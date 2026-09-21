"""Чтение выгрузки банка ФИПИ и сборка строк для таблиц проекта.

Модуль ничего не знает про SQL: он превращает файлы выгрузки в словари,
готовые к записи. Правила заполнения полей, которых у ФИПИ нет (slug,
название, сложность, формат ответа), собраны здесь в одном месте.
"""

from __future__ import annotations

import json
import math
import os
import re

from .html_to_md import html_to_markdown

# Бакет Supabase Storage, куда заливаются вложения банка.
STORAGE_BUCKET = 'task-assets'

# Префикс путей внутри бакета: выгрузка ФИПИ лежит отдельно от своих файлов.
STORAGE_PREFIX = 'fipi/'

# Служебная тема для заданий, которым банк не проставил КЭС.
NO_THEME_CODE = 'none'

# Тип ответа банка -> формат ответа проекта.
ANSWER_FORMATS = {
    'Краткий ответ': 'string',
    'Выбор ответа': 'single',
    'Последовательность': 'multi',
    'Развернутый ответ': 'string',
}

# Уровень задания из спецификации КИМ -> сложность 1–3.
KIM_LEVELS = {'Б': 1, 'П': 2, 'В': 3}

# Уровень изучения темы -> сложность 1–3, когда номера задания нет.
THEME_LEVELS = {'БУ': 1, 'БУ, УУ': 2, 'УУ': 3}

# Происхождение номера задания: восстановлен по спецификации ЕГЭ-2026.
EGE_NUMBER_SOURCE = 'fipi-spec-2026'

# Служебная фраза банка, которая не может быть названием задачи.
ATTACHMENT_NOTICE = 'Задание выполняется с использованием прилагаемых файлов'

MAX_TITLE_LENGTH = 80
MAX_SUMMARY_LENGTH = 300

# Сколько знаков читатель проходит за минуту — для оценки времени чтения.
CHARS_PER_MINUTE = 1200

_SENTENCE_END_RE = re.compile(r'(?<=[.!?])\s+')
_WHITESPACE_RE = re.compile(r'\s+')
_MARKDOWN_MARKS_RE = re.compile(r'[*_`\\]')

_CONTENT_TYPES = {
    '.txt': 'text/plain; charset=utf-8',
    '.csv': 'text/csv; charset=utf-8',
    '.zip': 'application/zip',
    '.rar': 'application/vnd.rar',
    '.gif': 'image/gif',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.ods': 'application/vnd.oasis.opendocument.spreadsheet',
    '.odt': 'application/vnd.oasis.opendocument.text',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.pdf': 'application/pdf',
    '.rtf': 'application/rtf',
}


class BankError(Exception):
    """Выгрузка не соответствует ожидаемой структуре."""


def task_uuid(fipi_id):
    """UUID задачи из 32-символьного GUID банка: связи остаются стабильными."""
    value = fipi_id.lower()
    if len(value) != 32 or not re.match(r'^[0-9a-f]{32}$', value):
        raise BankError('Идентификатор «{}» не похож на GUID банка'.format(fipi_id))
    return '{}-{}-{}-{}-{}'.format(
        value[0:8], value[8:12], value[12:16], value[16:20], value[20:32]
    )


def theme_slug(code):
    """slug статьи по коду темы: точка не проходит проверку slug."""
    return 'kes-' + code.replace('.', '-')


def storage_path(local_path):
    """Путь внутри бакета для вложения выгрузки."""
    relative = local_path[len('assets/'):] if local_path.startswith('assets/') \
        else local_path
    return STORAGE_PREFIX + relative


def content_type_for(filename):
    return _CONTENT_TYPES.get(os.path.splitext(filename)[1].lower())


def strip_markdown(text):
    """Текст без знаков разметки — для описаний и названий."""
    return _WHITESPACE_RE.sub(' ', _MARKDOWN_MARKS_RE.sub('', text)).strip()


def shorten(text, limit):
    """Обрезает по границе слова и ставит многоточие."""
    text = text.strip()
    if len(text) <= limit:
        return text
    cut = text[:limit]
    space = cut.rfind(' ')
    if space > limit // 2:
        cut = cut[:space]
    return cut.rstrip(' ,;:-–—') + '…'


def make_title(condition_text):
    """Название задачи: первое предложение условия без служебной фразы."""
    text = _WHITESPACE_RE.sub(' ', condition_text or '').strip()
    sentences = [s.strip() for s in _SENTENCE_END_RE.split(text) if s.strip()]
    for sentence in sentences:
        if ATTACHMENT_NOTICE.lower() in sentence.lower():
            continue
        return shorten(sentence, MAX_TITLE_LENGTH)
    return shorten(text, MAX_TITLE_LENGTH) if text else 'Задание банка ФИПИ'


