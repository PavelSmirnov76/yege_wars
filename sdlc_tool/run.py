"""Прогон проверок проекта: команда `run`.

Формат прогона — README скрипта, «Прогон `run`»; правила папки прогона —
`sdlc/6-eval/auto/AGENTS.md`. Git — через `gitbase`. Внешний мир — команды,
поиск программ, переменные окружения, домашняя папка и часы — идёт через
исполнитель `Executor`: тесты подменяют его (`EXECUTOR` или аргумент
`run_with`) и Flutter не запускают.

Как прочитаны места, где спецификация допускает разное:

- Подготовка (`pub_get`, `gen_l10n`, `build_runner`) — не вердикт о системе:
  в таблице README у неё «подготовка», а не «по коду возврата». Упавшая
  подготовка получает `BLOCKED`; следующая за ней подготовка и проверки
  Flutter (`analyze`, `custom_lint`, `format`, `flutter_test`) — тоже
  `BLOCKED` с причиной. Подготовка, пропущенная через `--skip`, считается
  сделанной.
- Программа ищется для каждой проверки своя: `flutter` — `SDLC_FLUTTER`,
  затем `~/fvm/versions/<версия из .fvmrc>/bin/flutter`, затем `PATH`;
  `dart` — так же, через `SDLC_DART`. Переменная задана, но не ведёт к
  исполняемому файлу, — `BLOCKED` без перехода к следующему способу: иначе
  прогон молча взял бы другой Flutter.
- Пропущенная проверка остаётся в `checks` с `"verdict": null` и причиной,
  чтобы частичный прогон не выглядел полным; на код возврата она не влияет.
- `totals` — число строк `tests` по вердиктам («тест без метки входит в
  итоги», `6-eval/auto/AGENTS.md`); вердикты проверок — в `checks`.
- Тест с несколькими разными метками путей даёт по строке `tests` на каждую
  метку, тест без метки — одну строку с `"label": null`.
- Полное имя теста Flutter — `name` из `testStart` (в нём уже есть имена
  групп); если имени внутренней группы в начале нет, оно дописывается.
- Тест Flutter без `testDone` (процесс оборвался) — `FAIL`; повторный
  `testDone` того же теста (ошибка после завершения) заменяет прежний.
- `flutter_test` — `FAIL`, если упал хоть один тест или код возврата не 0.
  Его хвост — упавшие тесты с ошибками (у стека — первые 10 строк), затем
  stderr.
- Метки SQL — из комментариев `--` и `/* … */` в `supabase/tests/*.sql`, в
  том числе внутри тел `$$ … $$`; строки в кавычках — не комментарии.
  Строка `tests` метки SQL: `file` — файл, `name` — текст комментария,
  вердикт — вердикт `rls`. Пропущен `rls` — таких строк нет.
- `rls` — `PASS`, если код 0 и в выводе есть строка `RLS OK` целиком.
- Тесты Python — тем же интерпретатором, что запустил скрипт
  (`sys.executable`); в `command` — `python3`, как в README.
- `format` — по файлам `.dart` из `lib/` и `test/`, которые видит git, без
  `*.g.dart` и `lib/l10n/gen/` (то же, что `find` в CI на чистой копии). Нет
  таких файлов — `PASS` без запуска.
- `started_at` и `finished_at` — UTC с `+00:00`: строки сравниваются как
  время на любой машине. `date` и имя папки — дата начала по локальному
  времени, как дата по умолчанию у других команд.
- Хвост вывода — только у проверок, которые выполнялись и не прошли. Путь
  корня репозитория в выводе и в именах тестов заменяется относительным,
  домашняя папка — `~`: прогон не зависит от машины. Кроме строк
  подключения (`postgres://…`, URI с паролем, `host=… password=…`), ключей
  `sb_secret_…` и JWT маскируется значение `…PASSWORD=…`.
- Суффикс папки — на единицу больше наибольшего среди папок этого коммита
  за этот день: `-02`, `-03`…
- В таблице путей `summary.md` — только тесты с меткой пути; остальные — в
  `summary.json`.
"""

from __future__ import annotations

import collections
import datetime
import json
import os
import posixpath
import re
import shutil
import subprocess
import sys
import urllib.parse
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional, Sequence, TextIO, Tuple

from . import gitbase, model

PASS = 'PASS'
FAIL = 'FAIL'
BLOCKED = 'BLOCKED'
VERDICT_CODES: Dict[str, int] = {PASS: 0, FAIL: 1, BLOCKED: 3}

USAGE_CODE = 2   # неизвестное имя в --skip, не git
DIRTY_CODE = 1   # незакоммиченные изменения без --allow-dirty

FLUTTER = 'flutter'
DART = 'dart'
BASH = 'bash'
PYTHON = 'python3'
# Переменная окружения с путём к программе (README, «Прогон `run`»).
PROGRAM_VARIABLES: Dict[str, str] = {FLUTTER: 'SDLC_FLUTTER', DART: 'SDLC_DART'}
FVMRC = '.fvmrc'
POSTGRES_BIN = '/opt/homebrew/opt/postgresql@17/bin'
PG_CTL = 'pg_ctl'

RLS = 'rls'
FLUTTER_TEST = 'flutter_test'
FORMAT = 'format'
RLS_SCRIPT = 'supabase/tests/run_local.sh'
RLS_OK = 'RLS OK'
SQL_TESTS_DIR = 'supabase/tests'
FORMAT_DIRS: Tuple[str, ...] = ('lib', 'test')
GENERATED_DIR = 'lib/l10n/gen/'

