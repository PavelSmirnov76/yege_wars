"""Преобразование условия задания из HTML банка ФИПИ в Markdown.

Банк отдаёт условия разметкой, выгруженной из Word: вложенные таблицы-обёртки,
`<span>` с пробелами вместо табуляции, обрывки MathML в пространстве имён `m:`
и картинки, вставленные вызовом `ShowPictureQ(...)` из `<script>`.

Внешних зависимостей нет: разбор идёт на `html.parser` из стандартной
библиотеки, потому что на машине сборки не установлены ни bs4, ни lxml.
"""

from __future__ import annotations

import re
from html import unescape
from html.parser import HTMLParser
from urllib.parse import quote

# Теги без закрывающей пары.
VOID_TAGS = frozenset({
    'br', 'img', 'hr', 'meta', 'link', 'input', 'col', 'area', 'base',
})

# Блочные теги: их появление закрывает незакрытый абзац.
BLOCK_TAGS = frozenset({
    'p', 'div', 'table', 'tr', 'td', 'th', 'ul', 'ol', 'li', 'blockquote',
    'pre', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'center',
})

# Что выбрасываем вместе с содержимым: оформление Word и вложенные объекты.
DROPPED_TAGS = frozenset({'style', 'o:p', 'xml', 'v:shapetype', 'v:shape'})

# Адрес картинок, которых нет в выгрузке: они остаются на сайте ФИПИ.
FIPI_BASE_URL = 'https://ege.fipi.ru/'

# Путь к картинке внутри вызова ShowPictureQ('docs/…').
_SHOW_PICTURE_RE = re.compile(r"ShowPictureQ\(\s*'([^']+)'", re.IGNORECASE)

_SUPERSCRIPTS = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶',
    '7': '⁷', '8': '⁸', '9': '⁹', '+': '⁺', '-': '⁻', '−': '⁻', '=': '⁼',
    '(': '⁽', ')': '⁾', 'n': 'ⁿ', 'i': 'ⁱ',
}

_SUBSCRIPTS = {
    '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆',
    '7': '₇', '8': '₈', '9': '₉', '+': '₊', '-': '₋', '−': '₋', '=': '₌',
    '(': '₍', ')': '₎',
}

# Символы, которые Markdown истолковал бы как разметку.
_ESCAPED_CHARS = '\\`*_[]<>|~'
_ESCAPE_RE = re.compile('([' + re.escape(_ESCAPED_CHARS) + '])')


class _Node:
    """Узел дерева разметки. `tag` = None у текстового узла."""

    __slots__ = ('tag', 'attrs', 'children', 'text')

    def __init__(self, tag, attrs=None, text=''):
        self.tag = tag
        self.attrs = attrs or {}
        self.children = []
        self.text = text


