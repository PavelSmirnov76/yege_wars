"""Тесты `run`: события `flutter test --reporter json`, метки путей из имён
тестов и из комментариев SQL, поиск Flutter и PostgreSQL, `BLOCKED`,
`--skip`, грязное дерево, имя папки прогона, состав `summary.json` и
`summary.md`, маскировка секретов, коды возврата, пересборка производных
файлов после прогона.

Внешние команды не запускаются: исполнитель подменён (`FakeExecutor`).

    python3 -m unittest sdlc_tool.tests.test_run
"""

from __future__ import annotations

import contextlib
import datetime
import io
import json
import os
import shutil
import tempfile
import unittest
from typing import Any, Callable, Dict, List, Optional, Sequence, Tuple, Union
from unittest import mock

from sdlc_tool import model
from sdlc_tool import run as runner
from sdlc_tool.__main__ import main
from sdlc_tool.tests.helpers import TreeTestCase, seed

# Начало прогона: 2026-11-02 01:30 по Москве — в UTC ещё 1 ноября.
NOW = datetime.datetime(2026, 11, 2, 1, 30,
                        tzinfo=datetime.timezone(datetime.timedelta(hours=3)))
VERSION = '3.41.0'
SQL = 'supabase/tests/rls_tests.sql'
WIDGET_TEST = 'test/login_test.dart'
PG_CTL = '/usr/local/bin/pg_ctl'
JWT = ('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
       'eyJyb2xlIjoic2VydmljZV9yb2xlIn0.c2lnbmF0dXJl')
SECRET_KEY = 'sb_secret_AbC123_xyz-9'
DB_URL = 'postgresql://postgres:hunter2@db.example.supabase.co:5432/postgres'


# --------------------------------------------------------------------------
# События flutter test --reporter json


def event(kind: str, **fields: Any) -> str:
    return json.dumps(dict(fields, type=kind), ensure_ascii=False)


def suite(suite_id: int, path: str) -> str:
    return event('suite', suite={'id': suite_id, 'platform': 'vm', 'path': path})


def group(group_id: int, suite_id: int, name: str, parent: Optional[int] = None) -> str:
    return event('group', group={'id': group_id, 'suiteID': suite_id, 'parentID': parent,
                                 'name': name, 'metadata': {'skip': False}, 'testCount': 1})


def start(test_id: int, suite_id: int, name: str, groups: Sequence[int] = (),
          **extra: Any) -> str:
    test = {'id': test_id, 'name': name, 'suiteID': suite_id, 'groupIDs': list(groups),
            'metadata': {'skip': False, 'skipReason': None}}
    test.update(extra)
    return event('testStart', test=test)


def done(test_id: int, result: str = 'success', skipped: bool = False,
         hidden: bool = False) -> str:
    return event('testDone', testID=test_id, result=result, skipped=skipped, hidden=hidden)


def error(test_id: int, text: str, stack: str = '') -> str:
    return event('error', testID=test_id, error=text, stackTrace=stack, isFailure=True)


def stream(*lines: str) -> str:
    return '\n'.join(lines) + '\n'


def passing_events(root: str) -> str:
    """Один набор: скрытая загрузка, тест с меткой пути и тест без метки."""
    return stream(
        event('start', protocolVersion='0.1.1'),
        suite(0, f'{root}/{WIDGET_TEST}'),
        start(1, 0, f'loading {root}/{WIDGET_TEST}'),
        done(1, hidden=True),
        group(2, 0, ''),
        start(3, 0, 'UC-1-P-01: вход с верным паролем', groups=[2]),
        done(3),
        start(4, 0, 'кнопка входа видна', groups=[2]),
        done(4),
        event('done', success=True),
    )


# --------------------------------------------------------------------------
# Исполнитель без внешнего мира


Response = Union[runner.CommandResult, BaseException,
                 Callable[[Sequence[str], str], runner.CommandResult]]

_MARKERS: Tuple[Tuple[str, Tuple[str, ...]], ...] = (
    ('pub_get', ('pub', 'get')),
    ('gen_l10n', ('gen-l10n',)),
    ('build_runner', ('run', 'build_runner')),
    ('analyze', ('analyze',)),
    ('custom_lint', ('run', 'custom_lint')),
    ('format', ('format',)),
    ('flutter_test', ('test', '--reporter', 'json')),
    ('rls', (runner.RLS_SCRIPT,)),
    ('tools_tests', ('-m', 'unittest', 'discover', '-s', 'tools/tests')),
    ('sdlc_tool_tests', ('-m', 'unittest', 'discover', '-s', 'sdlc_tool/tests')),
)


def check_of(argv: Sequence[str]) -> str:
    tail = tuple(argv[1:])
    for name, marker in _MARKERS:
        if tail[:len(marker)] == marker:
            return name
    raise AssertionError(f'неизвестная команда: {argv}')


def _default(name: str, cwd: str) -> runner.CommandResult:
    if name == 'flutter_test':
        return runner.CommandResult(0, passing_events(cwd))
    if name == 'rls':
        return runner.CommandResult(0, 'Применяю миграцию 0001…\nRLS OK\n')
    return runner.CommandResult(0, '')


class FakeExecutor(runner.Executor):
    """Программы, переменные окружения и ответы команд задаёт тест; вызовы
    пишутся в `calls` как (проверка, argv, cwd, stderr отдельно)."""

    def __init__(
        self,
        home: str,
        programs: Sequence[str] = (),
        path: Optional[Dict[str, str]] = None,
        environ: Optional[Dict[str, str]] = None,
        responses: Optional[Dict[str, Response]] = None,
    ) -> None:
        self.home_dir = home
        self.programs = set(programs)
        self.path = dict(path or {})
        self.environ = dict(environ or {})
        self.responses = dict(responses or {})
        self.calls: List[Tuple[str, List[str], str, bool]] = []
        self.moments = [NOW, NOW + datetime.timedelta(minutes=5)]

    def execute(self, argv: Sequence[str], cwd: str,
                separate_stderr: bool = False) -> runner.CommandResult:
        name = check_of(argv)
        self.calls.append((name, list(argv), cwd, separate_stderr))
        response = self.responses.get(name)
        if response is None:
            return _default(name, cwd)
        if isinstance(response, BaseException):
            raise response
        if callable(response):
            return response(argv, cwd)
        return response

    def getenv(self, name: str) -> Optional[str]:
        return self.environ.get(name)

    def home(self) -> str:
        return self.home_dir

    def is_executable(self, path: str) -> bool:
        return path in self.programs

    def which(self, name: str) -> Optional[str]:
        return self.path.get(name)

    def python(self) -> str:
        return 'python3'

    def now(self) -> datetime.datetime:
        return self.moments.pop(0) if len(self.moments) > 1 else self.moments[0]

    def ran(self) -> List[str]:
        return [call[0] for call in self.calls]

    def argv(self, name: str) -> List[str]:
        found = [call[1] for call in self.calls if call[0] == name]
        assert len(found) == 1, (name, self.calls)
        return found[0]