SUMMARY_JSON = 'summary.json'
SUMMARY_MD = 'summary.md'
TAIL_LINES = 60
STACK_LINES = 10  # строк стека у ошибки теста Flutter: хвост не тонет в кадрах flutter_tools
MASK = '***'
SKIP_REASON = 'пропущена: --skip'
NO_POSTGRES = (f'нет PostgreSQL: нужен {PG_CTL} в PATH или в {POSTGRES_BIN} — '
               'поставьте postgresql@17 (brew install postgresql@17)')


# --------------------------------------------------------------------------
# Проверки


@dataclass(frozen=True)
class CheckSpec:
    """Проверка из таблицы README: имя, команда для итога, программа и её
    аргументы; `prep` — подготовка, `flutter` — проверка группы Flutter."""

    name: str
    command: str
    program: str
    args: Tuple[str, ...]
    prep: bool = False
    flutter: bool = False


CHECKS: Tuple[CheckSpec, ...] = (
    CheckSpec('pub_get', 'flutter pub get', FLUTTER, ('pub', 'get'),
              prep=True, flutter=True),
    CheckSpec('gen_l10n', 'flutter gen-l10n', FLUTTER, ('gen-l10n',),
              prep=True, flutter=True),
    CheckSpec('build_runner', 'dart run build_runner build --delete-conflicting-outputs',
              DART, ('run', 'build_runner', 'build', '--delete-conflicting-outputs'),
              prep=True, flutter=True),
    CheckSpec('analyze', 'flutter analyze --fatal-infos --fatal-warnings', FLUTTER,
              ('analyze', '--fatal-infos', '--fatal-warnings'), flutter=True),
    CheckSpec('custom_lint', 'dart run custom_lint', DART, ('run', 'custom_lint'),
              flutter=True),
    CheckSpec(FORMAT, 'dart format --output=none --set-exit-if-changed '
              '<.dart из lib/ и test/ без *.g.dart и lib/l10n/gen/>', DART,
              ('format', '--output=none', '--set-exit-if-changed'), flutter=True),
    CheckSpec(FLUTTER_TEST, 'flutter test --reporter json', FLUTTER,
              ('test', '--reporter', 'json'), flutter=True),
    CheckSpec(RLS, f'bash {RLS_SCRIPT}', BASH, (RLS_SCRIPT,)),
    CheckSpec('tools_tests', 'python3 -m unittest discover -s tools/tests -t .', PYTHON,
              ('-m', 'unittest', 'discover', '-s', 'tools/tests', '-t', '.')),
    CheckSpec('sdlc_tool_tests', 'python3 -m unittest discover -s sdlc_tool/tests -t .',
              PYTHON, ('-m', 'unittest', 'discover', '-s', 'sdlc_tool/tests', '-t', '.')),
)
CHECK_NAMES: Tuple[str, ...] = tuple(spec.name for spec in CHECKS)


@dataclass
class CheckResult:
    """Итог проверки — строка `checks` в `summary.json`.

    `verdict` None — проверка пропущена. `exit_code` None — команда не
    выполнялась."""

    name: str
    command: str
    verdict: Optional[str]
    exit_code: Optional[int] = None
    reason: Optional[str] = None
    output_tail: Optional[str] = None

    def as_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'command': self.command,
            'verdict': self.verdict,
            'exit_code': self.exit_code,
            'reason': self.reason,
            'output_tail': self.output_tail,
        }


@dataclass(frozen=True)
class TestRow:
    """Строка `tests`: файл от корня (None — неизвестен), имя, метка пути
    (None — без метки), вердикт."""

    file: Optional[str]
    name: str
    label: Optional[str]
    verdict: str

    def as_dict(self) -> Dict[str, Any]:
        return {'file': self.file, 'name': self.name, 'label': self.label,
                'verdict': self.verdict}

    @property
    def sort_key(self) -> Tuple[str, str, str, str]:
        return (self.file or '', self.name, self.label or '', self.verdict)


# --------------------------------------------------------------------------
# Исполнитель


@dataclass(frozen=True)
class CommandResult:
    """Итог внешней команды. При общем потоке весь вывод — в `stdout`."""

    exit_code: int
    stdout: str
    stderr: str = ''


def _decode(data: Optional[bytes]) -> str:
    # `\r` не трогаем: по нему `output_tail` оставляет последнее состояние строки.
    return (data or b'').decode('utf-8', errors='replace')


class Executor:
    """Исполнитель прогона: внешние команды, поиск программ, переменные
    окружения, домашняя папка и часы. Тесты подменяют его целиком."""

    def execute(
        self, argv: Sequence[str], cwd: str, separate_stderr: bool = False
    ) -> CommandResult:
        """Выполняет команду без ввода и ждёт её. OSError — не запускается.

        `separate_stderr` — stderr отдельно (нужно `flutter test`: события
        идут в stdout); иначе stderr слит с stdout в порядке вывода.
        """
        completed = subprocess.run(
            list(argv), cwd=cwd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE if separate_stderr else subprocess.STDOUT,
            check=False,
        )
        return CommandResult(completed.returncode, _decode(completed.stdout),
                             _decode(completed.stderr))

    def getenv(self, name: str) -> Optional[str]:
        return os.environ.get(name)

    def home(self) -> str:
        return os.path.expanduser('~')

    def is_executable(self, path: str) -> bool:
        return os.path.isfile(path) and os.access(path, os.X_OK)

    def which(self, name: str) -> Optional[str]:
        return shutil.which(name)

    def python(self) -> str:
        """Интерпретатор для тестов Python — тот же, что у скрипта."""
        return sys.executable or PYTHON

    def now(self) -> datetime.datetime:
        """Текущее время с часовым поясом машины."""
        return datetime.datetime.now().astimezone()