class _TreeBuilder(HTMLParser):
    """Собирает дерево из заведомо неаккуратного HTML."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = _Node('root')
        self._stack = [self.root]
        # Глубина внутри выброшенного поддерева (`style`, `xml` и т.п.).
        self._dropped = 0

    # -- служебное ----------------------------------------------------------
    def _current(self):
        # Корень со стека не снимается, но разметка бывает любой.
        return self._stack[-1] if self._stack else self.root

    def _open_tags(self):
        return [node.tag for node in self._stack]

    def _close_until(self, tags):
        """Закрывает открытые узлы, пока сверху не окажется один из `tags`."""
        for index in range(len(self._stack) - 1, 0, -1):
            if self._stack[index].tag in tags:
                del self._stack[index:]
                return True
        return False

    def _autoclose(self, tag):
        """Закрывает узлы, которые новый тег закрывает по правилам HTML."""
        if tag == 'p' and 'p' in self._open_tags():
            self._close_until({'p'})
        elif tag in ('td', 'th'):
            if self._current().tag in ('td', 'th'):
                self._stack.pop()
        elif tag == 'tr':
            while self._current().tag in ('td', 'th', 'tr'):
                self._stack.pop()
        elif tag == 'li':
            while self._current().tag == 'li':
                self._stack.pop()
        elif tag in BLOCK_TAGS and self._current().tag == 'p':
            self._stack.pop()

    # -- обработчики HTMLParser --------------------------------------------
    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if self._dropped:
            if tag not in VOID_TAGS:
                self._dropped += 1
            return
        if tag in DROPPED_TAGS:
            self._dropped = 1
            return
        self._autoclose(tag)
        node = _Node(tag, {name.lower(): (value or '') for name, value in attrs})
        self._current().children.append(node)
        if tag not in VOID_TAGS:
            self._stack.append(node)

    def handle_startendtag(self, tag, attrs):
        tag = tag.lower()
        if self._dropped or tag in DROPPED_TAGS:
            return
        node = _Node(tag, {name.lower(): (value or '') for name, value in attrs})
        self._current().children.append(node)

    def handle_endtag(self, tag):
        tag = tag.lower()
        if self._dropped:
            self._dropped -= 1
            return
        if tag in VOID_TAGS:
            return
        for index in range(len(self._stack) - 1, 0, -1):
            if self._stack[index].tag == tag:
                del self._stack[index:]
                return
        # Закрывающий тег без открывающего — молча пропускаем.

    def handle_data(self, data):
        if self._dropped:
            return
        self._current().children.append(_Node(None, text=data))


def _escape(text):
    """Экранирует символы, которые Markdown принял бы за разметку."""
    return _ESCAPE_RE.sub(r'\\\1', text)


def _script_image(node):
    """Путь к картинке из `<script>ShowPictureQ('…')</script>`, если он есть."""
    body = ''.join(child.text for child in node.children if child.tag is None)
    match = _SHOW_PICTURE_RE.search(body)
    return match.group(1) if match else None


def _translate(text, table):
    """Переводит строку в надстрочные/подстрочные знаки, либо возвращает None."""
    if not text:
        return None
    result = []
    for char in text:
        if char not in table:
            return None
        result.append(table[char])
    return ''.join(result)


def _wrap_emphasis(inner, marker):
    """Обрамляет текст маркером, вынося наружу пробелы по краям."""
    stripped = inner.strip()
    if not stripped:
        return inner
    left = inner[:len(inner) - len(inner.lstrip())]
    right = inner[len(inner.rstrip()):]
    return '{}{}{}{}{}'.format(left, marker, stripped, marker, right)


class MarkdownRenderer:
    """Рисует дерево разметки в Markdown.

    `asset_url` — функция «локальный путь вложения → адрес, по которому файл
    доступен ученику»; если она вернёт None, ссылка останется относительной.
    """

    def __init__(self, asset_url=None):
        self._asset_url = asset_url or (lambda path: None)
        # Внутри ячейки таблицы переносы строк запрещены.
        self._in_cell = 0
        self.missing_images = []

    # -- адреса -------------------------------------------------------------
    def _resolve(self, url):
        url = unescape(url or '').strip()
        if not url:
            return ''
        if url.startswith(('http://', 'https://', 'data:')):
            return _quote_url(url)
        if url.startswith('assets/'):
            resolved = self._asset_url(url)
            return _quote_url(resolved if resolved else url)
        # Путь вида docs/… — картинка осталась на сайте ФИПИ.
        self.missing_images.append(url)
        return _quote_url(FIPI_BASE_URL + url.lstrip('/'))

    # -- инлайн -------------------------------------------------------------
    def _inline(self, node):
        parts = []
        for child in node.children:
            parts.append(self._inline_one(child))
        return ''.join(parts)

    def _inline_one(self, node):
        if node.tag is None:
            return _escape(node.text.replace('\xa0', ' '))

        tag = node.tag
        if tag == 'br':
            return ' ' if self._in_cell else '\\\n'
        if tag == 'img':
            url = self._resolve(node.attrs.get('src', ''))
            alt = _escape(unescape(node.attrs.get('alt', '')).strip())
            return '![{}]({})'.format(alt, url) if url else ''
        if tag == 'script':
            path = _script_image(node)
            return '![]({})'.format(self._resolve(path)) if path else ''
        if tag in ('b', 'strong'):
            return _wrap_emphasis(self._inline(node), '**')
        if tag in ('i', 'em'):
            return _wrap_emphasis(self._inline(node), '*')
        if tag in ('code', 'tt', 'kbd'):
            inner = self._inline(node).strip()
            return '`{}`'.format(inner.replace('\\', '')) if inner else ''
        if tag == 'sup':
            return self._script_text(node, _SUPERSCRIPTS, '^')
        if tag == 'sub':
            return self._script_text(node, _SUBSCRIPTS, '_')
        if tag == 'a':
            return self._link(node)
        if tag.startswith('m:'):
            return self._math(node)
        return self._inline(node)

    def _script_text(self, node, table, marker):
        """Надстрочный или подстрочный индекс."""
        plain = _plain_text(node).strip()
        translated = _translate(plain, table)
        if translated is not None:
            return translated
        inner = self._inline(node).strip()
        if not inner:
            return ''
        return '\\{}({})'.format(marker, inner)

    def _link(self, node):
        href = node.attrs.get('href')
        inner = self._inline(node).strip()
        if not href:
            # Якорь `<a name="_GoBack">` — разметка Word, смысла не несёт.
            return inner
        url = self._resolve(href)
        return '[{}]({})'.format(inner or url, url)

    def _math(self, node):
        """Обрывки MathML из Word: в банке это почти всегда одиночные знаки."""
        tag = node.tag[2:]
        children = [child for child in node.children
                    if child.tag is not None or child.text.strip()]
        if tag in ('mi', 'mn', 'mo', 'mtext', 'ms'):
            return _escape(_plain_text(node).strip())
        parts = [self._inline_one(child).strip() for child in children]
        if tag in ('msub', 'msup') and len(parts) >= 2:
            marker = '_' if tag == 'msub' else '^'
            return '{}\\{}({})'.format(parts[0], marker, parts[1])
        if tag == 'mfrac' and len(parts) >= 2:
            return '({})/({})'.format(parts[0], parts[1])
        if tag == 'msqrt':
            return '√({})'.format(''.join(parts))
        return ''.join(parts)

    # -- блоки --------------------------------------------------------------
    def render(self, node):
        """Markdown всего дерева."""
        blocks = self._blocks(node)
        return '\n\n'.join(blocks)

    def _blocks(self, node):
        """Список блоков (абзацев, таблиц, списков) внутри узла."""
        blocks = []
        buffer = []

        def flush():
            text = _collapse(''.join(buffer))
            buffer.clear()
            if text:
                blocks.append(text)

        for child in node.children:
            if child.tag == 'table':
                flush()
                blocks.extend(self._table(child))
            elif child.tag in ('p', 'div', 'center', 'blockquote'):
                flush()
                blocks.extend(self._blocks(child))
            elif child.tag in ('ul', 'ol'):
                flush()
                blocks.extend(self._list(child))
            elif child.tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
                flush()
                text = _collapse(self._inline(child))
                if text:
                    blocks.append('**{}**'.format(text))
            elif child.tag == 'pre':
                flush()
                code = _plain_text(child).strip('\n')
                if code.strip():
                    blocks.append('```\n{}\n```'.format(code))
            else:
                buffer.append(self._inline_one(child))
        flush()
        return blocks

    def _list(self, node):
        items = []
        ordered = node.tag == 'ol'
        number = 1
        for child in node.children:
            if child.tag != 'li':
                continue
            text = _collapse(self._inline(child))
            if not text:
                continue
            if ordered:
                items.append('{}. {}'.format(number, text))
                number += 1
            else:
                items.append('- {}'.format(text))
        return ['\n'.join(items)] if items else []

    def _table(self, node):
        rows = _table_rows(node)
        if not rows:
            return []
        # Таблица-обёртка из Word: одна ячейка либо border="0".
        if _is_layout_table(node, rows):
            blocks = []
            for row in rows:
                for cell in row:
                    blocks.extend(self._blocks(cell))
            return blocks
        if any(_has_block_content(cell) for row in rows for cell in row):
            # Ячейки с абзацами и вложенными таблицами в Markdown не влезают:
            # разворачиваем такую таблицу в последовательность блоков.
            blocks = []
            for row in rows:
                for cell in row:
                    blocks.extend(self._blocks(cell))
            return blocks
        return [self._grid(rows)]

    def _grid(self, rows):
        self._in_cell += 1
        try:
            grid = [[_cell_text(self._inline(cell)) for cell in row]
                    for row in rows]
        finally:
            self._in_cell -= 1
        width = max(len(row) for row in grid)
        grid = [row + [''] * (width - len(row)) for row in grid]

        if _looks_like_header(grid):
            header, body = grid[0], grid[1:]
        else:
            header, body = [''] * width, grid
        lines = ['| ' + ' | '.join(header) + ' |',
                 '| ' + ' | '.join(['---'] * width) + ' |']
        lines.extend('| ' + ' | '.join(row) + ' |' for row in body)
        return '\n'.join(lines)


def _quote_url(url):
    """Готовит адрес к подстановке в Markdown: скобки и пробелы ломают ссылку."""
    return quote(url, safe="/:?&=#%+,;@!$'*~")


def _plain_text(node):
    """Текст поддерева без разметки."""
    if node.tag is None:
        return node.text.replace('\xa0', ' ')
    return ''.join(_plain_text(child) for child in node.children)


def _collapse(text):
    """Схлопывает пробелы, сохраняя жёсткие переносы строк."""
    text = text.replace('\xa0', ' ')
    lines = [re.sub(r'[ \t]+', ' ', line).strip() for line in text.split('\n')]
    while lines and not lines[0]:
        lines.pop(0)
    while lines and not lines[-1]:
        lines.pop()
    # Одинокий слэш в конце блока — это <br/> перед закрывающим тегом.
    return re.sub(r'\\$', '', '\n'.join(lines).strip())


def _cell_text(text):
    """Содержимое ячейки таблицы: строго одной строкой."""
    return re.sub(r'\s+', ' ', _collapse(text).replace('\n', ' ')).strip()


def _table_rows(node):
    """Строки таблицы: `tr` ищем и внутри `tbody`/`thead`."""
    rows = []
    for child in node.children:
        if child.tag == 'tr':
            rows.append(_row_cells(child))
        elif child.tag in ('tbody', 'thead', 'tfoot'):
            for grandchild in child.children:
                if grandchild.tag == 'tr':
                    rows.append(_row_cells(grandchild))
    return [row for row in rows if row]


def _row_cells(row):
    """Ячейки строки; colspan разворачивается в пустые соседние ячейки."""
    cells = []
    for child in row.children:
        if child.tag not in ('td', 'th'):
            continue
        cells.append(child)
        try:
            span = int(child.attrs.get('colspan', '1'))
        except ValueError:
            span = 1
        for _ in range(max(0, span - 1)):
            cells.append(_Node('td'))
    return cells


def _is_layout_table(node, rows):
    """Таблица, которой Word размечал верстку, а не данные."""
    if node.attrs.get('border', '').strip() == '0':
        return True
    return len(rows) == 1 and len(rows[0]) == 1


def _has_block_content(cell):
    """Есть ли в ячейке то, что не помещается в строку Markdown-таблицы."""
    paragraphs = 0
    for child in cell.children:
        if child.tag == 'table':
            return True
        if child.tag in ('ul', 'ol', 'pre', 'div'):
            return True
        if child.tag == 'p':
            if _plain_text(child).strip() or _contains_image(child):
                paragraphs += 1
    return paragraphs > 1


def _contains_image(node):
    if node.tag == 'img':
        return True
    if node.tag == 'script':
        return _script_image(node) is not None
    return any(_contains_image(child) for child in node.children)


def _looks_like_header(grid):
    """Первая строка — заголовок, если она текстовая, а ниже есть числа."""
    if len(grid) < 2:
        return False
    first = grid[0]
    if any(not cell for cell in first):
        return False
    if any(_is_number(cell) for cell in first):
        return False
    return any(_is_number(cell) for row in grid[1:] for cell in row)


_NUMBER_RE = re.compile(r'^[-+]?\d+([.,]\d+)?$')


def _is_number(text):
    return bool(_NUMBER_RE.match(text.strip()))


def html_to_markdown(html, asset_url=None):
    """Markdown условия и список картинок, которых нет в выгрузке."""
    builder = _TreeBuilder()
    builder.feed(html or '')
    builder.close()
    renderer = MarkdownRenderer(asset_url)
    markdown = renderer.render(builder.root)
    markdown = re.sub(r'\n{3,}', '\n\n', markdown).strip()
    return markdown, renderer.missing_images