# --------------------------------------------------------------------------
# Разбор событий и метки путей


class FlutterEventsTest(unittest.TestCase):
    root = '/work/repo'

    def setUp(self) -> None:
        self.scrub = runner.Scrubber(self.root, '/home/user')

    def parse(self, text: str) -> runner.FlutterReport:
        return runner.parse_flutter_events(text, self.scrub)

    def test_real_shape(self) -> None:
        # Форма событий снята с flutter 3.41.0 (test runner 1.28.0).
        broken = f'{self.root}/test/broken_test.dart'
        probe = f'{self.root}/test/probe_test.dart'
        report = self.parse(stream(
            event('start', protocolVersion='0.1.1', runnerVersion='1.28.0'),
            suite(0, broken),
            start(1, 0, f'loading {broken}'),
            suite(2, probe),
            start(3, 2, f'loading {probe}'),
            event('allSuites', count=2),
            error(1, f'Failed to load "{broken}":\nCompilation failed'),
            done(1, result='error'),
            error(1, 'Error: The Dart compiler exited unexpectedly.'),
            done(3, hidden=True),
            group(4, 2, ''),
            group(5, 2, 'UC-1-P-01 вход', parent=4),
            start(6, 2, 'UC-1-P-01 вход верный пароль', groups=[4, 5]),
            done(6),
            group(7, 2, 'UC-1-P-01 вход вложенная', parent=5),
            start(8, 2, 'UC-1-P-01 вход вложенная падает', groups=[4, 5, 7]),
            error(8, 'Expected: <2>\n  Actual: <1>\n', 'test/probe_test.dart 10:9  main'),
            done(8, result='failure'),
            start(9, 2, 'UC-2-P-03: пропущенный', groups=[4]),
            event('print', testID=9, messageType='skip', message='Skip: нет данных'),
            done(9, skipped=True),
            start(10, 2, 'без метки', groups=[4]),
            done(10),
            start(11, 2, 'ошибка', groups=[4]),
            error(11, 'Bad state: бум'),
            done(11, result='error'),
            event('done', success=False),
        ))
        rows = runner.flutter_rows(report)
        self.assertEqual([row.as_dict() for row in rows], [
            {'file': 'test/broken_test.dart', 'name': 'loading test/broken_test.dart',
             'label': None, 'verdict': 'FAIL'},
            {'file': 'test/probe_test.dart', 'name': 'UC-1-P-01 вход верный пароль',
             'label': 'UC-1-P-01', 'verdict': 'PASS'},
            {'file': 'test/probe_test.dart', 'name': 'UC-1-P-01 вход вложенная падает',
             'label': 'UC-1-P-01', 'verdict': 'FAIL'},
            {'file': 'test/probe_test.dart', 'name': 'без метки',
             'label': None, 'verdict': 'PASS'},
            {'file': 'test/probe_test.dart', 'name': 'ошибка',
             'label': None, 'verdict': 'FAIL'},
        ])
        loading = report.tests[0]
        self.assertEqual(len(loading.errors), 2)  # ошибка после testDone тоже собрана
        self.assertIn('Compilation failed', loading.errors[0])
        hidden = [test for test in report.tests if test.hidden]
        skipped = [test for test in report.tests if test.skipped]
        self.assertEqual([test.id for test in hidden], [3])
        self.assertEqual([test.id for test in skipped], [9])
        self.assertIsNone(hidden[0].verdict)
        self.assertIsNone(skipped[0].verdict)

    def test_group_name_completes_full_name(self) -> None:
        # Имя без префикса группы (иной вывод репортёра) дополняется ею.
        report = self.parse(stream(
            suite(0, f'{self.root}/test/a_test.dart'),
            group(1, 0, ''),
            group(2, 0, 'UC-3-P-02 неверный пароль', parent=1),
            start(3, 0, 'показывает ошибку', groups=[1, 2]),
            done(3),
            start(4, 0, 'UC-3-P-02 неверный пароль', groups=[1, 2]),
            done(4),
        ))
        self.assertEqual([test.name for test in report.tests],
                         ['UC-3-P-02 неверный пароль показывает ошибку',
                          'UC-3-P-02 неверный пароль'])
        self.assertEqual([row.label for row in runner.flutter_rows(report)],
                         ['UC-3-P-02', 'UC-3-P-02'])

    def test_unfinished_and_repeated_done(self) -> None:
        report = self.parse(stream(
            suite(0, f'{self.root}/test/a_test.dart'),
            start(1, 0, 'UC-1-P-01 оборвался'),
            start(2, 0, 'UC-1-P-02 упал после завершения'),
            done(2),
            error(2, 'This test failed after it had already completed.'),
            done(2, result='error'),
        ))
        self.assertEqual([(test.result, test.verdict) for test in report.tests],
                         [(None, 'FAIL'), ('error', 'FAIL')])

    def test_stack_trace_shortened(self) -> None:
        stack = '\n'.join(f'кадр {n}' for n in range(1, 31))
        report = self.parse(stream(
            suite(0, f'{self.root}/test/a_test.dart'),
            start(1, 0, 'падает'),
            error(1, 'Bad state: бум\nвторая строка', stack),
            error(1, '', ''),
            done(1, result='error'),
        ))
        self.assertEqual(report.tests[0].errors, [
            '\n'.join(['Bad state: бум', 'вторая строка']
                      + [f'кадр {n}' for n in range(1, 11)])])

    def test_other_lines_and_garbage(self) -> None:
        report = self.parse(stream(
            'Resolving dependencies...',
            '{не json',
            '{"no_type": 1}',
            event('testDone', testID=99, result='success', hidden=False),
            start(1, 7, 'UC-1-P-01 вне набора',
                  root_url=f'file://{self.root}/test/b%20c_test.dart'),
            done(1),
        ))
        self.assertEqual(report.other, ['Resolving dependencies...', '{не json',
                                        '{"no_type": 1}'])
        self.assertEqual([(test.file, test.verdict) for test in report.tests],
                         [('test/b c_test.dart', 'PASS')])

    def test_rows_per_label(self) -> None:
        report = self.parse(stream(
            suite(0, f'{self.root}/test/a_test.dart'),
            start(1, 0, 'UC-1-P-01 и UC-1-P-02: UC-1-P-01 снова, UC-1, TOKEN-1'),
            done(1, result='failure'),
        ))
        self.assertEqual([(row.label, row.verdict) for row in runner.flutter_rows(report)],
                         [('UC-1-P-01', 'FAIL'), ('UC-1-P-02', 'FAIL')])