# Исполнитель команды `run`; тесты подменяют его через mock.patch.
EXECUTOR = Executor()


@dataclass(frozen=True)
class Program:
    """Найденная программа (`path`) или причина, по которой её нет."""

    path: Optional[str]
    reason: Optional[str] = None


def fvm_version(root: str) -> Optional[str]:
    """Версия Flutter из `.fvmrc` (`{"flutter": "3.41.0"}`); нет — None."""
    try:
        with open(os.path.join(root, FVMRC), encoding='utf-8') as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return None
    version = data.get('flutter') if isinstance(data, dict) else None
    if isinstance(version, str) and version.strip():
        return version.strip()
    return None


def find_program(executor: Executor, root: str, name: str) -> Program:
    """`flutter` или `dart`: переменная `SDLC_…`, затем fvm, затем `PATH`."""
    variable = PROGRAM_VARIABLES[name]
    value = executor.getenv(variable)
    if value:
        if executor.is_executable(value):
            return Program(value)
        return Program(None, f'{variable} задана, но не ведёт к исполняемому файлу '
                             f'{name} — поправьте или уберите её')
    version = fvm_version(root)
    if version:
        candidate = os.path.join(executor.home(), 'fvm', 'versions', version, 'bin', name)
        if executor.is_executable(candidate):
            return Program(candidate)
    found = executor.which(name)
    if found:
        return Program(found)
    fvm = (f', поставьте Flutter {version} в ~/fvm/versions/{version}/ '
           f'(fvm install {version})' if version else '')
    return Program(None, f'нет {name}: задайте {variable}{fvm} или добавьте {name} в PATH')


def find_postgres(executor: Executor) -> Optional[str]:
    """`pg_ctl` в `PATH` или в `/opt/homebrew/opt/postgresql@17/bin`."""
    found = executor.which(PG_CTL)
    if found:
        return found
    candidate = posixpath.join(POSTGRES_BIN, PG_CTL)
    return candidate if executor.is_executable(candidate) else None


# --------------------------------------------------------------------------
# Чистка вывода: пути машины и секреты


_SECRET_RES: Tuple[Tuple['re.Pattern[str]', str], ...] = (
    # Строка подключения URI: postgres://…, postgresql+psycopg://…, jdbc:postgresql://…
    (re.compile(r'(?:jdbc:)?postgres(?:ql)?(?:\+[A-Za-z0-9]+)?://[^\s\'"`<>]+',
                re.IGNORECASE), MASK),
    # Любая URI с паролем: scheme://user:password@host…
    (re.compile(r'\b[A-Za-z][A-Za-z0-9+.-]*://[^\s/@\'"`<>]*:[^\s/@\'"`<>]*@'
                r'[^\s\'"`<>]+'), MASK),
    # Строка подключения libpq: две и больше пары ключ=значение подряд.
    (re.compile(r'\b(?:host|hostaddr|port|dbname|user|password|sslmode)='
                r'(?:\'[^\']*\'|[^\s\'"`]+)'
                r'(?:[ \t]+(?:host|hostaddr|port|dbname|user|password|sslmode)='
                r'(?:\'[^\']*\'|[^\s\'"`]+))+', re.IGNORECASE), MASK),
    # Пароль в присваивании: password=…, PGPASSWORD=…, SUPABASE_DB_PASSWORD=…
    (re.compile(r'\b([A-Za-z0-9_]*password)=(?:\'[^\']*\'|"[^"]*"|[^\s\'"`]+)',
                re.IGNORECASE), r'\1=' + MASK),
    (re.compile(r'sb_secret_[A-Za-z0-9_-]+'), MASK),
    # JWT: три части base64url, заголовок — JSON-объект (`eyJ`).
    (re.compile(r'(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'),
     MASK),
)


def mask_secrets(text: str) -> str:
    """Заменяет строки подключения, ключи `sb_secret_…` и JWT на `***`."""
    for pattern, replacement in _SECRET_RES:
        text = pattern.sub(replacement, text)
    return text


class Scrubber:
    """Чистит текст для записи в прогон: путь корня репозитория —
    относительный, домашняя папка — `~`, секреты — `***`."""

    def __init__(self, root: str, home: Optional[str] = None) -> None:
        self._roots = self._variants(root)
        self._homes = self._variants(home) if home else []

    @staticmethod
    def _variants(path: str) -> List[str]:
        found = {os.path.abspath(path), os.path.realpath(path)}
        return sorted((item for item in found if item not in ('', '/')),
                      key=lambda item: (-len(item), item))

    def path(self, path: str) -> str:
        """Путь файла от корня через `/`, если он внутри корня."""
        for root in self._roots:
            if path == root:
                return '.'
            if path.startswith(root + '/'):
                return path[len(root) + 1:]
        return self.text(path)

    def text(self, text: str) -> str:
        for root in self._roots:
            text = text.replace(root + '/', '')
            text = re.sub(re.escape(root) + r'(?![\w.-])', '.', text)
        for home in self._homes:
            text = text.replace(home + '/', '~/')
            text = re.sub(re.escape(home) + r'(?![\w.-])', '~', text)
        return mask_secrets(text)


