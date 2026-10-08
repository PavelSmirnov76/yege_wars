"""Тесты CLI: разбор команд, `--root`, коды возврата, вызов модулей и
пересборка производных файлов после мутирующих команд.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import contextlib
import io
import os
import subprocess
import sys
from unittest import mock

import sdlc_tool
from sdlc_tool import model
from sdlc_tool.__main__ import build_parser, main
from sdlc_tool.tests.helpers import MOD_1, TreeTestCase, seed


class CliTest(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)
        self.tree.commit('мир')

    def call(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = main(list(argv))
        return code, out.getvalue(), err.getvalue()

    def test_check_codes(self):
        with mock.patch('sdlc_tool.views.render_all', return_value={}):
            code, out, _ = self.call('check', '--root', self.tree.root)
            self.assertEqual((code, out), (0, 'Итог: 0 ошибок, 0 предупреждений\n'))
            self.tree.write(MOD_1, self.tree.read(MOD_1) + '[x](nope.md)\n')
            code, out, _ = self.call('--root', self.tree.root, 'check', '--base', 'none')
        self.assertEqual(code, 1)
        self.assertIn('ОШИБКА sdlc/2-specs/modules/MOD-1-AUTH.md:4: цель ссылки не существует', out)

    def test_check_bad_base(self):
        code, _, err = self.call('check', '--root', self.tree.root, '--base', 'nope')
        self.assertEqual(code, 2)
        self.assertIn('ОТКАЗ: база nope недоступна', err)

    def test_next(self):
        code, out, _ = self.call('next', 'UC', '--root', self.tree.root)
        self.assertEqual((code, out), (0, 'UC-2\n'))
        code, out, _ = self.call('--root', self.tree.root, 'next', 'RESULT', 'TASK-1')
        self.assertEqual((code, out), (0, 'RESULT-TASK-1-02\n'))
        code, out, err = self.call('next', 'ACC', 'RESULT-TASK-1-01', '--root', self.tree.root)
        self.assertEqual((code, out), (2, ''))
        self.assertIn('ОТКАЗ: у сдачи RESULT-TASK-1-01 уже есть приёмка', err)

    def test_usage_errors(self):
        for argv in ([], ['nope'], ['next'], ['entomb', 'UC-1'],
                     ['entomb', 'UC-1', '--by', 'none', '--date', '2026-13-01'],
                     ['snapshot-prd', '--why', 'x']):
            with self.subTest(argv=argv):
                with contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as caught:
                        main(argv)
                self.assertEqual(caught.exception.code, 2)

    def test_missing_root(self):
        code, _, err = self.call('check', '--root', self.tree.abs('nope'))
        self.assertEqual(code, 2)
        self.assertIn('нет папки', err)

    def test_views(self):
        with mock.patch('sdlc_tool.views.write_all', return_value=['sdlc/4-tasks/INDEX.md']) as write:
            code, out, _ = self.call('views', '--root', self.tree.root)
        self.assertEqual((code, out), (0, 'обновлено: sdlc/4-tasks/INDEX.md\n'))
        self.assertIsInstance(write.call_args[0][0], model.Repo)
        self.assertEqual(write.call_args[0][0].root, self.tree.root)

    def test_entomb_dispatch(self):
        with mock.patch('sdlc_tool.tomb.entomb', return_value=['a.md']) as entomb, \
                mock.patch('sdlc_tool.views.write_all', return_value=['b.md']) as write:
            code, out, _ = self.call('entomb', 'UC-1', '--by', 'none', '--why', 'снято',
                                     '--date', '2026-11-02', '--root', self.tree.root)
        self.assertEqual((code, out), (0, 'обновлено: a.md\nобновлено: b.md\n'))
        repo, target, by, why, date = entomb.call_args[0]
        self.assertIsInstance(repo, model.Repo)
        self.assertEqual((target, by, why, date), ('UC-1', None, 'снято', '2026-11-02'))
        write.assert_called_once()
        with mock.patch('sdlc_tool.tomb.entomb', return_value=[]) as entomb, \
                mock.patch('sdlc_tool.views.write_all', return_value=[]):
            self.call('entomb', 'R1', '--by', 'R2', '--root', self.tree.root)
        _, target, by, why, date = entomb.call_args[0]
        self.assertEqual((target, by, why), ('R1', 'R2', None))
        self.assertTrue(model.valid_date(date))

    def test_entomb_refusal_skips_views(self):
        refusal = model.Refusal('артефакта UC-9 нет')
        with mock.patch('sdlc_tool.tomb.entomb', side_effect=refusal), \
                mock.patch('sdlc_tool.views.write_all') as write:
            code, _, err = self.call('entomb', 'UC-9', '--by', 'none', '--root', self.tree.root)
        self.assertEqual(code, 1)
        self.assertIn('ОТКАЗ: артефакта UC-9 нет', err)
        write.assert_not_called()

    def test_snapshot_dispatch(self):
        path = 'sdlc/0-vibes/prd/history/PRD-2026-11-02.md'
        with mock.patch('sdlc_tool.tomb.snapshot_prd', return_value=path) as snapshot, \
                mock.patch('sdlc_tool.views.write_all', return_value=[]) as write:
            code, out, _ = self.call('snapshot-prd', '--why', 'новый вход', '--input',
                                     'sdlc/0-vibes/raw/2026-11-01/', '--date', '2026-11-02',
                                     '--root', self.tree.root)
        self.assertEqual((code, out), (0, f'снимок: {path}\n'))
        self.assertEqual(snapshot.call_args[0][1:],
                         ('новый вход', 'sdlc/0-vibes/raw/2026-11-01/', '2026-11-02'))
        write.assert_called_once()

    def test_run_dispatch(self):
        for result in (0, 1, 3):
            with mock.patch('sdlc_tool.run.run', return_value=result) as run, \
                    mock.patch('sdlc_tool.views.write_all', return_value=[]) as write:
                code, _, _ = self.call('run', '--allow-dirty', '--skip', 'rls, format,',
                                       '--root', self.tree.root)
            self.assertEqual(code, result)
            self.assertEqual(run.call_args[1], {'allow_dirty': True, 'skip': ['rls', 'format']})
            write.assert_called_once()
        with mock.patch('sdlc_tool.run.run', return_value=0) as run, \
                mock.patch('sdlc_tool.views.write_all', return_value=[]):
            self.call('run', '--root', self.tree.root)
        self.assertEqual(run.call_args[1], {'allow_dirty': False, 'skip': []})

    def test_stub_not_implemented(self):
        with mock.patch('sdlc_tool.views.write_all', side_effect=NotImplementedError('views')):
            code, _, err = self.call('views', '--root', self.tree.root)
        self.assertEqual(code, 1)
        self.assertIn('ещё не реализована', err)
        with mock.patch('sdlc_tool.tomb.entomb', return_value=[]), \
                mock.patch('sdlc_tool.views.write_all', side_effect=NotImplementedError):
            code, _, err = self.call('entomb', 'UC-1', '--by', 'none', '--root', self.tree.root)
        self.assertEqual(code, 0)
        self.assertIn('производные файлы не пересобраны', err)

    def test_parser_has_all_commands(self):
        parser = build_parser()
        for argv in (['check'], ['views'], ['next', 'UC'], ['entomb', 'UC-1', '--by', 'none'],
                     ['snapshot-prd', '--why', 'x', '--input', 'y'], ['run']):
            with self.subTest(argv=argv):
                self.assertTrue(callable(parser.parse_args(argv).handler))

    def test_module_entry_point(self):
        completed = subprocess.run(
            [sys.executable, '-m', 'sdlc_tool', 'next', 'MOD', '--root', self.tree.root],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            cwd=os.path.dirname(os.path.dirname(os.path.abspath(sdlc_tool.__file__))),
        )
        self.assertEqual(completed.returncode, 0, completed.stderr.decode('utf-8'))
        self.assertEqual(completed.stdout.decode('utf-8'), 'MOD-2\n')
