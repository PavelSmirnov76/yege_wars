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

# Предел разворота объединённой ячейки: защита от мусора в атрибуте.
MAX_SPAN = 64

# Длина подписи столбца, при которой строка ещё считается шапкой.
MAX_LABEL_LENGTH = 60

# Признаки листинга программы, записанного абзацем на строку.
MIN_LISTING_LINES = 3
MAX_LISTING_LINE = 160
MAX_LISTING_MEDIAN = 45
# Сколько слов подряд делают строку фразой, а не командой.
MAX_PROSE_WORDS = 14
# Доля букв, выше которой строка читается как фраза: в коде много знаков
# операций, в прозе — почти одни буквы.
LETTER_SHARE = 0.6
# Конец предложения: точка после русской буквы, цифры или закрывающей
# скобки — «…(3 < n < 2000).». Паскалевское `end.` сюда не попадает:
# перед точкой латиница.
_RUSSIAN_SENTENCE_RE = re.compile(r'[а-яё0-9)»][)»\'"]*\.$', re.IGNORECASE)
_INDENTED_RE = re.compile(r'^[ ]{2,}\S')
# Знаки, которые в прозе не встречаются: строка с ними — код, сколько бы
# слов в ней ни было. Иначе комментарий в листинге рвал бы программу.
# Точки с запятой здесь нет: по-русски ею разделяют координаты «(4; 2)»,
# а знаков сравнения — потому что ими записывают «3 < n < 2000».
_CODE_MARK_RE = re.compile(r'[={}\[\]]')

# Вводная фраза перед листингом: «Цикл», «В конструкции». Ключевые слова
# алгоритмического языка так не пишутся — они либо целиком прописные
# (НАЧАЛО, КОНЕЦ ПОКА), либо целиком строчные (алг, нц, кц).
_INTRO_RE = re.compile(r'^[А-ЯЁ][а-яё]*(\s+[а-яё]+){0,2}$')

# Русская фраза, кончающаяся двоеточием: «Дана программа для Редактора:».
# Латиница исключена — иначе под правило попал бы `def F(n):`.
_INTRO_COLON_RE = re.compile(r'^[^A-Za-z{}\[\]=]*[а-яё][^A-Za-z{}\[\]=]*:$',
                             re.IGNORECASE)

# Решётка в начале строки: Markdown принял бы её за заголовок.
_HASH_RE = re.compile(r'^#')

# Любая последовательность пробельных символов.
_WHITESPACE_RE = re.compile(r'\s+')

# Теги, подряд идущие копии которых склеиваются перед отрисовкой.
_MERGEABLE_TAGS = frozenset({'sub', 'sup', 'b', 'strong', 'i', 'em', 'u'})

# Теги выделения: внутри них индекс может быть разорван границей тега.
_EMPHASIS_TAGS = frozenset({'b', 'strong', 'i', 'em', 'u'})

# Обёртки Word, не несущие смысла: мешают склейке соседних выделений.
_TRANSPARENT_TAGS = frozenset({'span', 'font'})

# Теги, каждый из которых в листинге начинает новую строку.
_LINE_TAGS = frozenset({'p', 'div', 'li', 'tr', 'center', 'blockquote'})

# Пунктуация, которую нельзя оставлять под маркером выделения: после неё
# CommonMark маркер не закрывает и печатает звёздочки текстом.
_EDGE_PUNCT = '-–—,.;:!?'

# Точка конца предложения, попавшая внутрь `<sub>`.
_SCRIPT_TAIL_PUNCT = '.,;:'

# Жёсткий перенос строки в готовой разметке.
_HARD_BREAK_RE = re.compile(r'\\\n')

# Прогон звёздочек на стыке двух выделений.
_MARKER_TAIL_RE = re.compile(r'\*+$')
_MARKER_HEAD_RE = re.compile(r'^\*+')

# Признак ячейки, поставленной на место объединения.
_FILLER_ATTR = 'data-merged-cell'

# Ограда блока кода.
FENCE_MARK = chr(96) * 3