_ANSI_RE = re.compile(r'\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)')


def output_tail(text: str, scrub: Scrubber, limit: int = TAIL_LINES) -> Optional[str]:
    """До `limit` последних непустых по краям строк вывода, вычищенных.

    Цвета терминала убираются, у строки с `\\r` остаётся то, что видно
    последним. Пустой вывод — None.
    """
    lines = [_ANSI_RE.sub('', raw).rstrip('\r').rsplit('\r', 1)[-1].rstrip()
             for raw in text.replace('\r\n', '\n').split('\n')]
    while lines and not lines[-1]:
        lines.pop()
    tail = lines[-limit:]
    while tail and not tail[0]:
        tail.pop(0)
    if not tail:
        return None
    return scrub.text('\n'.join(tail))


# --------------------------------------------------------------------------
# Метки путей


_PATH_LABEL_RE = re.compile(r'UC-([0-9]+)-P-([0-9]+)')


def path_labels(text: str) -> List[str]:
    """Метки путей UC (`UC-3-P-02`) в тексте, без повторов, по порядку."""
    found: List[str] = []
    for label in model.find_labels(text):
        if label.is_path and label.id not in found:
            found.append(label.id)
    return found


def label_key(label: str) -> Tuple[int, int, int, str]:
    """Порядок меток: по номеру UC и номеру пути, затем по тексту."""
    match = _PATH_LABEL_RE.fullmatch(label)
    if match is None:
        return (1, 0, 0, label)
    return (0, int(match.group(1)), int(match.group(2)), label)


# --------------------------------------------------------------------------
# События flutter test --reporter json


@dataclass
class FlutterTest:
    """Тест из событий `flutter test --reporter json`."""

    id: int
    name: str                      # полное имя: с именами групп
    file: Optional[str]            # файл набора от корня репозитория
    result: Optional[str] = None   # success, failure, error; None — нет testDone
    skipped: bool = False
    hidden: bool = False
    errors: List[str] = field(default_factory=list)

    @property
    def verdict(self) -> Optional[str]:
        """`PASS`, `FAIL` или None: скрытый и пропущенный тест не считается."""
        if self.hidden or self.skipped:
            return None
        return PASS if self.result == 'success' else FAIL


@dataclass
class FlutterReport:
    """Тесты в порядке `testStart` и строки stdout, которые не события."""

    tests: List[FlutterTest]
    other: List[str]


def _event(line: str) -> Optional[Dict[str, Any]]:
    line = line.strip()
    if not line.startswith('{'):
        return None
    try:
        event = json.loads(line)
    except ValueError:
        return None
    if isinstance(event, dict) and isinstance(event.get('type'), str):
        return event
    return None


def _dict(value: Any) -> Dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _full_name(name: str, group_ids: Any, groups: Dict[int, str]) -> str:
    """Имя теста с именем внутренней группы впереди (если его там нет)."""
    if not isinstance(group_ids, list) or not group_ids:
        return name
    prefix = groups.get(group_ids[-1], '')
    if not prefix or name == prefix or name.startswith(prefix + ' '):
        return name
    return f'{prefix} {name}' if name else prefix


def _url_file(url: Any, scrub: Scrubber) -> Optional[str]:
    if not isinstance(url, str) or not url.startswith('file://'):
        return None
    return scrub.path(urllib.parse.unquote(url[len('file://'):]))


def parse_flutter_events(stdout: str, scrub: Scrubber) -> FlutterReport:
    """Разбирает вывод `flutter test --reporter json`.

    Файл теста — путь набора (`suite.path`), иначе `root_url`/`url` теста.
    Имена и пути вычищаются (`Scrubber`).
    """
    suites: Dict[int, str] = {}
    groups: Dict[int, str] = {}
    tests: Dict[int, FlutterTest] = {}
    order: List[int] = []
    other: List[str] = []
    for line in stdout.split('\n'):
        event = _event(line)
        if event is None:
            if line.strip():
                other.append(line.rstrip())
            continue
        kind = event['type']
        if kind == 'suite':
            suite = _dict(event.get('suite'))
            if isinstance(suite.get('id'), int) and isinstance(suite.get('path'), str):
                suites[suite['id']] = scrub.path(suite['path'])
        elif kind == 'group':
            group = _dict(event.get('group'))
            if isinstance(group.get('id'), int):
                name = group.get('name')
                groups[group['id']] = name if isinstance(name, str) else ''
        elif kind == 'testStart':
            test = _dict(event.get('test'))
            test_id = test.get('id')
            if not isinstance(test_id, int):
                continue
            raw_name = test.get('name')
            name = _full_name(raw_name if isinstance(raw_name, str) else '',
                              test.get('groupIDs'), groups)
            suite_id = test.get('suiteID')
            file = suites.get(suite_id) if isinstance(suite_id, int) else None
            if file is None:
                file = _url_file(test.get('root_url') or test.get('url'), scrub)
            if test_id not in tests:
                order.append(test_id)
            tests[test_id] = FlutterTest(test_id, scrub.text(name), file)
        elif kind in ('testDone', 'error'):
            test_id = event.get('testID')
            found = tests.get(test_id) if isinstance(test_id, int) else None
            if found is None:
                continue
            if kind == 'testDone':
                result = event.get('result')
                found.result = result if isinstance(result, str) else None
                found.skipped = bool(event.get('skipped'))
                found.hidden = bool(event.get('hidden'))
                continue
            message, stack = event.get('error'), event.get('stackTrace')
            lines = message.rstrip().split('\n') if isinstance(message, str) else []
            if isinstance(stack, str) and stack.strip():
                lines += stack.rstrip().split('\n')[:STACK_LINES]
            if any(line.strip() for line in lines):
                found.errors.append('\n'.join(lines))
    return FlutterReport([tests[test_id] for test_id in order], other)


