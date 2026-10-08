"""CLI скрипта конвейера: `python3 -m sdlc_tool <команда> [параметры]`.

Команды и коды возврата — README скрипта, «Команды». Общий параметр
`--root` можно дать и до команды, и после неё. Отказ команды
(`model.Refusal`) печатается в stderr строкой `ОТКАЗ: …` с кодом отказа.
Мутирующие команды (`entomb`, `snapshot-prd`, `run`) после работы
пересобирают производные файлы (`views.write_all`) по заново прочитанному
дереву; `run` — и при `FAIL`/`BLOCKED`, но не при отказе.
"""

from __future__ import annotations

import argparse
import datetime
import os
import sys
from typing import List, Optional, Sequence

from . import check, ids, model, tomb, views
from . import run as runner


def _date(value: str) -> str:
    if not model.valid_date(value):
        raise argparse.ArgumentTypeError(f'дата {value} — не ГГГГ-ММ-ДД')
    return value


def _today() -> str:
    return datetime.date.today().isoformat()


def _print_changed(paths: List[str]) -> None:
    for path in paths:
        print(f'обновлено: {path}')


def _rebuild_views(root: str) -> None:
    try:
        changed = views.write_all(model.load_repo(root))
    except NotImplementedError:
        print('ПРЕДУПРЕЖДЕНИЕ: views ещё не реализован — производные файлы '
              'не пересобраны', file=sys.stderr)
        return
    _print_changed(changed)


def _cmd_check(args: argparse.Namespace) -> int:
    base = None if args.base.lower() == 'none' else args.base
    return check.run(args.root, base)


def _cmd_views(args: argparse.Namespace) -> int:
    _print_changed(views.write_all(model.load_repo(args.root)))
    return 0


def _cmd_next(args: argparse.Namespace) -> int:
    print(ids.next_id(model.load_repo(args.root), args.type, args.owner))
    return 0


def _cmd_entomb(args: argparse.Namespace) -> int:
    by = None if args.by.lower() == 'none' else args.by
    changed = tomb.entomb(model.load_repo(args.root), args.id, by, args.why,
                          args.date or _today())
    _print_changed(changed)
    _rebuild_views(args.root)
    return 0


def _cmd_snapshot_prd(args: argparse.Namespace) -> int:
    path = tomb.snapshot_prd(model.load_repo(args.root), args.why, args.input,
                             args.date or _today())
    print(f'снимок: {path}')
    _rebuild_views(args.root)
    return 0


def _cmd_run(args: argparse.Namespace) -> int:
    skip = [name.strip() for name in (args.skip or '').split(',') if name.strip()]
    code = runner.run(model.load_repo(args.root), allow_dirty=args.allow_dirty,
                      skip=skip)
    _rebuild_views(args.root)
    return code


def build_parser() -> argparse.ArgumentParser:
    """Парсер команд; у каждой подкоманды — `handler(args) -> код`."""
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument('--root', default=argparse.SUPPRESS, metavar='ПУТЬ',
                        help='корень репозитория (по умолчанию — текущая папка)')
    parser = argparse.ArgumentParser(
        prog='python3 -m sdlc_tool',
        description='Скрипт конвейера sdlc/: id, ссылки, производные файлы, прогоны.',
    )
    parser.add_argument('--root', default='.', metavar='ПУТЬ',
                        help='корень репозитория (по умолчанию — текущая папка)')
    commands = parser.add_subparsers(dest='command', metavar='команда')
    commands.required = True

    command = commands.add_parser('check', parents=[common], help='все проверки')
    command.add_argument('--base', default='HEAD', metavar='REF',
                         help='коммит базы (по умолчанию HEAD); none — без базы')
    command.set_defaults(handler=_cmd_check)

    command = commands.add_parser('views', parents=[common],
                                  help='пересобрать INDEX.md и DASHBOARD.md')
    command.set_defaults(handler=_cmd_views)

    command = commands.add_parser('next', parents=[common], help='следующий id')
    command.add_argument('type', metavar='ТИП', help='R, BT, MOD, …, RESULT, ACC')
    command.add_argument('owner', nargs='?', metavar='ВЛАДЕЛЕЦ',
                         help='у RESULT — TASK-{n}, у ACC — RESULT-TASK-{n}-{NN}')
    command.set_defaults(handler=_cmd_next)

    command = commands.add_parser(
        'entomb', parents=[common],
        help='похоронить артефакт или отметить устаревшим требование')
    command.add_argument('id', metavar='ID', help='id артефакта или требования (R7)')
    command.add_argument('--by', required=True, metavar='ID|none',
                         help='чем заменён; none — ничем')
    command.add_argument('--why', metavar='ТЕКСТ', help='почему')
    command.add_argument('--date', type=_date, metavar='ГГГГ-ММ-ДД',
                         help='дата (по умолчанию — сегодня)')
    command.set_defaults(handler=_cmd_entomb)

    command = commands.add_parser('snapshot-prd', parents=[common],
                                  help='снять PRD в history/')
    command.add_argument('--why', required=True, metavar='ТЕКСТ', help='почему')
    command.add_argument('--input', required=True, metavar='ПУТЬ',
                         help='вход: папка raw/<дата>/ или сигнал 9-observation/')
    command.add_argument('--date', type=_date, metavar='ГГГГ-ММ-ДД',
                         help='дата (по умолчанию — сегодня)')
    command.set_defaults(handler=_cmd_snapshot_prd)

    command = commands.add_parser('run', parents=[common],
                                  help='прогнать проверки проекта')
    command.add_argument('--allow-dirty', action='store_true',
                         help='проверять и с незакоммиченными изменениями')
    command.add_argument('--skip', metavar='ИМЯ,…', help='пропустить проверки')
    command.set_defaults(handler=_cmd_run)
    return parser


def _utf8_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        encoding = (getattr(stream, 'encoding', '') or '').lower().replace('-', '')
        reconfigure = getattr(stream, 'reconfigure', None)
        if reconfigure is not None and encoding != 'utf8':
            try:
                reconfigure(encoding='utf-8')
            except (ValueError, OSError):
                pass


def main(argv: Optional[Sequence[str]] = None) -> int:
    """Точка входа; возвращает код возврата."""
    _utf8_stdio()
    args = build_parser().parse_args(argv)
    args.root = os.path.abspath(args.root)
    if not os.path.isdir(args.root):
        print(f'ОТКАЗ: нет папки {args.root}', file=sys.stderr)
        return 2
    try:
        return args.handler(args)
    except model.Refusal as refusal:
        print(f'ОТКАЗ: {refusal}', file=sys.stderr)
        return refusal.code
    except NotImplementedError as error:
        print(f'ОШИБКА: команда ещё не реализована: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