def article_summary(markdown):
    """Описание для карточки: первый абзац статьи без заголовка."""
    blocks = [b.strip() for b in markdown.split('\n\n') if b.strip()]
    for block in blocks:
        if block.startswith('#'):
            continue
        return shorten(strip_markdown(block), MAX_SUMMARY_LENGTH)
    return shorten(strip_markdown(markdown), MAX_SUMMARY_LENGTH)


def article_title(markdown, fallback):
    """Короткий заголовок статьи: строка H1, если она есть.

    В `handbook.json` поле `title` — это полная формулировка КЭС длиной до
    600 знаков: в карточке и в ссылке `[[slug]]` её не показать. Короткое
    название есть в самой статье первой строкой.
    """
    first = markdown.lstrip().split('\n', 1)[0].strip()
    if first.startswith('#'):
        title = first.lstrip('#').strip()
        if title:
            return title
    return shorten(fallback, MAX_TITLE_LENGTH)


def reading_minutes(markdown):
    return max(1, min(60, math.ceil(len(markdown) / CHARS_PER_MINUTE)))


class Bank:
    """Выгрузка банка ФИПИ, разобранная в строки таблиц проекта."""

    def __init__(self, root):
        self.root = os.path.abspath(os.path.expanduser(root))
        self.tasks = self._load('tasks.json')
        self.handbook = self._load(os.path.join('handbook', 'handbook.json'))
        self.handbook_index = self._load(os.path.join('handbook', 'index.json'))
        self.kim_numbers = self._load('kim_numbers.json')
        self.kim_coverage = self._load('kim_coverage.json')
        self._number_by_task = self._index_numbers()
        self._theme_level = {t['code']: t.get('level') for t in self.handbook}
        # Копится по ходу сборки: о чём отчёт должен сказать отдельно.
        self.stats = {
            'tasks': 0,
            'task_themes': 0,
            'tasks_without_theme': 0,
            'tasks_with_number': 0,
            'tasks_without_number': 0,
            'files': 0,
            'tasks_with_files': 0,
            'missing_images': 0,
            'tasks_with_missing_images': 0,
            'missing_asset_files': [],
            'files_on_disk': 0,
            'assets_orphaned': 0,
            'parents': 0,
            'duplicates': 0,
            'incomplete': 0,
        }

    # -- чтение файлов выгрузки --------------------------------------------
    def _load(self, name):
        path = os.path.join(self.root, name)
        if not os.path.exists(path):
            raise BankError('В выгрузке нет файла {}'.format(name))
        with open(path, encoding='utf-8') as handle:
            return json.load(handle)

    def _index_numbers(self):
        """Идентификатор задания -> номер в КИМ."""
        numbers = {}
        for number, payload in self.kim_numbers.items():
            ids = payload['tasks'] if isinstance(payload, dict) else payload
            for task_id in ids:
                numbers[task_id] = int(number)
        return numbers

    # -- темы ---------------------------------------------------------------
    def themes(self):
        """45 тем кодификатора; служебную none ставит миграция."""
        rows = []
        for order, theme in enumerate(self.handbook):
            rows.append({
                'code': theme['code'],
                'title': theme['title'],
                'section_code': theme['section_code'],
                'section_title': theme['section_title'],
                'level': theme.get('level'),
                'sort_order': order,
            })
        return rows

    def articles(self):
        """Статьи справочника: по одной на тему кодификатора."""
        rows = []
        for theme in self.handbook:
            markdown = theme['article_markdown']
            index = self.handbook_index.get(theme['code'], {})
            rows.append({
                'slug': theme_slug(theme['code']),
                'title': article_title(markdown, theme['title']),
                'summary': article_summary(markdown),
                'content_md': markdown,
                'theme_code': theme['code'],
                'ege_numbers': sorted(index.get('kim_numbers') or []),
                'tags': [theme['code'], theme['section_code']],
                'level': THEME_LEVELS.get(theme.get('level'), 1),
                'reading_minutes': reading_minutes(markdown),
                'is_published': True,
            })
        return rows

    # -- задания ------------------------------------------------------------
    def _difficulty(self, number, theme_codes):
        if number is not None:
            level = self.kim_coverage.get(str(number), {}).get('level')
            if level in KIM_LEVELS:
                return KIM_LEVELS[level]
        for code in theme_codes:
            level = self._theme_level.get(code)
            if level in THEME_LEVELS:
                return THEME_LEVELS[level]
        return 1

    def _asset_url_factory(self):
        """Адрес вложения в Storage — он же подставляется в условие."""
        def resolve(local_path):
            return '{}/{}'.format(STORAGE_BUCKET, storage_path(local_path))
        return resolve

    def build(self):
        """Строки таблиц tasks, task_themes и task_files."""
        resolve = self._asset_url_factory()
        tasks, links, themes, files = [], [], [], []

        for task in self.tasks:
            task_id = task_uuid(task['id'])
            theme_codes = [t['code'] for t in task['themes']]
            number = self._number_by_task.get(task['id'])
            statement, missing = html_to_markdown(
                task['condition_html_local'], resolve
            )
            answer_format = ANSWER_FORMATS.get(task['answer_type'])
            if answer_format is None:
                raise BankError(
                    'Неизвестный тип ответа «{}» у задания {}'.format(
                        task['answer_type'], task['short_id']
                    )
                )
            if task.get('answer_options'):
                statement = _append_options(statement, task['answer_options'])

            tasks.append({
                'id': task_id,
                'slug': 'fipi-' + task['short_id'].lower(),
                'ege_number': number,
                'ege_number_source': EGE_NUMBER_SOURCE if number else None,
                'title': make_title(task['condition_text']),
                'statement_md': statement,
                'difficulty': self._difficulty(number, theme_codes),
                'answer_format': answer_format,
                'tags': theme_codes,
                'status': 'draft',
                'origin': 'fipi',
                'source': task.get('source_url'),
                'fipi_id': task['id'],
                'fipi_short_id': task['short_id'],
                'condition_incomplete': bool(task.get('condition_incomplete')),
            })

            if task.get('parent_id') or task.get('duplicate_of'):
                links.append({
                    'id': task_id,
                    'parent_task_id': task_uuid(task['parent_id'])
                    if task.get('parent_id') else None,
                    'duplicate_of': task_uuid(task['duplicate_of'])
                    if task.get('duplicate_of') else None,
                })

            codes = theme_codes or [NO_THEME_CODE]
            if not theme_codes:
                self.stats['tasks_without_theme'] += 1
            for order, code in enumerate(codes):
                themes.append({
                    'task_id': task_id,
                    'theme_code': code,
                    'sort_order': order,
                })

            assets = task.get('assets') or []
            if assets:
                self.stats['tasks_with_files'] += 1
            for order, asset in enumerate(assets):
                files.append(self._file_row(task_id, asset, order))

            if missing:
                self.stats['missing_images'] += len(missing)
                self.stats['tasks_with_missing_images'] += 1
            if number is not None:
                self.stats['tasks_with_number'] += 1
            else:
                self.stats['tasks_without_number'] += 1
            if task.get('parent_id'):
                self.stats['parents'] += 1
            if task.get('duplicate_of'):
                self.stats['duplicates'] += 1
            if task.get('condition_incomplete'):
                self.stats['incomplete'] += 1

        self.stats['tasks'] = len(tasks)
        self.stats['task_themes'] = len(themes)
        self.stats['files'] = len(files)
        self.stats['files_on_disk'] = (
            len(files) - len(self.stats['missing_asset_files'])
        )
        self.stats['assets_orphaned'] = self._count_orphans(files)
        return tasks, links, themes, files

    def _count_orphans(self, files):
        """Файлы в каталоге вложений, на которые выгрузка не ссылается.

        Пересборка выгрузки перенумеровывает вложения задания, а старые
        файлы из каталога не удаляет. Импорт идёт по `tasks.json`, поэтому
        хвосты в базу не попадают — но знать о них надо.
        """
        assets_dir = os.path.join(self.root, 'assets')
        if not os.path.isdir(assets_dir):
            return 0
        referenced = {row['storage_path'] for row in files}
        orphans = 0
        for current, _, names in os.walk(assets_dir):
            for name in names:
                full = os.path.join(current, name)
                relative = os.path.relpath(full, self.root)
                if storage_path(relative) not in referenced:
                    orphans += 1
        return orphans

    def _file_row(self, task_id, asset, order):
        local_path = asset['local_path']
        full_path = os.path.join(self.root, local_path)
        if os.path.exists(full_path):
            size = os.path.getsize(full_path)
        else:
            self.stats['missing_asset_files'].append(local_path)
            size = asset.get('bytes_size') or 0
        filename = os.path.basename(local_path)
        return {
            'task_id': task_id,
            'filename': filename,
            'content': None,
            'storage_bucket': STORAGE_BUCKET,
            'storage_path': storage_path(local_path),
            'content_type': content_type_for(filename),
            'source_url': asset.get('url'),
            'kind': 'image' if asset.get('kind') == 'image' else 'file',
            'size_bytes': size,
            'sort_order': order,
        }


def _append_options(statement, options):
    """Варианты ответа банк держит отдельно от условия — дописываем списком."""
    lines = ['**Варианты ответа:**']
    for index, option in enumerate(options, start=1):
        if isinstance(option, dict):
            marker = str(option.get('value') or index)
            text = str(option.get('text') or '')
        else:
            marker, text = str(index), str(option)
        text = _WHITESPACE_RE.sub(' ', text).strip()
        if text:
            lines.append('{}. {}'.format(marker, text))
    if len(lines) == 1:
        return statement
    return statement + '\n\n' + '\n'.join(lines)