def flutter_rows(report: FlutterReport) -> List[TestRow]:
    """Строки `tests` по тестам Flutter: без скрытых и пропущенных, по строке
    на каждую метку пути (без метки — одна строка с `label` None)."""
    rows: List[TestRow] = []
    for test in report.tests:
        verdict = test.verdict
        if verdict is None:
            continue
        labels: List[Optional[str]] = list(path_labels(test.name)) or [None]
        for label in labels:
            rows.append(TestRow(test.file, test.name, label, verdict))
    return rows


def _failure_lines(failed: Sequence[FlutterTest]) -> List[str]:
    lines: List[str] = []
    for test in failed:
        lines.append(f'FAIL {test.file or "?"}: {test.name}')
        if test.result is None:
            lines.append('нет testDone: процесс оборвался до конца теста')
        for error in test.errors:
            lines += error.split('\n')
    return lines


# --------------------------------------------------------------------------
# Метки SQL


def _identifier_char(char: str) -> bool:
    return char.isalnum() or char in '_$'


_DOLLAR_TAG_RE = re.compile(r'\$(?:[^\W\d][\w]*)?\$')


def sql_comments(text: str, first_line: int = 1) -> List[Tuple[int, str]]:
    """Комментарии SQL: пары (номер строки, текст без `--`, `/*`, `*/`).

    Строки `'…'` (с `''`, у `E'…'` — и с `\\`), имена `"…"` — не
    комментарии. Тело `$тег$ … $тег$` разбирается как SQL: в нём код
    PL/pgSQL `DO $$ … $$` с теми же комментариями. Блочный комментарий
    (вложенный, как в PostgreSQL) даёт по паре на каждую свою строку.
    """
    comments: List[Tuple[int, str]] = []
    index, size, line = 0, len(text), first_line
    while index < size:
        char = text[index]
        if char == '\n':
            line += 1
            index += 1
            continue
        start = index
        if text.startswith('--', index):
            end = text.find('\n', index)
            end = size if end < 0 else end
            comments.append((line, text[index + 2:end]))
            index = end
            continue
        if text.startswith('/*', index):
            end, depth = index + 2, 1
            while end < size and depth:
                if text.startswith('/*', end):
                    depth += 1
                    end += 2
                elif text.startswith('*/', end):
                    depth -= 1
                    end += 2
                else:
                    end += 1
            body = text[index + 2:end - 2 if depth == 0 else end]
            for offset, part in enumerate(body.split('\n')):
                comments.append((line + offset, part))
            index = end
        elif char == "'":
            escapes = (index > 0 and text[index - 1] in 'eE'
                       and (index < 2 or not _identifier_char(text[index - 2])))
            end = index + 1
            while end < size:
                if escapes and text[end] == '\\':
                    end += 2
                elif text.startswith("''", end):
                    end += 2
                elif text[end] == "'":
                    end += 1
                    break
                else:
                    end += 1
            index = min(end, size)
        elif char == '"':
            end = text.find('"', index + 1)
            index = size if end < 0 else end + 1
        elif char == '$' and (index == 0 or not _identifier_char(text[index - 1])):
            match = _DOLLAR_TAG_RE.match(text, index)
            if match is None:
                index += 1
                continue
            close = text.find(match.group(0), match.end())
            body_end = size if close < 0 else close
            comments += sql_comments(text[match.end():body_end], line)
            index = size if close < 0 else close + len(match.group(0))
        else:
            index += 1
            continue
        line += text.count('\n', start, index)
    return comments


def sql_test_files(repo: model.Repo) -> List[str]:
    """Файлы `supabase/tests/*.sql`, которые видит git."""
    return sorted(path for path in repo.code_files()
                  if posixpath.dirname(path) == SQL_TESTS_DIR and path.endswith('.sql'))


def sql_rows(repo: model.Repo, verdict: str, scrub: Scrubber) -> List[TestRow]:
    """Строки `tests` по меткам путей в комментариях SQL с вердиктом `rls`."""
    rows: List[TestRow] = []
    for path in sql_test_files(repo):
        for _, comment in sql_comments(repo.source.read(path)):
            labels = path_labels(comment)
            if not labels:
                continue
            name = scrub.text(' '.join(comment.split()))
            for label in labels:
                rows.append(TestRow(path, name, label, verdict))
    return rows


# --------------------------------------------------------------------------
# Сводка прогона


def worst(verdicts: Iterable[Optional[str]]) -> str:
    """`FAIL`, если есть; иначе `BLOCKED`, если есть; иначе `PASS`."""
    found = set(verdicts)
    if FAIL in found:
        return FAIL
    if BLOCKED in found:
        return BLOCKED
    return PASS


def exit_code(verdicts: Iterable[Optional[str]]) -> int:
    """Код возврата по вердиктам проверок: 0, 1 (есть `FAIL`) или 3 (есть
    `BLOCKED`, но нет `FAIL`); пропущенные (None) не влияют."""
    return VERDICT_CODES[worst(verdicts)]