class LabelsTest(unittest.TestCase):
    def test_path_labels_from_names(self) -> None:
        self.assertEqual(runner.path_labels('UC-3-P-02: вход'), ['UC-3-P-02'])
        self.assertEqual(runner.path_labels('UC-3, TOKEN-1, COMP-2 — не пути'), [])
        self.assertEqual(runner.path_labels('xUC-3-P-02 UC-3-P-02x UC-3-P-02-1'), [])
        self.assertEqual(runner.path_labels('(UC-3-P-02) [UC-10-P-1]'),
                         ['UC-3-P-02', 'UC-10-P-1'])

    def test_label_order(self) -> None:
        labels = ['UC-10-P-01', 'UC-2-P-10', 'UC-2-P-02', 'UC-02-P-x', 'UC-2-P-01']
        self.assertEqual(sorted(labels, key=runner.label_key),
                         ['UC-2-P-01', 'UC-2-P-02', 'UC-2-P-10', 'UC-10-P-01', 'UC-02-P-x'])


class SqlCommentsTest(unittest.TestCase):
    TEXT = '\n'.join([
        '-- Тесты RLS',                                                # 1
        '-- UC-1-P-01 вход: чужие попытки не видны',                    # 2
        'do $$',                                                        # 3
        'begin',                                                        # 4
        '  -- UC-1-P-02 внутри тела DO',                                # 5
        "  raise notice 'OK: UC-9-P-09 в строке'; -- хвост без метки",  # 6
        '  perform 1; /* UC-1-P-03',                                    # 7
        '     вторая строка UC-2-P-01 /* вложенный */ ещё */',          # 8
        'end',                                                          # 9
        '$$;',                                                          # 10
        "select 'строка -- UC-7-P-07 не комментарий', 'a''b -- UC-7-P-08';",  # 11
        "select E'экранированная \\' кавычка -- UC-8-P-08'; -- UC-3-P-01",    # 12
        'select "имя -- UC-6-P-06" from t where x = $1; -- UC-3-P-02',  # 13
        'create function f() returns int as $fn$',                     # 14
        '  select 1 -- UC-4-P-01 в теле с тегом',                       # 15
        '$fn$ language sql;',                                           # 16
    ]) + '\n'

    def test_comments_with_lines(self) -> None:
        found = [(line, runner.path_labels(text))
                 for line, text in runner.sql_comments(self.TEXT)]
        self.assertEqual([item for item in found if item[1]], [
            (2, ['UC-1-P-01']),
            (5, ['UC-1-P-02']),
            (7, ['UC-1-P-03']),
            (8, ['UC-2-P-01']),
            (12, ['UC-3-P-01']),
            (13, ['UC-3-P-02']),
            (15, ['UC-4-P-01']),
        ])
        self.assertIn((6, ' хвост без метки'), runner.sql_comments(self.TEXT))

    def test_unclosed_constructs_do_not_hang(self) -> None:
        for text in ("select 'нет конца -- UC-1-P-01", 'select $$ -- UC-1-P-01',
                     '/* UC-1-P-01', "select E'\\", 'select "x'):
            with self.subTest(text=text):
                runner.sql_comments(text)
        self.assertEqual(runner.sql_comments('select $$ -- UC-1-P-01'), [(1, ' UC-1-P-01')])


class MaskTest(unittest.TestCase):
    def test_secrets_masked(self) -> None:
        cases = {
            f'SEED_DATABASE_URL={DB_URL} ок': 'SEED_DATABASE_URL=*** ок',
            'psql postgres://u:p@localhost/db': 'psql ***',
            'url=postgresql+psycopg://u@h/db; ок': 'url=*** ок',
            'jdbc:postgresql://h:5432/db?password=x': '***',
            'https://user:pa55@example.com/x': '***',
            'conn host=db.x port=5432 user=postgres password=s3cr3t dbname=postgres end':
                'conn *** end',
            'PGPASSWORD=s3cr3t psql': 'PGPASSWORD=*** psql',
            'export SUPABASE_DB_PASSWORD="s3 cr3t"': 'export SUPABASE_DB_PASSWORD=***',
            f'ключ {SECRET_KEY}.': 'ключ ***.',
            f'Authorization: Bearer {JWT}': 'Authorization: Bearer ***',
        }
        for text, expected in cases.items():
            with self.subTest(text=text):
                self.assertEqual(runner.mask_secrets(text), expected)

    def test_plain_text_kept(self) -> None:
        for text in ('https://example.com:8080/path', 'sb_publishable_abc', 'eyJ без точек',
                     'host=localhost', 'Применяю миграцию 0001…', 'a.b.c'):
            with self.subTest(text=text):
                self.assertEqual(runner.mask_secrets(text), text)

    def test_scrubber_paths(self) -> None:
        scrub = runner.Scrubber('/home/user/repo', '/home/user')
        self.assertEqual(scrub.path('/home/user/repo/test/a_test.dart'), 'test/a_test.dart')
        self.assertEqual(scrub.path('/home/user/repo'), '.')
        self.assertEqual(scrub.path('/elsewhere/a.dart'), '/elsewhere/a.dart')
        self.assertEqual(
            scrub.text('cd /home/user/repo; /home/user/repo/lib/a.dart; '
                       '/home/user/fvm/bin/dart; /home/user/repo2; /home/user'),
            'cd .; lib/a.dart; ~/fvm/bin/dart; ~/repo2; ~')

    def test_output_tail(self) -> None:
        scrub = runner.Scrubber('/r', '/home/u')
        text = '\n'.join(f'строка {n}' for n in range(1, 101)) + '\n\n\n'
        tail = runner.output_tail(text, scrub)
        assert tail is not None
        self.assertEqual(tail.split('\n'), [f'строка {n}' for n in range(41, 101)])
        self.assertEqual(
            runner.output_tail('\n\n\x1b[31mкрасный\x1b[0m\r\n10%\r50%\r100%\r\n'
                               f'/r/lib/a.dart {SECRET_KEY}\n', scrub, limit=3),
            'красный\n100%\nlib/a.dart ***')
        self.assertIsNone(runner.output_tail(' \n\n', scrub))


# --------------------------------------------------------------------------
# Поиск программ, вердикты, папка прогона


class ProgramsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = tempfile.mkdtemp(prefix='sdlc_tool_run_')
        self.addCleanup(shutil.rmtree, self.root, True)
        with open(os.path.join(self.root, '.fvmrc'), 'w', encoding='utf-8') as handle:
            handle.write('{"flutter": "3.41.0"}\n')
        self.fvm = '/home/u/fvm/versions/3.41.0/bin/flutter'

    def find(self, **options: Any) -> runner.Program:
        return runner.find_program(FakeExecutor('/home/u', **options), self.root, 'flutter')

    def test_order(self) -> None:
        everything = dict(programs=['/opt/f/flutter', self.fvm],
                          path={'flutter': '/usr/bin/flutter'})
        self.assertEqual(self.find(environ={'SDLC_FLUTTER': '/opt/f/flutter'}, **everything),
                         runner.Program('/opt/f/flutter'))
        self.assertEqual(self.find(**everything), runner.Program(self.fvm))
        self.assertEqual(self.find(path={'flutter': '/usr/bin/flutter'}),
                         runner.Program('/usr/bin/flutter'))

    def test_bad_variable_does_not_fall_back(self) -> None:
        found = self.find(environ={'SDLC_FLUTTER': '/nope/flutter'}, programs=[self.fvm])
        self.assertIsNone(found.path)
        self.assertIn('SDLC_FLUTTER задана, но не ведёт к исполняемому файлу', found.reason)
        self.assertNotIn('/nope', found.reason)

    def test_missing(self) -> None:
        self.assertEqual(self.find().reason,
                         'нет flutter: задайте SDLC_FLUTTER, поставьте Flutter 3.41.0 в '
                         '~/fvm/versions/3.41.0/ (fvm install 3.41.0) или добавьте flutter '
                         'в PATH')
        os.remove(os.path.join(self.root, '.fvmrc'))
        self.assertEqual(runner.find_program(FakeExecutor('/home/u'), self.root, 'dart').reason,
                         'нет dart: задайте SDLC_DART или добавьте dart в PATH')

    def test_postgres(self) -> None:
        homebrew = '/opt/homebrew/opt/postgresql@17/bin/pg_ctl'
        self.assertEqual(runner.find_postgres(FakeExecutor('/h', path={'pg_ctl': PG_CTL})),
                         PG_CTL)
        self.assertEqual(runner.find_postgres(FakeExecutor('/h', programs=[homebrew])),
                         homebrew)
        self.assertIsNone(runner.find_postgres(FakeExecutor('/h')))


class VerdictsTest(unittest.TestCase):
    def test_exit_codes(self) -> None:
        self.assertEqual(runner.exit_code([]), 0)
        self.assertEqual(runner.exit_code(['PASS', None, 'PASS']), 0)
        self.assertEqual(runner.exit_code(['PASS', 'BLOCKED', None]), 3)
        self.assertEqual(runner.exit_code(['BLOCKED', 'FAIL', 'PASS']), 1)

    def test_paths_and_totals(self) -> None:
        rows = [
            runner.TestRow('t.dart', 'a', 'UC-2-P-01', 'PASS'),
            runner.TestRow('t.dart', 'b', 'UC-2-P-01', 'BLOCKED'),
            runner.TestRow('t.dart', 'c', 'UC-10-P-01', 'PASS'),
            runner.TestRow('t.dart', 'd', 'UC-1-P-01', 'BLOCKED'),
            runner.TestRow('t.dart', 'e', 'UC-1-P-01', 'FAIL'),
            runner.TestRow('t.dart', 'f', None, 'FAIL'),
        ]
        paths = runner.path_verdicts(rows)
        self.assertEqual(list(paths.items()), [
            ('UC-1-P-01', 'FAIL'), ('UC-2-P-01', 'BLOCKED'), ('UC-10-P-01', 'PASS')])
        self.assertEqual(runner.totals(rows), {'pass': 2, 'fail': 2, 'blocked': 2})


class RunDirNameTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = tempfile.mkdtemp(prefix='sdlc_tool_run_')
        self.addCleanup(shutil.rmtree, self.root, True)

    def make(self, *names: str) -> None:
        for name in names:
            os.makedirs(os.path.join(self.root, 'sdlc', '6-eval', 'auto', name))

    def name(self) -> str:
        return runner.run_dir_name(self.root, '2026-11-02', 'abc1234')

    def test_suffixes(self) -> None:
        self.assertEqual(self.name(), '2026-11-02-abc1234')
        self.make('2026-11-02-abc1234', '2026-11-01-abc1234', '2026-11-02-abc1234d',
                  '2026-11-02-fff0000-07', '2026-11-02-abc1234-1')
        self.assertEqual(self.name(), '2026-11-02-abc1234-02')
        self.make('2026-11-02-abc1234-02')
        self.assertEqual(self.name(), '2026-11-02-abc1234-03')
        self.make('2026-11-02-abc1234-09')
        self.assertEqual(self.name(), '2026-11-02-abc1234-10')


# --------------------------------------------------------------------------
# Прогон на дереве


SQL_TEXT = '\n'.join([
    '-- RLS-тесты',
    'do $$',
    'begin',
    '  -- UC-1-P-01 чужие попытки не видны',
    "  raise notice 'OK: чужие попытки не видны';",
    'end',
    '$$;',
    '',
])
CHECKS = list(runner.CHECK_NAMES)
FLUTTER_CHECKS = ['pub_get', 'gen_l10n', 'build_runner', 'analyze', 'custom_lint', 'format',
                  'flutter_test']


