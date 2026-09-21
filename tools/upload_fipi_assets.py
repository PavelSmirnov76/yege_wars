#!/usr/bin/env python3
"""Заливка вложений банка ФИПИ в Supabase Storage.

Импорт (`tools/import_fipi_bank.py`) кладёт в `task_files` адреса файлов,
а не их содержимое: 405 МБ архивов и таблиц в базу не помещаются ни по
типу колонки, ни по лимиту бесплатного тарифа. Сами файлы отправляет сюда
этот скрипт — один раз, после применения миграций.

Доступы берутся из переменных окружения (как в tools/content_client.py):

    SUPABASE_URL          https://<ref>.supabase.co
    SUPABASE_ANON_KEY     публичный ключ проекта
    CONTENT_API_LOGIN     логин администратора (например ai_author)
    CONTENT_API_PASSWORD  его пароль

Запуск:

    set -a; . supabase/.env.local; set +a
    python3 tools/upload_fipi_assets.py --dump ~/projects/ege-informatics-2027
    python3 tools/upload_fipi_assets.py --dry-run    # только посчитать

Заливка идёт по одному файлу и продолжается с места обрыва: уже загруженные
объекты пропускаются, если не указан --force.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from content_client import ContentApiError, ContentClient  # noqa: E402
from fipi_import.bank import (  # noqa: E402
    STORAGE_BUCKET,
    content_type_for,
    storage_path,
)

DEFAULT_DUMP = '~/projects/ege-informatics-2027'
TIMEOUT_SECONDS = 300


def assets_of(dump_root):
    """Пары «локальный путь -> путь в бакете» для всех вложений выгрузки."""
    with open(os.path.join(dump_root, 'tasks.json'), encoding='utf-8') as handle:
        tasks = json.load(handle)
    seen = {}
    for task in tasks:
        for asset in task.get('assets') or []:
            local = asset['local_path']
            seen[local] = storage_path(local)
    return sorted(seen.items())


class StorageUploader:
    """Отправка файлов в бакет через Storage API."""

    def __init__(self, client, bucket=STORAGE_BUCKET):
        self._client = client
        self._bucket = bucket

    def _url(self, path):
        quoted = urllib.parse.quote(path)
        return '{}/storage/v1/object/{}/{}'.format(
            self._client.url, self._bucket, quoted
        )

    def exists(self, path):
        """Есть ли объект в бакете."""
        request = urllib.request.Request(
            self._url(path),
            headers={
                'apikey': self._client.anon_key,
                'Authorization': 'Bearer {}'.format(self._client.token),
            },
            method='HEAD',
        )
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS):
                return True
        except urllib.error.HTTPError as error:
            if error.code in (400, 404):
                return False
            raise ContentApiError(
                'storage', 'Не удалось проверить {}: {}'.format(path, error.code),
                error.code,
            ) from error

    def upload(self, local_path, path, overwrite=False):
        """Отправляет файл; возвращает число отправленных байт."""
        with open(local_path, 'rb') as handle:
            body = handle.read()
        headers = {
            'apikey': self._client.anon_key,
            'Authorization': 'Bearer {}'.format(self._client.token),
            'Content-Type': content_type_for(path) or 'application/octet-stream',
            'Cache-Control': 'public, max-age=31536000',
        }
        if overwrite:
            headers['x-upsert'] = 'true'
        request = urllib.request.Request(
            self._url(path), data=body, headers=headers, method='POST',
        )
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS):
                return len(body)
        except urllib.error.HTTPError as error:
            detail = error.read().decode('utf-8', 'replace')
            raise ContentApiError(
                'storage', 'Не удалось залить {}: {} {}'.format(
                    path, error.code, detail),
                error.code,
            ) from error


def main(argv=None):
    parser = argparse.ArgumentParser(
        description='Заливает вложения банка ФИПИ в Supabase Storage.')
    parser.add_argument('--dump', default=os.environ.get('FIPI_DUMP',
                                                         DEFAULT_DUMP))
    parser.add_argument('--dry-run', action='store_true',
                        help='ничего не отправлять, только посчитать')
    parser.add_argument('--force', action='store_true',
                        help='перезаписывать уже загруженные файлы')
    parser.add_argument('--limit', type=int,
                        help='отправить не больше указанного числа файлов')
    args = parser.parse_args(argv)

    dump_root = os.path.abspath(os.path.expanduser(args.dump))
    if not os.path.exists(os.path.join(dump_root, 'tasks.json')):
        print('ОШИБКА: в «{}» нет tasks.json'.format(dump_root), file=sys.stderr)
        return 1

    assets = assets_of(dump_root)
    total_bytes = 0
    absent = []
    for local, _ in assets:
        full = os.path.join(dump_root, local)
        if os.path.exists(full):
            total_bytes += os.path.getsize(full)
        else:
            absent.append(local)

    print('Вложений в выгрузке: {}, суммарно {:.1f} МБ'.format(
        len(assets), total_bytes / 1e6))
    if absent:
        print('Нет на диске: {} файлов, например {}'.format(
            len(absent), absent[0]), file=sys.stderr)
    if args.dry_run:
        return 0

    try:
        client = ContentClient()
        uploader = StorageUploader(client)
    except ContentApiError as error:
        print('ОШИБКА: {}'.format(error), file=sys.stderr)
        return 1

    sent = skipped = failed = 0
    sent_bytes = 0
    for index, (local, path) in enumerate(assets, start=1):
        full = os.path.join(dump_root, local)
        if not os.path.exists(full):
            failed += 1
            continue
        if args.limit and sent >= args.limit:
            break
        try:
            if not args.force and uploader.exists(path):
                skipped += 1
                continue
            sent_bytes += uploader.upload(full, path, overwrite=args.force)
            sent += 1
        except ContentApiError as error:
            failed += 1
            print('ОШИБКА: {}'.format(error), file=sys.stderr)
        if index % 50 == 0:
            print('  {} из {}: отправлено {}, пропущено {}, ошибок {}'.format(
                index, len(assets), sent, skipped, failed))

    print('Готово: отправлено {} ({:.1f} МБ), пропущено {}, ошибок {}'.format(
        sent, sent_bytes / 1e6, skipped, failed))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