def path_verdicts(rows: Sequence[TestRow]) -> Dict[str, str]:
    """Метка пути → худший вердикт её тестов, по порядку меток."""
    found: Dict[str, List[str]] = {}
    for row in rows:
        if row.label:
            found.setdefault(row.label, []).append(row.verdict)
    return {label: worst(found[label]) for label in sorted(found, key=label_key)}


def totals(rows: Sequence[TestRow]) -> Dict[str, int]:
    counts = collections.Counter(row.verdict for row in rows)
    return {'pass': counts[PASS], 'fail': counts[FAIL], 'blocked': counts[BLOCKED]}


def _utc(moment: datetime.datetime) -> str:
    return moment.astimezone(datetime.timezone.utc).isoformat(timespec='seconds')


def build_summary(
    commit: str,
    commit_short: str,
    started: datetime.datetime,
    finished: datetime.datetime,
    dirty: bool,
    checks: Sequence[CheckResult],
    rows: Sequence[TestRow],
) -> Dict[str, Any]:
    """`summary.json` в порядке полей README."""
    ordered = sorted(rows, key=lambda row: row.sort_key)
    return {
        'commit': commit,
        'commit_short': commit_short,
        'date': started.date().isoformat(),
        'started_at': _utc(started),
        'finished_at': _utc(finished),
        'dirty': dirty,
        'checks': [check.as_dict() for check in checks],
        'tests': [row.as_dict() for row in ordered],
        'paths': path_verdicts(ordered),
        'totals': totals(ordered),
    }


def _cell(text: Any) -> str:
    if text is None or text == '':
        return '—'
    return ' '.join(str(text).split()).replace('|', '\\|')


def _fence(text: str) -> str:
    longest = max((len(run) for run in re.findall(r'`+', text)), default=0)
    return '`' * max(3, longest + 1)


def render_markdown(name: str, summary: Dict[str, Any]) -> str:
    """`summary.md`: коммит и дата, таблица проверок, таблица «путь UC | тест |
    вердикт», хвосты вывода упавших проверок."""
    checks = summary['checks']
    code = exit_code(check['verdict'] for check in checks)
    overall = {value: key for key, value in VERDICT_CODES.items()}[code]
    skipped = [check['name'] for check in checks if check['verdict'] is None]
    count = summary['totals']
    lines = [
        f'# Прогон {name}',
        '',
        f'- Коммит: `{summary["commit"]}`',
        f'- Дата: {summary["date"]}; начат {summary["started_at"]}, '
        f'закончен {summary["finished_at"]}',
        '- Незакоммиченные изменения: '
        + ('есть (`--allow-dirty`)' if summary['dirty'] else 'нет'),
        f'- Итог: {overall} (код {code})'
        + (f'; пропущены: {", ".join(skipped)}' if skipped else ''),
        f'- Тесты: PASS {count["pass"]}, FAIL {count["fail"]}, '
        f'BLOCKED {count["blocked"]}',
        '',
        '## Проверки',
        '',
        '| Проверка | Команда | Вердикт | Код | Причина |',
        '|---|---|---|---|---|',
    ]
    for check in checks:
        verdict = check['verdict'] or 'пропущена'
        exit_value = '—' if check['exit_code'] is None else str(check['exit_code'])
        lines.append(f'| {check["name"]} | `{check["command"]}` | {verdict} | '
                     f'{exit_value} | {_cell(check["reason"])} |')
    lines += ['', '## Пути UC', '']
    labelled = sorted((row for row in summary['tests'] if row['label']),
                      key=lambda row: (label_key(row['label']), row['file'] or '',
                                       row['name']))
    if labelled:
        lines += ['| Путь UC | Тест | Вердикт |', '|---|---|---|']
        for row in labelled:
            where = f'`{row["file"]}` — ' if row['file'] else ''
            lines.append(f'| {row["label"]} | {where}{_cell(row["name"])} | '
                         f'{row["verdict"]} |')
    else:
        lines.append('Тестов с меткой пути нет.')
    tails = [check for check in checks if check['output_tail']]
    if tails:
        lines += ['', '## Вывод упавших проверок']
        for check in tails:
            fence = _fence(check['output_tail'])
            lines += ['', f'### {check["name"]}', '', fence + 'text']
            lines += check['output_tail'].split('\n')
            lines.append(fence)
    return '\n'.join(lines) + '\n'


def run_dir_name(root: str, date: str, commit_short: str) -> str:
    """Имя папки прогона: `<дата>-<хэш>`, следующий того же дня — `…-02`."""
    base = f'{date}-{commit_short}'
    try:
        names = os.listdir(os.path.join(root, *model.AUTO_DIR.split('/')))
    except OSError:
        names = []
    pattern = re.compile(re.escape(base) + r'(?:-([0-9]{2,}))?')
    top = 0
    for name in names:
        match = pattern.fullmatch(name)
        if match:
            top = max(top, int(match.group(1)) if match.group(1) else 1)
    return base if top == 0 else f'{base}-{model.format_nn(top + 1)}'


_DIR_ATTEMPTS = 100


