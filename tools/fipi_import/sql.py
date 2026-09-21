"""Сборка SQL-скрипта импорта: COPY вместо тысяч INSERT.

Скрипт получается самодостаточным: его можно скормить psql как локальной
проверочной базе, так и боевому Supabase через Session Pooler.
"""

from __future__ import annotations

# Экранирование текстового формата COPY: обратный слэш и управляющие символы.
_COPY_ESCAPES = (
    ('\\', '\\\\'),
    ('\b', '\\b'),
    ('\f', '\\f'),
    ('\n', '\\n'),
    ('\r', '\\r'),
    ('\t', '\\t'),
    ('\v', '\\v'),
)


def copy_text(value):
    """Значение в текстовом формате COPY; None превращается в \\N."""
    if value is None:
        return r'\N'
    if isinstance(value, bool):
        return 't' if value else 'f'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, tuple)):
        return _array_literal(value)
    text = str(value)
    for source, target in _COPY_ESCAPES:
        text = text.replace(source, target)
    return text


def _array_literal(values):
    """Литерал массива PostgreSQL; элементы всегда в кавычках."""
    items = []
    for value in values:
        if value is None:
            items.append('NULL')
            continue
        item = str(value).replace('\\', '\\\\').replace('"', '\\"')
        items.append('"{}"'.format(item))
    return _escape_plain('{' + ','.join(items) + '}')


def _escape_plain(text):
    """Экранирование COPY для уже собранного литерала."""
    for source, target in _COPY_ESCAPES:
        text = text.replace(source, target)
    return text


def copy_block(table, columns, rows):
    """Команда COPY со встроенными данными — psql читает их прямо из файла."""
    lines = ['copy {} ({}) from stdin;'.format(table, ', '.join(columns))]
    for row in rows:
        lines.append('\t'.join(copy_text(row.get(column)) for column in columns))
    lines.append('\\.')
    lines.append('')
    return '\n'.join(lines)


def quote_literal(value):
    """Строковый литерал SQL."""
    if value is None:
        return 'null'
    return "'" + str(value).replace("'", "''") + "'"