class RunTreeTest(TreeTestCase):
    def setUp(self) -> None:
        super().setUp()
        seed(self.tree)
        self.tree.write('.fvmrc', '{"flutter": "3.41.0"}\n')
        self.tree.write(SQL, SQL_TEXT)
        self.tree.write(WIDGET_TEST, 'void main() {}\n')
        self.tree.write('lib/app.g.dart', '// сгенерировано\n')
        self.tree.write('lib/l10n/gen/app_localizations.dart', '// сгенерировано\n')
        self.tree.write('lib/l10n/app_ru.arb', '{}\n')
        self.commit('мир и тесты')
        self.home = os.path.join(os.path.dirname(self.tree.root), 'home')
        self.flutter = f'{self.home}/fvm/versions/{VERSION}/bin/flutter'
        self.dart = f'{self.home}/fvm/versions/{VERSION}/bin/dart'

    def commit(self, message: str) -> None:
        self.tree.commit(message)
        self.short = self.tree.git('rev-parse', '--short', 'HEAD').strip()

    def fake(self, **options: Any) -> FakeExecutor:
        options.setdefault('programs', [self.flutter, self.dart])
        options.setdefault('path', {'pg_ctl': PG_CTL})
        return FakeExecutor(self.home, **options)

    def run_tree(self, fake: FakeExecutor, **options: Any) -> Tuple[int, str]:
        out = io.StringIO()
        code = runner.run_with(self.tree.repo(), fake, stream=out, **options)
        return code, out.getvalue()

    def run_dir(self, suffix: str = '') -> str:
        return f'sdlc/6-eval/auto/2026-11-02-{self.short}{suffix}'

    def summary(self, suffix: str = '') -> Dict[str, Any]:
        return json.loads(self.tree.read(f'{self.run_dir(suffix)}/summary.json'))

    def markdown(self, suffix: str = '') -> str:
        return self.tree.read(f'{self.run_dir(suffix)}/summary.md')

    def checks(self, summary: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
        return {check['name']: check for check in summary['checks']}

    def verdicts(self, summary: Dict[str, Any]) -> Dict[str, Optional[str]]:
        return {check['name']: check['verdict'] for check in summary['checks']}

    def auto_dirs(self) -> List[str]:
        auto = self.tree.abs('sdlc/6-eval/auto')
        return sorted(name for name in os.listdir(auto)
                      if os.path.isdir(os.path.join(auto, name)))

    # -- всё прошло ---------------------------------------------------------

    def test_all_pass_summary_json(self) -> None:
        fake = self.fake()
        code, out = self.run_tree(fake)
        self.assertEqual(code, 0, out)
        summary = self.summary()
        self.assertEqual(list(summary), ['commit', 'commit_short', 'date', 'started_at',
                                         'finished_at', 'dirty', 'checks', 'tests', 'paths',
                                         'totals'])
        self.assertEqual(summary['commit'], self.tree.git('rev-parse', 'HEAD').strip())
        self.assertEqual(summary['commit_short'], self.short)
        self.assertEqual(summary['date'], '2026-11-02')  # по местному времени
        self.assertEqual(summary['started_at'], '2026-11-01T22:30:00+00:00')
        self.assertEqual(summary['finished_at'], '2026-11-01T22:35:00+00:00')
        self.assertIs(summary['dirty'], False)
        self.assertEqual([check['name'] for check in summary['checks']], CHECKS)
        for check in summary['checks']:
            self.assertEqual(list(check), ['name', 'command', 'verdict', 'exit_code',
                                           'reason', 'output_tail'])
            self.assertEqual((check['verdict'], check['exit_code'], check['reason'],
                              check['output_tail']), ('PASS', 0, None, None), check['name'])
        self.assertEqual(self.checks(summary)['format']['command'],
                         'dart format --output=none --set-exit-if-changed '
                         '<.dart из lib/ и test/ без *.g.dart и lib/l10n/gen/>')
        self.assertEqual(summary['tests'], [
            {'file': SQL, 'name': 'UC-1-P-01 чужие попытки не видны', 'label': 'UC-1-P-01',
             'verdict': 'PASS'},
            {'file': WIDGET_TEST, 'name': 'UC-1-P-01: вход с верным паролем',
             'label': 'UC-1-P-01', 'verdict': 'PASS'},
            {'file': WIDGET_TEST, 'name': 'кнопка входа видна', 'label': None,
             'verdict': 'PASS'},
        ])
        self.assertEqual(summary['paths'], {'UC-1-P-01': 'PASS'})
        self.assertEqual(summary['totals'], {'pass': 3, 'fail': 0, 'blocked': 0})
        self.assertEqual(self.auto_dirs(), [f'2026-11-02-{self.short}'])
        self.assertIn(f'прогон: {self.run_dir()}/\n', out)
        self.assertTrue(out.endswith('Итог: PASS 10, FAIL 0, BLOCKED 0, пропущено 0 — код 0\n'))

    def test_commands(self) -> None:
        fake = self.fake()
        self.run_tree(fake)
        self.assertEqual(fake.ran(), CHECKS)
        for name, argv, cwd, separate in fake.calls:
            self.assertEqual(cwd, self.tree.root)
            self.assertEqual(separate, name == 'flutter_test', name)
        self.assertEqual(fake.argv('pub_get'), [self.flutter, 'pub', 'get'])
        self.assertEqual(fake.argv('build_runner'),
                         [self.dart, 'run', 'build_runner', 'build',
                          '--delete-conflicting-outputs'])
        self.assertEqual(fake.argv('analyze'),
                         [self.flutter, 'analyze', '--fatal-infos', '--fatal-warnings'])
        self.assertEqual(fake.argv('flutter_test'), [self.flutter, 'test', '--reporter', 'json'])
        self.assertEqual(fake.argv('format'),
                         [self.dart, 'format', '--output=none', '--set-exit-if-changed',
                          'lib/main.dart', WIDGET_TEST])
        self.assertEqual(fake.argv('rls'), ['bash', 'supabase/tests/run_local.sh'])
        self.assertEqual(fake.argv('tools_tests'),
                         ['python3', '-m', 'unittest', 'discover', '-s', 'tools/tests', '-t', '.'])
        self.assertEqual(fake.argv('sdlc_tool_tests'),
                         ['python3', '-m', 'unittest', 'discover', '-s', 'sdlc_tool/tests',
                          '-t', '.'])

    def test_summary_markdown(self) -> None:
        self.run_tree(self.fake(responses={'analyze': runner.CommandResult(
            1, 'error • сломано • lib/main.dart:1:1 • x\n```\n1 issue found.\n')}))
        text = self.markdown()
        head = text.split('\n## Проверки')[0]
        self.assertEqual(head, '\n'.join([
            f'# Прогон 2026-11-02-{self.short}',
            '',
            f'- Коммит: `{self.tree.git("rev-parse", "HEAD").strip()}`',
            '- Дата: 2026-11-02; начат 2026-11-01T22:30:00+00:00, '
            'закончен 2026-11-01T22:35:00+00:00',
            '- Незакоммиченные изменения: нет',
            '- Итог: FAIL (код 1)',
            '- Тесты: PASS 3, FAIL 0, BLOCKED 0',
            '',
        ]))
        self.assertIn('| Проверка | Команда | Вердикт | Код | Причина |\n|---|---|---|---|---|\n'
                      '| pub_get | `flutter pub get` | PASS | 0 | — |\n', text)
        self.assertIn('| analyze | `flutter analyze --fatal-infos --fatal-warnings` | FAIL | 1 '
                      '| код 1 |\n', text)
        self.assertIn('## Пути UC\n\n| Путь UC | Тест | Вердикт |\n|---|---|---|\n'
                      f'| UC-1-P-01 | `{SQL}` — UC-1-P-01 чужие попытки не видны | PASS |\n'
                      f'| UC-1-P-01 | `{WIDGET_TEST}` — UC-1-P-01: вход с верным паролем '
                      '| PASS |\n', text)
        self.assertNotIn('кнопка входа видна', text)  # тест без метки — только в json
        self.assertTrue(text.endswith(
            '## Вывод упавших проверок\n\n### analyze\n\n````text\n'
            'error • сломано • lib/main.dart:1:1 • x\n```\n1 issue found.\n````\n'))

    def test_markdown_without_labels_and_tails(self) -> None:
        self.run_tree(self.fake(), skip=['rls', 'flutter_test'])
        text = self.markdown()
        self.assertIn('- Итог: PASS (код 0); пропущены: flutter_test, rls\n', text)
        self.assertIn('| rls | `bash supabase/tests/run_local.sh` | пропущена | — | '
                      'пропущена: --skip |\n', text)
        self.assertIn('## Пути UC\n\nТестов с меткой пути нет.\n', text)
        self.assertNotIn('## Вывод упавших проверок', text)

    def test_check_and_auto_runs_after_run(self) -> None:
        self.run_tree(self.fake())
        self.assertEqual(self.tree.errors(), [])
        runs = self.tree.repo().auto_runs()
        self.assertEqual([(item.name, item.error) for item in runs],
                         [(f'2026-11-02-{self.short}', None)])
        self.assertEqual(runs[0].summary['paths'], {'UC-1-P-01': 'PASS'})

    # -- FAIL и хвосты ------------------------------------------------------

    def test_fail_tail_masked(self) -> None:
        secret_output = '\n'.join(
            [f'строка {n}' for n in range(1, 80)]
            + [f'подключение {DB_URL}', f'ключ {SECRET_KEY}', f'токен {JWT}',
               f'{self.tree.root}/tools/tests/test_x.py: AssertionError', ''])
        code, out = self.run_tree(self.fake(responses={
            'tools_tests': runner.CommandResult(1, secret_output)}))
        self.assertEqual(code, 1)
        check = self.checks(self.summary())['tools_tests']
        self.assertEqual((check['verdict'], check['exit_code'], check['reason']),
                         ('FAIL', 1, 'код 1'))
        tail = check['output_tail'].split('\n')
        self.assertEqual(len(tail), 60)
        self.assertEqual(tail[0], 'строка 24')
        self.assertEqual(tail[-4:], ['подключение ***', 'ключ ***', 'токен ***',
                                     'tools/tests/test_x.py: AssertionError'])
        for path in ('summary.json', 'summary.md'):
            text = self.tree.read(f'{self.run_dir()}/{path}')
            for secret in ('hunter2', 'db.example.supabase.co', SECRET_KEY, JWT,
                           self.tree.root):
                self.assertNotIn(secret, text, path)
        self.assertIn('tools_tests: FAIL — код 1', out)

    def test_flutter_test_failure(self) -> None:
        def failing(argv: Sequence[str], cwd: str) -> runner.CommandResult:
            return runner.CommandResult(1, stream(
                suite(0, f'{cwd}/{WIDGET_TEST}'),
                start(1, 0, 'UC-1-P-01: вход с верным паролем'),
                error(1, f'Expected: true\n  Actual: false\n{SECRET_KEY}',
                      f'{cwd}/{WIDGET_TEST} 12:5  main.<fn>'),
                done(1, result='failure'),
                start(2, 0, 'без метки'),
                done(2),
            ), stderr='Some tests failed.\n')
        code, _ = self.run_tree(self.fake(responses={'flutter_test': failing}))
        self.assertEqual(code, 1)
        summary = self.summary()
        check = self.checks(summary)['flutter_test']
        self.assertEqual((check['verdict'], check['exit_code'], check['reason']),
                         ('FAIL', 1, 'упало тестов: 1'))
        self.assertEqual(check['output_tail'], '\n'.join([
            f'FAIL {WIDGET_TEST}: UC-1-P-01: вход с верным паролем',
            'Expected: true', '  Actual: false', '***',
            f'{WIDGET_TEST} 12:5  main.<fn>',
            'Some tests failed.',
        ]))
        self.assertEqual(summary['paths'], {'UC-1-P-01': 'FAIL'})  # SQL — PASS, тест — FAIL
        self.assertEqual(summary['totals'], {'pass': 2, 'fail': 1, 'blocked': 0})

    def test_flutter_test_exit_code_without_failed_tests(self) -> None:
        code, _ = self.run_tree(self.fake(responses={
            'flutter_test': runner.CommandResult(
                1, '', stderr='Test directory "test" not found.\n')}))
        self.assertEqual(code, 1)
        check = self.checks(self.summary())['flutter_test']
        self.assertEqual((check['verdict'], check['reason'], check['output_tail']),
                         ('FAIL', 'код 1, упавших тестов нет', 'Test directory "test" not found.'))

    def test_rls_needs_ok_line(self) -> None:
        code, _ = self.run_tree(self.fake(responses={
            'rls': runner.CommandResult(0, 'RLS TESTS PASSED\nRLS OK — почти\n')}))
        self.assertEqual(code, 1)
        summary = self.summary()
        self.assertEqual(self.checks(summary)['rls']['reason'],
                         'код 0, но в выводе нет строки RLS OK')
        self.assertEqual(summary['paths'], {'UC-1-P-01': 'FAIL'})

    # -- BLOCKED ------------------------------------------------------------

    def test_blocked_without_flutter(self) -> None:
        fake = self.fake(programs=[])
        code, out = self.run_tree(fake)
        self.assertEqual(code, 3)
        self.assertEqual(fake.ran(), ['rls', 'tools_tests', 'sdlc_tool_tests'])
        checks = self.checks(self.summary())
        for name in FLUTTER_CHECKS:
            program = 'dart' if name in ('build_runner', 'custom_lint', 'format') else 'flutter'
            variable = 'SDLC_DART' if program == 'dart' else 'SDLC_FLUTTER'
            self.assertEqual(checks[name]['verdict'], 'BLOCKED', name)
            self.assertIsNone(checks[name]['exit_code'])
            self.assertTrue(checks[name]['reason'].startswith(f'нет {program}: задайте {variable}, '
                                                              'поставьте Flutter 3.41.0'),
                            checks[name]['reason'])
        summary = self.summary()
        self.assertEqual([row['file'] for row in summary['tests']], [SQL])
        self.assertEqual(summary['paths'], {'UC-1-P-01': 'PASS'})
        self.assertIn('pub_get: BLOCKED — нет flutter: задайте SDLC_FLUTTER', out)
        self.assertTrue(out.endswith('Итог: PASS 3, FAIL 0, BLOCKED 7, пропущено 0 — код 3\n'))

    def test_sdlc_variables(self) -> None:
        fake = self.fake(programs=['/opt/flutter/bin/flutter', self.dart],
                         environ={'SDLC_FLUTTER': '/opt/flutter/bin/flutter'})
        self.assertEqual(self.run_tree(fake)[0], 0)
        self.assertEqual(fake.argv('analyze')[0], '/opt/flutter/bin/flutter')
        self.assertEqual(fake.argv('custom_lint')[0], self.dart)
        fake = self.fake(environ={'SDLC_DART': '/nope/dart'})
        self.assertEqual(self.run_tree(fake)[0], 3)
        checks = self.checks(self.summary('-02'))
        self.assertEqual(checks['pub_get']['verdict'], 'PASS')
        self.assertEqual(checks['gen_l10n']['verdict'], 'PASS')
        self.assertEqual(checks['build_runner']['reason'],
                         'SDLC_DART задана, но не ведёт к исполняемому файлу dart — '
                         'поправьте или уберите её')
        self.assertEqual(checks['analyze']['reason'],
                         'не прошла подготовка build_runner: SDLC_DART задана, но не ведёт '
                         'к исполняемому файлу dart — поправьте или уберите её')
        self.assertEqual(fake.ran(), ['pub_get', 'gen_l10n', 'rls', 'tools_tests',
                                      'sdlc_tool_tests'])

    def test_blocked_without_postgres(self) -> None:
        fake = self.fake(path={})
        code, _ = self.run_tree(fake)
        self.assertEqual(code, 3)
        self.assertNotIn('rls', fake.ran())
        summary = self.summary()
        rls = self.checks(summary)['rls']
        self.assertEqual((rls['verdict'], rls['exit_code'], rls['reason']),
                         ('BLOCKED', None, runner.NO_POSTGRES))
        self.assertEqual([(row['file'], row['verdict']) for row in summary['tests']
                          if row['label']], [(SQL, 'BLOCKED'), (WIDGET_TEST, 'PASS')])
        self.assertEqual(summary['paths'], {'UC-1-P-01': 'BLOCKED'})
        self.assertEqual(summary['totals'], {'pass': 2, 'fail': 0, 'blocked': 1})

    def test_blocked_after_failed_preparation(self) -> None:
        fake = self.fake(responses={'pub_get': runner.CommandResult(69, 'Нет сети.\n')})
        code, _ = self.run_tree(fake)
        self.assertEqual(code, 3)
        self.assertEqual(fake.ran(), ['pub_get', 'rls', 'tools_tests', 'sdlc_tool_tests'])
        checks = self.checks(self.summary())
        self.assertEqual(
            (checks['pub_get']['verdict'], checks['pub_get']['exit_code'],
             checks['pub_get']['reason'], checks['pub_get']['output_tail']),
            ('BLOCKED', 69, 'подготовка не прошла (код 69): проверки Flutter заблокированы',
             'Нет сети.'))
        for name in FLUTTER_CHECKS[1:]:
            self.assertEqual((checks[name]['verdict'], checks[name]['reason']),
                             ('BLOCKED', 'не прошла подготовка pub_get (код 69)'), name)

    def test_failed_build_runner_blocks_only_later_checks(self) -> None:
        fake = self.fake(responses={'build_runner': runner.CommandResult(1, 'ошибка\n')})
        self.assertEqual(self.run_tree(fake)[0], 3)
        verdicts = self.verdicts(self.summary())
        self.assertEqual([verdicts[name] for name in FLUTTER_CHECKS],
                         ['PASS', 'PASS'] + ['BLOCKED'] * 5)
        self.assertEqual(fake.ran(), ['pub_get', 'gen_l10n', 'build_runner', 'rls',
                                      'tools_tests', 'sdlc_tool_tests'])

    def test_program_does_not_start(self) -> None:
        fake = self.fake(responses={'rls': FileNotFoundError(2, 'No such file or directory')})
        self.assertEqual(self.run_tree(fake)[0], 3)
        rls = self.checks(self.summary())['rls']
        self.assertEqual((rls['verdict'], rls['reason']),
                         ('BLOCKED', 'не запускается bash: No such file or directory'))

    def test_fail_wins_over_blocked(self) -> None:
        fake = self.fake(path={}, responses={'analyze': runner.CommandResult(1, 'x')})
        self.assertEqual(self.run_tree(fake)[0], 1)

    # -- --skip -------------------------------------------------------------

    def test_skip(self) -> None:
        fake = self.fake()
        code, out = self.run_tree(fake, skip=['pub_get', 'rls', 'flutter_test', 'rls'])
        self.assertEqual(code, 0)
        self.assertEqual(fake.ran(), ['gen_l10n', 'build_runner', 'analyze', 'custom_lint',
                                      'format', 'tools_tests', 'sdlc_tool_tests'])
        summary = self.summary()
        for name in ('pub_get', 'rls', 'flutter_test'):
            check = self.checks(summary)[name]
            self.assertEqual((check['verdict'], check['exit_code'], check['reason']),
                             (None, None, 'пропущена: --skip'))
        self.assertEqual((summary['tests'], summary['paths']), ([], {}))
        self.assertEqual(summary['totals'], {'pass': 0, 'fail': 0, 'blocked': 0})
        self.assertIn('pub_get: пропущена (--skip)\n', out)
        self.assertTrue(out.endswith('Итог: PASS 7, FAIL 0, BLOCKED 0, пропущено 3 — код 0\n'))

    def test_skip_everything(self) -> None:
        fake = self.fake()
        self.assertEqual(self.run_tree(fake, skip=CHECKS)[0], 0)
        self.assertEqual(fake.ran(), [])
        self.assertEqual(set(self.verdicts(self.summary()).values()), {None})

    def test_unknown_skip_refused(self) -> None:
        fake = self.fake()
        with self.assertRaises(model.Refusal) as caught:
            self.run_tree(fake, skip=['rls', 'lint', 'tests'])
        self.assertEqual(caught.exception.code, 2)
        self.assertIn('нет проверки lint, tests', str(caught.exception))
        self.assertIn('pub_get, gen_l10n', str(caught.exception))
        self.assertEqual((fake.ran(), self.auto_dirs()), ([], []))

    # -- грязное дерево -----------------------------------------------------

    def test_dirty_tree_refused(self) -> None:
        for path, change in ((WIDGET_TEST, 'void main() { }\n'),
                             ('test/new_test.dart', 'void main() {}\n'),
                             ('supabase/migrations/0002_x.sql', 'select 1;\n'),
                             ('web/index.html', '<html></html>\n')):
            with self.subTest(path=path):
                self.tree.git('reset', '-q', '--hard')
                self.tree.git('clean', '-q', '-fd', '--', 'lib', 'test', 'web', 'supabase')
                self.tree.write(path, change)
                fake = self.fake()
                with self.assertRaises(model.Refusal) as caught:
                    self.run_tree(fake)
                self.assertEqual(caught.exception.code, 1)
                self.assertIn(f': {path} — run проверяет закоммиченное состояние',
                              str(caught.exception))
                self.assertIn('--allow-dirty', str(caught.exception))
                self.assertEqual((fake.ran(), self.auto_dirs()), ([], []))

    def test_dirty_list_shortened(self) -> None:
        for number in range(7):
            self.tree.write(f'lib/new_{number}.dart', '// новое\n')
        with self.assertRaises(model.Refusal) as caught:
            self.run_tree(self.fake())
        self.assertIn('lib/new_4.dart и ещё 2 — run', str(caught.exception))

    def test_changes_outside_code_are_not_dirty(self) -> None:
        self.tree.write('tools/new_tool.py', 'print()\n')
        self.tree.write('README.md', '# проект\n')
        self.tree.write('sdlc/0-vibes/raw/2026-11-03/notes.md', 'заметка\n')
        self.assertEqual(self.run_tree(self.fake())[0], 0)
        self.assertIs(self.summary()['dirty'], False)

    def test_allow_dirty(self) -> None:
        self.tree.write('test/new_test.dart', 'void main() {}\n')
        fake = self.fake()
        code, _ = self.run_tree(fake, allow_dirty=True)
        self.assertEqual(code, 0)
        self.assertIs(self.summary()['dirty'], True)
        self.assertIn('- Незакоммиченные изменения: есть (`--allow-dirty`)\n', self.markdown())
        self.assertIn('test/new_test.dart', fake.argv('format'))
        clean = self.fake()
        self.tree.remove('test/new_test.dart')
        self.run_tree(clean, allow_dirty=True)
        self.assertIs(self.summary('-02')['dirty'], False)

    def test_not_a_git_repository(self) -> None:
        root = tempfile.mkdtemp(prefix='sdlc_tool_run_')
        self.addCleanup(shutil.rmtree, root, True)
        os.makedirs(os.path.join(root, 'sdlc'))
        with self.assertRaises(model.Refusal) as caught:
            runner.run_with(model.load_repo(root), self.fake(), stream=io.StringIO())
        self.assertEqual(caught.exception.code, 2)

    # -- папка прогона ------------------------------------------------------

    def test_second_run_same_day_gets_suffix(self) -> None:
        for _ in range(3):
            self.run_tree(self.fake())
        self.assertEqual(self.auto_dirs(), [f'2026-11-02-{self.short}',
                                            f'2026-11-02-{self.short}-02',
                                            f'2026-11-02-{self.short}-03'])
        self.assertEqual(self.summary('-03')['date'], '2026-11-02')
        self.assertTrue(self.markdown('-02').startswith(f'# Прогон 2026-11-02-{self.short}-02\n'))
        self.commit('прогоны')
        later = self.fake()
        later.moments = [NOW + datetime.timedelta(days=1)]
        self.run_tree(later)
        self.assertIn(f'2026-11-03-{self.short}', self.auto_dirs())

    def test_format_files(self) -> None:
        self.tree.write('lib/notes.txt', 'не dart\n')
        self.tree.write('test/helpers/fake.dart', '// помощник\n')
        self.commit('ещё файлы')
        self.assertEqual(runner.format_files(self.tree.root),
                         ['lib/main.dart', 'test/helpers/fake.dart', WIDGET_TEST])

    def test_format_without_files(self) -> None:
        self.tree.git('rm', '-q', 'lib/main.dart', WIDGET_TEST)
        self.commit('без dart')
        fake = self.fake()
        self.assertEqual(self.run_tree(fake)[0], 0)
        self.assertNotIn('format', fake.ran())
        check = self.checks(self.summary())['format']
        self.assertEqual((check['verdict'], check['exit_code'], check['reason']),
                         ('PASS', None, 'нет файлов .dart — проверять нечего'))

    # -- CLI: пересборка производных файлов ---------------------------------

    def call(self, *argv: str) -> Tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = main(list(argv))
        return code, out.getvalue(), err.getvalue()

    def test_cli_rebuilds_views_after_run(self) -> None:
        seen: List[Tuple[bool, List[str]]] = []

        def write_all(repo: model.Repo) -> List[str]:
            seen.append((os.path.isfile(self.tree.abs(f'{self.run_dir()}/summary.json')),
                         [item.name for item in repo.auto_runs()]))
            return ['sdlc/6-eval/DASHBOARD.md']

        for responses, expected in (({}, 0),
                                    ({'analyze': runner.CommandResult(1, 'x')}, 1)):
            seen.clear()
            fake = self.fake(responses=responses)
            with mock.patch.object(runner, 'EXECUTOR', fake), \
                    mock.patch('sdlc_tool.views.write_all', side_effect=write_all):
                code, out, _ = self.call('run', '--root', self.tree.root, '--skip', 'rls,')
            self.assertEqual(code, expected)
            self.assertEqual(len(seen), 1)
            self.assertTrue(seen[0][0])
            self.assertIn(os.path.basename(self.run_dir() if expected == 0
                                           else self.run_dir('-02')), seen[0][1])
            self.assertNotIn('rls', fake.ran())
            self.assertTrue(out.endswith(
                f'— код {expected}\nобновлено: sdlc/6-eval/DASHBOARD.md\n'), out)

    def test_cli_refusal_skips_views(self) -> None:
        self.tree.write('lib/draft.dart', '// черновик\n')
        fake = self.fake()
        with mock.patch.object(runner, 'EXECUTOR', fake), \
                mock.patch('sdlc_tool.views.write_all') as write_all:
            code, _, err = self.call('run', '--root', self.tree.root)
            self.assertEqual(code, 1)
            self.assertIn('ОТКАЗ: незакоммиченные изменения', err)
            code, _, err = self.call('run', '--root', self.tree.root, '--allow-dirty',
                                     '--skip', 'nope')
            self.assertEqual(code, 2)
            self.assertIn('ОТКАЗ: нет проверки nope', err)
        write_all.assert_not_called()
        self.assertEqual(fake.ran(), [])


if __name__ == '__main__':
    unittest.main()