def _write_text(path: str, text: str) -> None:
    with open(path, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(text)


def write_run(root: str, summary: Dict[str, Any]) -> str:
    """Пишет `summary.json` и `summary.md` в новую папку прогона; возвращает
    её путь от корня. Прошлые прогоны не перезаписываются."""
    for _ in range(_DIR_ATTEMPTS):
        name = run_dir_name(root, summary['date'], summary['commit_short'])
        relative = f'{model.AUTO_DIR}/{name}'
        absolute = os.path.join(root, *relative.split('/'))
        try:
            os.makedirs(absolute)
        except FileExistsError:
            continue  # папку только что занял другой прогон — берём следующую
        break
    else:
        raise OSError(f'не удалось создать папку прогона в {model.AUTO_DIR}/')
    _write_text(os.path.join(absolute, SUMMARY_JSON),
                json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    _write_text(os.path.join(absolute, SUMMARY_MD), render_markdown(name, summary))
    return relative


# --------------------------------------------------------------------------
# Прогон


class _Blocked(Exception):
    """Проверка не может выполниться; `reason` — что её разблокирует."""

    def __init__(self, reason: str) -> None:
        super().__init__(reason)
        self.reason = reason


def format_files(root: str) -> List[str]:
    """Файлы для `format`: `.dart` из `lib/` и `test/`, которые видит git, без
    `*.g.dart` и `lib/l10n/gen/`."""
    return [path for path in gitbase.worktree_files(root, FORMAT_DIRS)
            if path.endswith('.dart') and not path.endswith('.g.dart')
            and not path.startswith(GENERATED_DIR)]


def _prep_problem(name: str, result: CheckResult) -> str:
    """Причина `BLOCKED` проверок Flutter после неудачной подготовки."""
    if result.exit_code is not None:
        return f'не прошла подготовка {name} (код {result.exit_code})'
    return f'не прошла подготовка {name}: {result.reason}'


class _Runner:
    """Проверки по порядку README: вердикты, строки `tests`, печать хода."""

    def __init__(self, repo: model.Repo, executor: Executor, skipped: Sequence[str],
                 scrub: Scrubber, stream: TextIO) -> None:
        self.repo = repo
        self.executor = executor
        self.skipped = set(skipped)
        self.scrub = scrub
        self.stream = stream
        self.rows: List[TestRow] = []
        self._programs: Dict[str, Program] = {}
        self._prep_problem: Optional[str] = None

    def run(self) -> List[CheckResult]:
        results = []
        for spec in CHECKS:
            result = self._check(spec)
            if spec.name == RLS and result.verdict is not None:
                self.rows += sql_rows(self.repo, result.verdict, self.scrub)
            if (spec.prep and result.verdict not in (PASS, None)
                    and self._prep_problem is None):
                self._prep_problem = _prep_problem(spec.name, result)
            if result.verdict is None:
                line = f'{spec.name}: пропущена (--skip)'
            else:
                line = f'{spec.name}: {result.verdict}'
                if result.reason and result.verdict != PASS:
                    line += f' — {result.reason}'
            print(line, file=self.stream, flush=True)
            results.append(result)
        return results

    def _check(self, spec: CheckSpec) -> CheckResult:
        if spec.name in self.skipped:
            return CheckResult(spec.name, spec.command, None, reason=SKIP_REASON)
        try:
            if spec.flutter:
                return self._flutter(spec)
            if spec.name == RLS:
                return self._rls(spec)
            return self._by_exit_code(spec, [self.executor.python()] + list(spec.args))
        except _Blocked as blocked:
            return CheckResult(spec.name, spec.command, BLOCKED, reason=blocked.reason)

    def _program(self, name: str) -> Program:
        if name not in self._programs:
            self._programs[name] = find_program(self.executor, self.repo.root, name)
        return self._programs[name]

    def _execute(self, spec: CheckSpec, argv: Sequence[str],
                 separate_stderr: bool = False) -> CommandResult:
        print(f'{spec.name}: {spec.command} …', file=self.stream, flush=True)
        try:
            return self.executor.execute(argv, self.repo.root, separate_stderr)
        except OSError as error:
            raise _Blocked(self.scrub.text(
                f'не запускается {argv[0]}: {error.strerror or error}')) from error

    def _flutter(self, spec: CheckSpec) -> CheckResult:
        program = self._program(spec.program)
        if program.path is None:
            raise _Blocked(program.reason or f'нет {spec.program}')
        if self._prep_problem:
            raise _Blocked(self._prep_problem)
        argv = [program.path] + list(spec.args)
        if spec.name == FORMAT:
            try:
                files = format_files(self.repo.root)
            except gitbase.GitError as error:
                raise _Blocked(f'git не дал список файлов: {error}') from error
            if not files:
                return CheckResult(spec.name, spec.command, PASS,
                                   reason='нет файлов .dart — проверять нечего')
            argv += files
        if spec.name == FLUTTER_TEST:
            return self._flutter_test(spec, argv)
        return self._by_exit_code(spec, argv)

    def _by_exit_code(self, spec: CheckSpec, argv: Sequence[str]) -> CheckResult:
        outcome = self._execute(spec, argv)
        if outcome.exit_code == 0:
            return CheckResult(spec.name, spec.command, PASS, 0)
        if spec.prep:
            verdict = BLOCKED
            reason = (f'подготовка не прошла (код {outcome.exit_code}): '
                      'проверки Flutter заблокированы')
        else:
            verdict, reason = FAIL, f'код {outcome.exit_code}'
        return CheckResult(spec.name, spec.command, verdict, outcome.exit_code, reason,
                           output_tail(outcome.stdout + '\n' + outcome.stderr, self.scrub))

    def _flutter_test(self, spec: CheckSpec, argv: Sequence[str]) -> CheckResult:
        outcome = self._execute(spec, argv, separate_stderr=True)
        report = parse_flutter_events(outcome.stdout, self.scrub)
        self.rows += flutter_rows(report)
        failed = [test for test in report.tests if test.verdict == FAIL]
        if failed:
            reason = f'упало тестов: {len(failed)}'
        elif outcome.exit_code != 0:
            reason = f'код {outcome.exit_code}, упавших тестов нет'
        else:
            return CheckResult(spec.name, spec.command, PASS, 0)
        text = '\n'.join(_failure_lines(failed) + report.other + [outcome.stderr])
        return CheckResult(spec.name, spec.command, FAIL, outcome.exit_code, reason,
                           output_tail(text, self.scrub))

    def _rls(self, spec: CheckSpec) -> CheckResult:
        if find_postgres(self.executor) is None:
            raise _Blocked(NO_POSTGRES)
        outcome = self._execute(spec, [BASH] + list(spec.args))
        output = outcome.stdout + '\n' + outcome.stderr
        if outcome.exit_code == 0 and any(line.strip() == RLS_OK
                                          for line in output.split('\n')):
            return CheckResult(spec.name, spec.command, PASS, 0)
        reason = (f'код {outcome.exit_code}' if outcome.exit_code != 0
                  else f'код 0, но в выводе нет строки {RLS_OK}')
        return CheckResult(spec.name, spec.command, FAIL, outcome.exit_code, reason,
                           output_tail(output, self.scrub))


def _validate_skip(skip: Sequence[str]) -> List[str]:
    names: List[str] = []
    for name in skip:
        if name not in names:
            names.append(name)
    unknown = [name for name in names if name not in CHECK_NAMES]
    if unknown:
        raise model.Refusal(
            f'нет проверки {", ".join(unknown)}; в --skip — имена из списка: '
            f'{", ".join(CHECK_NAMES)}', code=USAGE_CODE)
    return names


def _head(root: str) -> Tuple[str, str]:
    try:
        return gitbase.head_commit(root), gitbase.short_hash(root)
    except gitbase.GitError as error:
        raise model.Refusal(f'run проверяет коммит, а в {root} нет git-репозитория '
                            f'с коммитами: {error}', code=USAGE_CODE) from error


def _dirty_paths(root: str) -> List[str]:
    try:
        return [path for _, path in gitbase.status_entries(root, model.CODE_DIRS)]
    except gitbase.GitError as error:
        raise model.Refusal(f'git не дал состояние рабочего дерева: {error}',
                            code=USAGE_CODE) from error


def _refuse_dirty(paths: Sequence[str]) -> model.Refusal:
    shown = ', '.join(paths[:5]) + (f' и ещё {len(paths) - 5}' if len(paths) > 5 else '')
    folders = ', '.join(f'{name}/' for name in model.CODE_DIRS)
    return model.Refusal(
        f'незакоммиченные изменения в {folders}: {shown} — run проверяет '
        'закоммиченное состояние; закоммитьте их или передайте --allow-dirty',
        code=DIRTY_CODE)


def summary_line(checks: Sequence[CheckResult], code: int) -> str:
    """Строка итога: `Итог: PASS 8, FAIL 0, BLOCKED 2, пропущено 0 — код 3`."""
    counts = collections.Counter(check.verdict for check in checks)
    return (f'Итог: PASS {counts[PASS]}, FAIL {counts[FAIL]}, '
            f'BLOCKED {counts[BLOCKED]}, пропущено {counts[None]} — код {code}')


def run_with(
    repo: model.Repo,
    executor: Executor,
    allow_dirty: bool = False,
    skip: Sequence[str] = (),
    stream: Optional[TextIO] = None,
) -> int:
    """`run` с явным исполнителем и потоком вывода (см. `run`)."""
    stream = stream or sys.stdout
    skipped = _validate_skip(skip)
    commit, commit_short = _head(repo.root)
    dirty = _dirty_paths(repo.root)
    if dirty and not allow_dirty:
        raise _refuse_dirty(dirty)
    started = executor.now()
    runner = _Runner(repo, executor, skipped, Scrubber(repo.root, executor.home()), stream)
    checks = runner.run()
    finished = executor.now()
    summary = build_summary(commit, commit_short, started, finished, bool(dirty),
                            checks, runner.rows)
    run_dir = write_run(repo.root, summary)
    code = exit_code(check.verdict for check in checks)
    print(f'прогон: {run_dir}/', file=stream)
    print(summary_line(checks, code), file=stream)
    return code


def run(repo: model.Repo, allow_dirty: bool = False, skip: Sequence[str] = ()) -> int:
    """Прогоняет проверки проекта по порядку README и пишет прогон в
    `sdlc/6-eval/auto/<ГГГГ-ММ-ДД>-<короткий хэш HEAD>/` (`summary.json`,
    `summary.md`).

    `skip` — имена проверок из `--skip`, уже разделённые по запятым.
    Возвращает код: 0 — всё `PASS`, 1 — есть `FAIL`, 3 — `FAIL` нет, но есть
    `BLOCKED`. Отказ — `model.Refusal`: грязное дерево без `allow_dirty` —
    код 1, неизвестное имя в `skip` — код 2. Производные файлы не
    пересобирает: после прогона CLI зовёт `views.write_all`.
    """
    return run_with(repo, EXECUTOR, allow_dirty=allow_dirty, skip=skip)