# Подписи столбцов с программами — закрытый список: в банке встречаются
# только эти. Значение — язык для подсветки; она в проекте есть только
# для Python, остальным язык не проставляем. «Естественный язык» сюда
# намеренно не входит: под ним проза, а не код.
_CODE_LABELS = {
    'python': 'python',
    'питон': 'python',
    'паскаль': None,
    'бейсик': None,
    'алгоритмический': None,
    'алгоритмическийязык': None,
    'школьныйалгоритмическийязык': None,
    'си': None,
    'c++': None,
    'с++': None,
    'java': None,
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
    """Обрамляет текст маркером, вынося наружу пробелы и пунктуацию краёв.

    Выделение не ставится, если внутри нет ничего видимого (Word
    оборачивает курсивом одинокий `<br/>`) или нет ни буквы, ни цифры
    (курсив вокруг запятой). Пунктуация с краёв выносится наружу:
    закрывающий маркер после дефиса CommonMark не закрывает, и обе
    звёздочки печатаются как текст.
    """
    stripped = inner.strip()
    if not stripped or not _HARD_BREAK_RE.sub('', inner).strip():
        return inner
    if not any(char.isalnum() for char in stripped):
        return inner
    left = inner[:len(inner) - len(inner.lstrip())]
    right = inner[len(inner.rstrip()):]
    while stripped and stripped[-1] in _EDGE_PUNCT:
        right = stripped[-1] + right
        stripped = stripped[:-1]
    while stripped and stripped[0] in _EDGE_PUNCT:
        left += stripped[0]
        stripped = stripped[1:]
    if not stripped:
        return inner
    return '{}{}{}{}{}'.format(left, marker, stripped, marker, right)


def _append_inline(parts, text):
    """Добавляет кусок разметки, гася шов между двумя выделениями."""
    if not text:
        return
    if parts:
        parts[-1], text = _close_seam(parts[-1], text)
    parts.append(text)


def _close_seam(left, right):
    """Гасит шов между двумя выделениями подряд.

    `**a****b**` Markdown прочитать не может: прогон из четырёх
    звёздочек не закрывает открывающий маркер, и он остаётся текстом.
    """
    tail = _MARKER_TAIL_RE.search(left)
    head = _MARKER_HEAD_RE.match(right)
    if not tail or not head:
        return left, right
    width = len(tail.group())
    if width > 2 or width != len(head.group()):
        return left, right
    if tail.start() and left[tail.start() - 1] == '\\':
        return left, right
    if not left[:tail.start()] or not right[head.end():]:
        return left, right
    return left[:tail.start()], right[head.end():]


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
            if resolved is None:
                return _quote_url(url)
            # Пустая строка — служебная картинка сайта банка, не условие.
            return _quote_url(resolved) if resolved else ''
        # Путь вида docs/… — картинка осталась на сайте ФИПИ.
        self.missing_images.append(url)
        return _quote_url(FIPI_BASE_URL + url.lstrip('/'))

    # -- инлайн -------------------------------------------------------------
    def _inline(self, node):
        parts = []
        for child in node.children:
            _append_inline(parts, self._inline_one(child))
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
        if tag in ('p', 'div', 'li'):
            # Абзац внутри ячейки: Word так разбивает подпись на строки,
            # и без разделителя слова слиплись бы.
            return ' {} '.format(self._inline(node))
        return self._inline(node)

    def _script_text(self, node, table, marker):
        """Надстрочный или подстрочный индекс.

        Пробелы по краям возвращаются наружу: в разметке банка внутрь
        `<sup>` нередко попадает пробел перед знаком операции, и без этого
        индекс слипался бы со следующим словом. Точка конца предложения,
        попавшая внутрь `<sub>`, тоже выносится: иначе индекс `0.`
        перестаёт переводиться и весь он падает в скобки.
        """
        plain = _plain_text(node)
        stripped = plain.strip()
        if not stripped:
            return ' ' if plain else ''
        left = ' ' if plain[:1].isspace() else ''
        right = ' ' if plain[-1:].isspace() else ''
        tail = ''
        while len(stripped) > 1 and stripped[-1] in _SCRIPT_TAIL_PUNCT:
            tail = stripped[-1] + tail
            stripped = stripped[:-1]
        translated = _translate(stripped, table)
        if translated is None:
            inner = self._inline(node).strip()
            translated = '\\{}({})'.format(marker, inner) if inner else ''
            tail = ''
        return left + translated + tail + right

    def _link(self, node):
        href = node.attrs.get('href')
        inner = self._inline(node).strip()
        if not href:
            # Якорь `<a name="_GoBack">` — разметка Word, смысла не несёт.
            return inner
        url = self._resolve(href)
        if not url:
            return inner
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

    def _blocks(self, node, language=None):
        """Список блоков (абзацев, таблиц, списков) внутри узла."""
        blocks = []
        buffer = []
        run = []

        def flush_text():
            text = _collapse(''.join(buffer))
            buffer.clear()
            if text:
                blocks.append(text)

        def flush_run():
            """Копит подряд идущие абзацы: вместе они могут быть листингом."""
            if not run:
                return
            for chunk, lines in _split_listing(run):
                if lines is not None:
                    blocks.append(_fence(lines, language))
                    continue
                for paragraph in chunk:
                    blocks.extend(self._blocks(paragraph))
            run.clear()

        for child in node.children:
            if child.tag == 'p':
                flush_text()
                run.append(child)
                continue
            if child.tag is None and not child.text.strip():
                # Между блоками пробельный узел ничего не значит, а между
                # инлайн-соседями это разделитель слов: без него «файла
                # <i>B</i> <b>не следует</b>» слипалось в «Bне следует».
                if buffer:
                    buffer.append(' ')
                continue
            flush_run()
            if child.tag == 'table':
                flush_text()
                blocks.extend(self._table(child))
            elif child.tag in ('div', 'center', 'blockquote'):
                flush_text()
                blocks.extend(self._blocks(child, language))
            elif child.tag in ('ul', 'ol'):
                flush_text()
                blocks.extend(self._list(child))
            elif child.tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
                flush_text()
                text = _collapse(self._inline(child))
                if text:
                    blocks.append('**{}**'.format(text))
            elif child.tag == 'pre':
                flush_text()
                code = _plain_text(child).replace('\xa0', ' ').strip('\n')
                if code.strip():
                    blocks.append(_fence(code.split('\n'), language))
            else:
                _append_inline(buffer, self._inline_one(child))
        flush_run()
        flush_text()
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

    # -- таблицы ------------------------------------------------------------
    def _table(self, node):
        """Таблица: сетка, разворот в блоки или раскрытие обёртки."""
        grid = _table_grid(node)
        if not grid:
            return []
        if _is_layout_table(grid):
            # Вёрстка Word: таблица держит соседние блоки, а не данные.
            return [block for row in grid for cell in row
                    for block in self._cell_blocks(cell)]
        if _has_listing_rows(grid):
            return self._table_as_blocks(grid)
        return [self._grid(grid)]

    def _table_as_blocks(self, grid):
        """Таблица, которая в строку Markdown не влезает.

        Ячейка с несколькими абзацами (обычно это листинг программы) строкой
        таблицы быть не может. Если над такой строкой стоит строка коротких
        подписей — это шапка вроде «Паскаль | Python | Алгоритмический язык»,
        и пара разбирается по столбцам, чтобы подпись осталась при своём
        содержимом. Иначе ячейки выводятся в порядке чтения.
        """
        blocks = []
        index = 0
        while index < len(grid):
            row = grid[index]
            below = grid[index + 1] if index + 1 < len(grid) else None
            if (below is not None and _is_label_row(row)
                    and _has_block_row(below, row)):
                for column in range(max(len(row), len(below))):
                    label = _cell_plain(row[column]) if column < len(row) else ''
                    body = (self._cell_blocks(below[column],
                                              _language_of(label),
                                              _is_code_label(label))
                            if column < len(below) else [])
                    if not label and not body:
                        continue
                    if label:
                        blocks.append('**{}**'.format(_escape(label)))
                    blocks.extend(body)
                index += 2
            else:
                for cell in row:
                    blocks.extend(self._cell_blocks(cell))
                index += 1
        return blocks

    def _cell_blocks(self, cell, language=None, labelled=False):
        """Содержимое ячейки блоками; листинг отдаётся оградой целиком.

        Строки листинга в банке разделены то абзацами, то `<br/>` внутри
        одного абзаца — по ячейке это видно одинаково, а по её детям нет.
        """
        listing = _cell_listing(cell, labelled)
        if listing is not None:
            return [_fence(listing, language)]
        return self._blocks(cell, language)

    def _grid(self, grid):
        self._in_cell += 1
        try:
            cells = [[_cell_text(self._inline(cell)) for cell in row]
                     for row in grid]
        finally:
            self._in_cell -= 1
        width = max(len(row) for row in cells)
        cells = [row + [''] * (width - len(row)) for row in cells]

        if _looks_like_header(cells):
            header, body = cells[0], cells[1:]
        else:
            header, body = [''] * width, cells
        lines = ['| ' + ' | '.join(header) + ' |',
                 '| ' + ' | '.join(['---'] * width) + ' |']
        lines.extend('| ' + ' | '.join(row) + ' |' for row in body)
        return '\n'.join(lines)


def _quote_url(url):
    """Готовит адрес к подстановке в Markdown: скобки и пробелы ломают ссылку."""
    return quote(url, safe="/:?&=#%+,;@!$'*~")


def _plain_text(node):
    """Текст поддерева без разметки.

    Внутри `<m:math>` переносы и отступы — это разметка Word, а не текст:
    в блоке кода они показывались буквально и раздвигали знак операции.
    """
    if node.tag is None:
        return node.text.replace('\xa0', ' ')
    inner = ''.join(_plain_text(child) for child in node.children)
    if node.tag.startswith('m:'):
        return _WHITESPACE_RE.sub(' ', inner).strip()
    return inner


def _text_lines(node):
    """Текст узла построчно: `<br/>` и абзац начинают новую строку."""
    lines = ['']

    def _break_line():
        if lines[-1].strip():
            lines.append('')
        else:
            lines[-1] = ''

    def walk(current):
        if current.tag is None:
            text = current.text.replace('\xa0', ' ')
            text = text.replace('\r', ' ').replace('\n', ' ')
            lines[-1] += text.replace('\t', '    ')
            return
        if current.tag in DROPPED_TAGS:
            return
        if current.tag == 'br':
            lines.append('')
            return
        if current.tag.startswith('m:'):
            lines[-1] += _plain_text(current)
            return
        if current.tag in _LINE_TAGS:
            # Пробельный узел между `</p>` и `<p>` пустой строкой в
            # листинге быть не должен: её видно внутри ограды.
            _break_line()
            for child in current.children:
                walk(child)
            _break_line()
            return
        for child in current.children:
            walk(child)

    walk(node)
    lines = [line.rstrip() for line in lines]
    while lines and not lines[0]:
        lines.pop(0)
    while lines and not lines[-1]:
        lines.pop()
    return lines


def _collapse(text):
    """Схлопывает пробелы, сохраняя жёсткие переносы строк."""
    text = text.replace('\xa0', ' ')
    lines = [re.sub(r'[ \t]+', ' ', line).strip() for line in text.split('\n')]
    while lines and not lines[0]:
        lines.pop(0)
    while lines and not lines[-1]:
        lines.pop()
    # Решётка в начале строки — комментарий в коде, а не заголовок Markdown.
    lines = [_HASH_RE.sub(r'\\#', line) for line in lines]
    # Одинокий слэш в конце блока — это <br/> перед закрывающим тегом.
    return re.sub(r'\\$', '', '\n'.join(lines).strip())


def _cell_text(text):
    """Содержимое ячейки таблицы: строго одной строкой."""
    return re.sub(r'\s+', ' ', _collapse(text).replace('\n', ' ')).strip()


def _table_row_nodes(node):
    """Узлы `tr` таблицы; `tbody`/`thead`/`tfoot` прозрачны."""
    rows = []
    for child in node.children:
        if child.tag == 'tr':
            rows.append(child)
        elif child.tag in ('tbody', 'thead', 'tfoot'):
            rows.extend(g for g in child.children if g.tag == 'tr')
    return rows


def _filler():
    """Пустая ячейка на месте объединённой: колонки не должны съезжать."""
    return _Node('td', {_FILLER_ATTR: '1'})


def _is_filler(cell):
    return cell.attrs.get(_FILLER_ATTR) == '1'


def _span(cell, name):
    """Значение colspan/rowspan; мусор в атрибуте считается единицей."""
    try:
        value = int(cell.attrs.get(name, '1'))
    except ValueError:
        value = 1
    return max(1, min(value, MAX_SPAN))


def _table_grid(node):
    """Прямоугольная сетка ячеек таблицы.

    Объединённые ячейки Markdown выразить не может, поэтому colspan и
    rowspan разворачиваются в пустые ячейки-заполнители: вид объединения
    теряется, но каждое значение остаётся в своём столбце. Без разворота
    rowspan строки под объединённой ячейкой съезжали влево, и числа
    оказывались под чужими заголовками.
    """
    grid = []
    # столбец -> сколько строк он ещё занят объединением по вертикали
    pending = {}
    for row_node in _table_row_nodes(node):
        row = {}
        for column, left in sorted(pending.items()):
            if left > 0:
                row[column] = _filler()
                pending[column] = left - 1
        column = 0
        for cell in row_node.children:
            if cell.tag not in ('td', 'th'):
                continue
            while column in row:
                column += 1
            width = _span(cell, 'colspan')
            height = _span(cell, 'rowspan')
            for offset in range(width):
                row[column + offset] = cell if offset == 0 else _filler()
                if height > 1:
                    pending[column + offset] = height - 1
            column += width
        pending = dict((c, left) for c, left in pending.items() if left > 0)
        if row:
            grid.append([row.get(c, _filler())
                         for c in range(max(row) + 1)])
    if not grid:
        return []
    width = max(len(row) for row in grid)
    return [row + [_filler()] * (width - len(row)) for row in grid]


def _is_layout_table(grid):
    """Таблица, которой Word размечал вёрстку, а не данные.

    Признак — структура, а не атрибут `border`: Word ставит `border="0"`
    и на таблицы с данными, рисуя рамки стилем. По атрибуту вёрсткой
    считались настоящие матрицы, и они разваливались в столбик значений.
    """
    if not grid:
        return True
    if len(grid) == 1 and len(grid[0]) == 1:
        return True
    if any(_contains_tag(cell, 'table') for row in grid for cell in row):
        return True
    if len(grid) == 1 and len(grid[0]) == 2:
        return _is_layout_pair(grid[0])
    # Шапка «значок + предупреждение о файлах», под ней текст задания во
    # всю ширину: столбцов тут нет, таблицей это выводить нельзя. Строка
    # во всю ширину сама по себе признаком не служит — ею же набран
    # столбец «Си» в таблицах с программами на пяти языках.
    return (len(grid) == 2 and _is_wrapper_row(grid[1])
            and any(_contains_image(cell) for cell in grid[0]))


def _is_layout_pair(row):
    """Строка из двух ячеек: вёрстка или всё-таки пара значений.

    «| 50 | 65 |» — это ряд и место из ответа, такую таблицу разбирать
    на абзацы нельзя: два числа стали бы двумя ответами.
    """
    texts = [_cell_plain(cell) for cell in row]
    if not all(texts):
        return True
    if any(_contains_image(cell) for cell in row):
        return True
    return any(len(text) > MAX_LABEL_LENGTH for text in texts)


def _is_wrapper_row(row):
    """Строка из одной ячейки во всю ширину, и в ней — текст задания.

    Так Word кладёт условие под шапку «значок + предупреждение о
    прилагаемых файлах»: столбцы к этой строке уже не относятся, и
    таблицей такое выводить нельзя.
    """
    if len(row) < 2 or _is_filler(row[0]):
        return False
    if not all(_is_filler(cell) for cell in row[1:]):
        return False
    return (len(_cell_plain(row[0])) > MAX_LABEL_LENGTH
            or _has_block_content(row[0]))


def _contains_tag(node, tag):
    if node.tag == tag:
        return True
    return any(_contains_tag(child, tag) for child in node.children)


def _cell_listing(cell, labelled=False):
    """Строки листинга ячейки, если её содержимое — текст программы."""
    if _contains_image(cell) or _contains_tag(cell, 'table'):
        return None
    lines = _text_lines(cell)
    return lines if _looks_like_listing(lines, labelled) else None


def _has_block_content(cell, labelled=False):
    """Есть ли в ячейке то, что не помещается в строку Markdown-таблицы.

    Несколько коротких абзацев — это Word разбил подпись на строки, они
    склеиваются в одну ячейку. Разворачивать таблицу в блоки нужно
    только ради листинга и вложенных списков: иначе таблица с шапкой
    «Найдено страниц» / «(в сотнях тысяч)» рассыпалась в столбик чисел.
    """
    if any(child.tag in ('table', 'ul', 'ol', 'pre')
           for child in cell.children):
        return True
    return _cell_listing(cell, labelled) is not None


def _has_block_row(row, labels=None):
    """Есть ли в строке ячейка, которую строкой таблицы не сделать."""
    for column, cell in enumerate(row):
        label = (_cell_plain(labels[column])
                 if labels is not None and column < len(labels) else '')
        if _has_block_content(cell, _is_code_label(label)):
            return True
    return False


def _has_listing_rows(grid):
    """Нужно ли разворачивать таблицу в блоки: где-то лежит листинг."""
    for index, row in enumerate(grid):
        above = grid[index - 1] if index else None
        labels = above if above is not None and _is_label_row(above) else None
        if _has_block_row(row, labels):
            return True
    return False


def _cell_plain(cell):
    """Текст ячейки без разметки, одной строкой."""
    return _WHITESPACE_RE.sub(' ', _plain_text(cell)).strip()


def _is_label_row(row):
    """Строка коротких подписей — шапка вроде «Паскаль | Python»."""
    texts = [_cell_plain(cell) for cell in row]
    if not any(texts):
        return False
    if any(_has_block_content(cell) for cell in row):
        return False
    return all(len(text) <= MAX_LABEL_LENGTH for text in texts)


def _contains_image(node):
    if node.tag == 'img':
        return True
    if node.tag == 'script':
        return _script_image(node) is not None
    return any(_contains_image(child) for child in node.children)


def _is_prose_line(line):
    """Строка — фраза, а не команда программы.

    Считать слова у всех строк подряд нельзя: `while (s > 0) { s = s - 20;
    n = n + 2; }` даёт шестнадцать «слов» и отбраковывал весь листинг на
    Си. Строку делает прозой не длина, а то, что в ней одни слова: ни
    присваивания, ни скобок индекса, ни точки с запятой.
    """
    stripped = line.strip()
    if not stripped:
        return False
    if _CODE_MARK_RE.search(stripped):
        return False
    if _RUSSIAN_SENTENCE_RE.search(stripped):
        return True
    letters = sum(1 for char in stripped if char.isalpha())
    dense = letters > LETTER_SHARE * len(stripped.replace(' ', ''))
    return dense and len(stripped.split()) > MAX_PROSE_WORDS


def _looks_like_listing(lines, labelled=False):
    """Похож ли набор строк на текст программы.

    Word пишет листинг отдельным абзацем на строку, а отступ задаёт
    пробелами или неразрывными пробелами. Схлопывание пробелов такой
    отступ убивало, и тело цикла выходило из цикла.

    `labelled` — над ячейкой стоит название языка. Тогда отступ не
    нужен: программа на Бейсике его и не требует, а в соседнем столбце
    той же строки лежит та же программа на Паскале с отступами.
    """
    body = [line for line in lines if line.strip()]
    if len(body) < MIN_LISTING_LINES:
        return False
    if not labelled and not any(_INDENTED_RE.match(line) for line in body):
        return False
    if max(len(line) for line in body) > MAX_LISTING_LINE:
        return False
    if sum(1 for line in body if _is_prose_line(line)) >= 2:
        return False
    # Строки кода короткие; абзац прозы длиннее любой из них.
    lengths = sorted(len(line) for line in body)
    return lengths[len(lengths) // 2] <= MAX_LISTING_MEDIAN


def _split_listing(paragraphs):
    """Режет прогон абзацев на куски прозы и куски листинга.

    В заданиях без таблиц программа исполнителя набрана такими же `<p>`,
    как окружающая проза. Проверять прогон целиком нельзя: одна фраза
    рядом валила признак листинга, и отступы терялись.
    """
    chunks = []
    current = []
    for paragraph in paragraphs:
        lines = _text_lines(paragraph)
        if any(_is_prose_line(line) for line in lines):
            if current:
                chunks.append(current)
                current = []
            chunks.append([(paragraph, lines)])
        else:
            current.append((paragraph, lines))
    if current:
        chunks.append(current)

    result = []
    for chunk in chunks:
        while chunk and _is_intro_paragraph(chunk[0][1]):
            result.append(([chunk[0][0]], None))
            chunk = chunk[1:]
        if not chunk:
            continue
        flat = [line for _, lines in chunk for line in lines]
        nodes = [paragraph for paragraph, _ in chunk]
        result.append((nodes, flat if _looks_like_listing(flat) else None))
    return result


def _is_intro_paragraph(lines):
    """Абзац — вводная фраза, а не первая строка программы."""
    body = [line.strip() for line in lines if line.strip()]
    if len(body) != 1:
        return False
    return bool(_INTRO_RE.match(body[0])
                or _INTRO_COLON_RE.match(body[0]))


def _fence(lines, language=None):
    """Блок кода с оградой; язык включает подсветку на клиенте."""
    while lines and not lines[0].strip():
        lines = lines[1:]
    while lines and not lines[-1].strip():
        lines = lines[:-1]
    body = "\n".join(lines).replace(FENCE_MARK, FENCE_MARK[:2])
    return FENCE_MARK + (language or '') + "\n" + body + "\n" + FENCE_MARK


def _code_label(label):
    """Подпись столбца, приведённая к виду ключа: «С ++» и «C++» — одно."""
    return _WHITESPACE_RE.sub('', (label or '').strip().lower())


def _is_code_label(label):
    """Названа ли подпись столбца языком программирования."""
    return _code_label(label) in _CODE_LABELS


def _language_of(label):
    """Язык блока кода по подписи столбца."""
    return _CODE_LABELS.get(_code_label(label))


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


def _unwrap_transparent(node):
    """Убирает `<span>` и `<font>`: смысла в них нет, а склейке мешают.

    `<span><b>9</b></span><b>E</b>` — соседними эти `<b>` не считались,
    выделения закрывались встык, и прогон `****` выпадал в текст.
    """
    children = []
    for child in node.children:
        if child.tag in _TRANSPARENT_TAGS:
            _unwrap_transparent(child)
            children.extend(child.children)
        else:
            _unwrap_transparent(child)
            children.append(child)
    node.children = children


def _absorb(previous, child):
    """Присоединяет узел к предыдущему, если это части одного целого."""
    if child.tag is None or child.tag not in _MERGEABLE_TAGS:
        return False
    if previous.tag == child.tag:
        previous.children.extend(child.children)
        return True
    # `<i>y<sub>j</sub></i><sub>+ 1</sub>` — индекс разорван концом
    # курсива; без склейки «+ 1» встаёт отдельным членом формулы.
    if (child.tag in ('sub', 'sup') and previous.tag in _EMPHASIS_TAGS
            and previous.children
            and previous.children[-1].tag == child.tag):
        previous.children[-1].children.extend(child.children)
        return True
    return False


def _merge_adjacent(node):
    """Склеивает подряд идущие одинаковые теги выделения и индексов.

    Word пишет `a<sub>n</sub><sub>–</sub><sub>1</sub>`: три отдельных
    индекса вместо одного. Без склейки они разваливались в `a_(n)_(–)₁`,
    а соседние `<b>` давали слипшиеся прогоны звёздочек.
    """
    merged = []
    for child in node.children:
        previous = merged[-1] if merged else None
        if previous is not None and _absorb(previous, child):
            continue
        merged.append(child)
    node.children = merged
    for child in node.children:
        _merge_adjacent(child)


def html_to_markdown(html, asset_url=None):
    """Markdown условия и список картинок, которых нет в выгрузке."""
    builder = _TreeBuilder()
    builder.feed(html or '')
    builder.close()
    _unwrap_transparent(builder.root)
    _merge_adjacent(builder.root)
    renderer = MarkdownRenderer(asset_url)
    markdown = renderer.render(builder.root)
    markdown = re.sub(r'\n{3,}', '\n\n', markdown).strip()
    return markdown, renderer.missing_images
