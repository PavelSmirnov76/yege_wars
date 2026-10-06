#!/usr/bin/env python3
"""Юнит-тесты переноса задач проекта в базу (tools/import_repo_tasks.py).

База и локальные эталоны не нужны: задача и её решение собираются во
временном каталоге.

    python3 -m unittest discover -s tools/tests -t .
"""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import import_repo_tasks  # noqa: E402

SLUG = 'e24-sample'
ANSWER = '42'

TASK_YAML = '''slug: e24-sample
title: "Задание 24. Пример"
ege_number: 24
difficulty: 2
answer_format: single
tags:
  - обработка строк
{themes}source: "Тестовая задача"
'''


class CollectTaskThemesTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name)
        self.task_dir = root / 'tasks' / '24' / SLUG
        self.task_dir.mkdir(parents=True)
        (self.task_dir / 'statement.md').write_text(
            'Найдите ответ.', encoding='utf-8'
        )
        (self.task_dir / '24.txt').write_text('ABC', encoding='utf-8')

        reference_dir = root / 'reference'
        (reference_dir / SLUG).mkdir(parents=True)
        (reference_dir / SLUG / 'solution.py').write_text(
            f'print({ANSWER})\n', encoding='utf-8'
        )
        patcher = mock.patch.object(
            import_repo_tasks, 'REFERENCE_DIR', reference_dir
        )
        patcher.start()
        self.addCleanup(patcher.stop)

    def tearDown(self):
        self._tmp.cleanup()

    def _write_yaml(self, themes_block):
        (self.task_dir / 'task.yaml').write_text(
            TASK_YAML.format(themes=themes_block), encoding='utf-8'
        )

    def _collect(self):
        return import_repo_tasks.collect_task(self.task_dir, {SLUG: ANSWER})

    def test_themes_go_to_payload_in_order(self):
        self._write_yaml('themes:\n  - "3.9"\n  - 3.10\n')
        payload = self._collect()['payload']
        # Первая тема — основная; 3.10 без кавычек не превращается в 3.1.
        self.assertEqual(payload['themes'], ['3.9', '3.10'])

    def test_missing_themes_is_preparation_error(self):
        self._write_yaml('')
        with self.assertRaises(import_repo_tasks.ImportError_) as caught:
            self._collect()
        self.assertIn('нет тем (themes)', str(caught.exception))
        self.assertIn(SLUG, str(caught.exception))

    def test_empty_themes_list_is_preparation_error(self):
        self._write_yaml('themes:\n')
        with self.assertRaises(import_repo_tasks.ImportError_) as caught:
            self._collect()
        self.assertIn('нет тем (themes)', str(caught.exception))


if __name__ == '__main__':
    unittest.main()
