#!/usr/bin/env python3
"""Импорт открытого банка заданий ФИПИ в базу проекта.

Скрипт не ходит в сеть и не подключается к базе сам: он читает выгрузку и
собирает SQL-скрипт, который заливается через psql. Так один и тот же файл
проверяется на временном PostgreSQL и применяется к боевому Supabase.

    python3 tools/import_fipi_bank.py --dump ~/projects/ege-informatics-2027 \
        --out /tmp/fipi.sql --stats /tmp/fipi.json
    psql "$SEED_DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/fipi.sql

Вложения (963 файла) скрипт не заливает: они лежат в Supabase Storage,
их отправляет tools/upload_fipi_assets.py.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fipi_import.bank import Bank, BankError  # noqa: E402
from fipi_import.sql import copy_block, quote_literal  # noqa: E402

DEFAULT_DUMP = '~/projects/ege-informatics-2027'

THEME_COLUMNS = ['code', 'title', 'section_code', 'section_title', 'level',
                 'sort_order']

ARTICLE_COLUMNS = ['slug', 'title', 'summary', 'content_md', 'theme_code',
                   'ege_numbers', 'tags', 'level', 'reading_minutes',
                   'is_published']

TASK_COLUMNS = ['id', 'slug', 'ege_number', 'ege_number_source', 'title',
                'statement_md', 'difficulty', 'answer_format', 'tags',
                'status', 'origin', 'source', 'fipi_id', 'fipi_short_id',
                'condition_incomplete']

TASK_THEME_COLUMNS = ['task_id', 'theme_code', 'sort_order']

TASK_FILE_COLUMNS = ['task_id', 'filename', 'content', 'storage_bucket',
                     'storage_path', 'content_type', 'source_url', 'kind',
                     'size_bytes', 'sort_order']

HEADER = """-- =============================================================================
-- Импорт открытого банка заданий ФИПИ. Файл собран tools/import_fipi_bank.py,
-- руками не правится. Источник: {source}, выгрузка от {downloaded}.
-- =============================================================================
begin;

-- Повторный запуск заменяет прежний импорт целиком.
delete from public.tasks where origin = 'fipi';
delete from public.reference_articles where theme_code is not null;
delete from public.themes where code <> 'none';
"""

FOOTER = """
commit;
"""


def build_script(bank):
    """Текст SQL-скрипта импорта."""
    metadata_path = os.path.join(bank.root, 'metadata.json')
    metadata = {}
    if os.path.exists(metadata_path):
        with open(metadata_path, encoding='utf-8') as handle:
            metadata = json.load(handle)

    tasks, links, task_themes, task_files = bank.build()

    parts = [HEADER.format(
        source=metadata.get('source', 'неизвестен'),
        downloaded=metadata.get('download_date', 'неизвестной даты'),
    )]
    parts.append(copy_block('public.themes', THEME_COLUMNS, bank.themes()))
    parts.append(copy_block('public.reference_articles', ARTICLE_COLUMNS,
                            bank.articles()))
    parts.append(copy_block('public.tasks', TASK_COLUMNS, tasks))

    # Связи задача -> задача проставляются после вставки: задание 20 ссылается
    # на задание 19, которое в том же COPY может идти позже.
    for link in links:
        parts.append(
            'update public.tasks set parent_task_id = {parent}, '
            'duplicate_of = {duplicate} where id = {id};'.format(
                parent=quote_literal(link['parent_task_id'])
                if link['parent_task_id'] else 'null',
                duplicate=quote_literal(link['duplicate_of'])
                if link['duplicate_of'] else 'null',
                id=quote_literal(link['id']),
            )
        )
    if links:
        parts.append('')

    parts.append(copy_block('public.task_themes', TASK_THEME_COLUMNS,
                            task_themes))
    parts.append(copy_block('public.task_files', TASK_FILE_COLUMNS, task_files))
    parts.append(FOOTER)
    return '\n'.join(parts)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description='Собирает SQL-скрипт импорта банка ФИПИ.')
    parser.add_argument('--dump', default=os.environ.get('FIPI_DUMP',
                                                         DEFAULT_DUMP),
                        help='каталог выгрузки банка (по умолчанию %(default)s)')
    parser.add_argument('--out', default='-',
                        help='куда писать SQL; «-» — в стандартный вывод')
    parser.add_argument('--stats',
                        help='файл, куда сложить статистику импорта в JSON')
    args = parser.parse_args(argv)

    try:
        bank = Bank(args.dump)
        script = build_script(bank)
    except BankError as error:
        print('ОШИБКА: {}'.format(error), file=sys.stderr)
        return 1

    if args.out == '-':
        sys.stdout.write(script)
    else:
        with open(args.out, 'w', encoding='utf-8') as handle:
            handle.write(script)

    if args.stats:
        with open(args.stats, 'w', encoding='utf-8') as handle:
            json.dump(bank.stats, handle, ensure_ascii=False, indent=2)

    missing = bank.stats['missing_asset_files']
    if missing:
        print('ВНИМАНИЕ: в выгрузке нет {} файлов вложений, например {}'.format(
            len(missing), missing[0]), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
