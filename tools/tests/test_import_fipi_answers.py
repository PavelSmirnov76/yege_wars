#!/usr/bin/env python3
"""Юнит-тесты заливки ответов банка ФИПИ (tools/import_fipi_answers.py).

Сеть и база не нужны: выгрузка собирается во временном каталоге, Content API
подменяет заглушка, которая ведёт себя как функции базы.

    python3 -m unittest discover -s tools/tests -t .
"""

from __future__ import annotations

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import import_fipi_answers as importer  # noqa: E402
from content_client import ContentApiError  # noqa: E402

# Ответы и эталоны нарочно приметные: по ним проверяется, что в вывод
# скрипта они не попадают.
SECRET_ANSWER = 'SECRET-ANSWER-QWERTY'
SECRET_REFERENCE_MARK = 'SECRET_REFERENCE_MARK'


def _entry(short_id, answer, answer_format='string', verified=True):
    reference = f'{SECRET_REFERENCE_MARK} = 1\nprint({answer!r})\n'
    return {
        'short_id': short_id,
        'task_id': short_id * 4,
        'kim_number': 1,
        'answer': answer,
        'answer_format': answer_format,
        'reference_solution': reference,
        'answer_explanation': f'Разбор {short_id}',
        'verified': verified,
        'attempts': 1,
        'verify_code': 3 if verified else None,
    }


def _task(short_id, **extra):
    task = {
        'short_id': short_id,
        'id': short_id * 4,
        'assets': [],
        'parent_id': None,
        'condition_incomplete': False,
        'duplicate_of': None,
    }
    task.update(extra)
    return task


# Маленькая выгрузка: 6 подтверждённых, из них к публикации 2.
SOLUTIONS = [
    _entry('AA0001', SECRET_ANSWER),
    _entry('aB0002', '10 20 30', 'multi'),
    _entry('AA0003', '7', 'single'),
    _entry('AA0004', '8', 'single'),
    _entry('AA0005', 'xyz'),
    _entry('AA0006', 'w x'),
    _entry('AA0007', '1', 'single', verified=False),
]
TASKS = [
    _task('AA0001'),
    _task('aB0002'),
    _task('AA0003', assets=[{'local_path': 'assets/files/a.zip'}]),
    _task('AA0004', parent_id='PARENT'),
    _task('AA0005', condition_incomplete=True),
    _task('AA0006', duplicate_of='AA0005'),
    _task('AA0007'),
]
CONFIRMED = ['AA0001', 'aB0002', 'AA0003', 'AA0004', 'AA0005', 'AA0006']
PUBLISHABLE = ['AA0001', 'aB0002']


class StubClient:
    """Заглушка Content API: ведёт себя как функции базы."""

    def __init__(self, entries):
        self.calls = []
        self.tasks = {}
        self.fail_queue = []
        self.mismatch = set()
        for entry in entries:
            self.tasks[importer.task_slug(entry['short_id'])] = {
                'slug': importer.task_slug(entry['short_id']),
                'origin': 'fipi',
                'fipi_short_id': entry['short_id'],
                'status': 'draft',
                'answer': None,
                'answer_format': 'string',
                'reference_solution': None,
                'reference_verified_at': None,
                'files': [],
            }

    def _record(self, name, *args):
        self.calls.append((name,) + args)
        if self.fail_queue:
            raise self.fail_queue.pop(0)

    def get_task(self, slug):
        self._record('get_task', slug)
        return dict(self.tasks[slug])

    def set_answer(self, payload):
        self._record('set_answer', payload['slug'])
        task = self.tasks[payload['slug']]
        task.update(
            answer=payload['answer'],
            answer_format=payload['answer_format'],
            reference_solution=payload['reference_solution'],
            reference_verified_at=None,
        )
        if task['status'] == 'published':
            task['status'] = 'review'
        return {
            'slug': payload['slug'],
            'status': task['status'],
            'answer_format': payload['answer_format'],
        }

    def verify_reference(self, slug, output):
        self._record('verify_reference', slug)
        task = self.tasks[slug]
        matches = slug not in self.mismatch and importer.answers_match(
            output, task['answer'], task['answer_format']
        )
        task['reference_verified_at'] = '2026-10-07T00:00:00Z' if matches else None
        return {'slug': slug, 'matches': matches}

    def set_status(self, slug, status):
        self._record('set_status', slug, status)
        task = self.tasks[slug]
        if status == 'published' and task['reference_verified_at'] is None:
            raise ContentApiError('not_verified', 'Сначала проверьте эталон.')
        task['status'] = status
        return {'slug': slug, 'status': status}

    def names(self, name):
        return [call for call in self.calls if call[0] == name]


class FakeClock:
    """Часы, которые идут только во время sleep."""

    def __init__(self):
        self.now = 0.0
        self.sleeps = []

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds


class DumpTestCase(unittest.TestCase):
    """Временная выгрузка с solutions.json, tasks.json и assets/files/."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dump = Path(self._tmp.name)
        (self.dump / 'assets' / 'files').mkdir(parents=True)
        (self.dump / 'solutions.json').write_text(
            json.dumps(SOLUTIONS, ensure_ascii=False), encoding='utf-8'
        )
        (self.dump / 'tasks.json').write_text(
            json.dumps(TASKS, ensure_ascii=False), encoding='utf-8'
        )
        self.client = StubClient(SOLUTIONS)
        self.clock = FakeClock()

    def run_main(self, *argv, expected_publish=2):
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(importer, 'EXPECTED_TO_PUBLISH', expected_publish):
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                code = importer.main(
                    ['--dump', str(self.dump), *argv],
                    client=self.client,
                    sleep=self.clock.sleep,
                    clock=self.clock,
                )
        return code, out.getvalue() + err.getvalue()


class SelectionTest(DumpTestCase):
    def test_confirmed_and_publishable(self):
        solutions, tasks = importer.load_dump(self.dump)
        confirmed = importer.select_confirmed(solutions)
        self.assertEqual([e['short_id'] for e in confirmed], CONFIRMED)
        publishable = importer.select_publishable(confirmed, tasks)
        self.assertEqual([e['short_id'] for e in publishable], PUBLISHABLE)

    def test_slug_is_lowercase_short_id(self):
        self.assertEqual(importer.task_slug('eFeAB3'), 'fipi-efeab3')

    def test_dry_run_counts(self):
        code, output = self.run_main('--dry-run')
        self.assertEqual(code, 0, output)
        self.assertIn('к заливке: 6, к публикации: 2', output)
        self.assertEqual(self.client.calls, [])

    def test_dry_run_catches_wrong_reference(self):
        broken = [dict(SOLUTIONS[0], reference_solution='print("другое")')]
        (self.dump / 'solutions.json').write_text(json.dumps(broken), encoding='utf-8')
        code, output = self.run_main('--dry-run', expected_publish=1)
        self.assertEqual(code, 1)
        self.assertIn('не совпал', output)


class LoadTest(DumpTestCase):
    def test_loads_all_confirmed(self):
        code, output = self.run_main()
        self.assertEqual(code, 0, output)
        self.assertEqual(len(self.client.names('set_answer')), 6)
        self.assertEqual(len(self.client.names('verify_reference')), 6)
        for slug in ('fipi-aa0001', 'fipi-ab0002'):
            self.assertIsNotNone(self.client.tasks[slug]['reference_verified_at'])
        self.assertEqual(self.client.names('set_status'), [])

    def test_already_loaded_task_is_skipped(self):
        self.run_main()
        self.client.calls.clear()
        code, output = self.run_main()
        self.assertEqual(code, 0, output)
        self.assertEqual(self.client.names('set_answer'), [])
        self.assertEqual(len(self.client.names('get_task')), 6)
        self.assertIn('уже залита', output)

    def test_published_task_is_not_unpublished_on_rerun(self):
        self.run_main()
        self.run_main('--publish')
        self.run_main()
        self.assertEqual(self.client.tasks['fipi-aa0001']['status'], 'published')

    def test_changed_answer_is_reloaded(self):
        self.run_main()
        self.client.tasks['fipi-aa0005']['answer'] = 'старый'
        self.client.calls.clear()
        self.run_main()
        self.assertEqual(self.client.names('set_answer'), [('set_answer', 'fipi-aa0005')])

    def test_stops_on_mismatch(self):
        self.client.mismatch.add('fipi-ab0002')
        code, output = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn('matches: false', output)
        # Первая задача залита, на второй стоп: дальше скрипт не пошёл.
        self.assertEqual(
            [call[1] for call in self.client.names('set_answer')],
            ['fipi-aa0001', 'fipi-ab0002'],
        )

    def test_stops_on_failing_reference(self):
        broken = [dict(SOLUTIONS[0], reference_solution='raise ValueError("SECRET-ANSWER-QWERTY")')]
        (self.dump / 'solutions.json').write_text(json.dumps(broken), encoding='utf-8')
        code, output = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn('ValueError', output)
        self.assertNotIn(SECRET_ANSWER, output)
        self.assertEqual(self.client.names('verify_reference'), [])

    def test_single_slug(self):
        code, output = self.run_main('--slug', 'aB0002')
        self.assertEqual(code, 0, output)
        self.assertEqual(self.client.names('set_answer'), [('set_answer', 'fipi-ab0002')])

    def test_wrong_task_under_slug_is_refused(self):
        self.client.tasks['fipi-aa0001']['fipi_short_id'] = 'OTHER1'
        code, output = self.run_main('--slug', 'fipi-aa0001')
        self.assertEqual(code, 1)
        self.assertEqual(self.client.names('set_answer'), [])

    def test_retries_after_rate_limit(self):
        self.client.fail_queue.append(
            ContentApiError('rate_limit', 'Слишком много изменений контента.')
        )
        code, output = self.run_main('--slug', 'AA0001')
        self.assertEqual(code, 0, output)
        self.assertIn(60, self.clock.sleeps)
        self.assertIn('[rate_limit]', output)
        self.assertEqual(len(self.client.names('set_answer')), 1)
        self.assertEqual(len(self.client.names('get_task')), 2)


class PublishTest(DumpTestCase):
    def test_publishes_selected(self):
        self.run_main()
        code, output = self.run_main('--publish')
        self.assertEqual(code, 0, output)
        self.assertEqual(
            sorted(call[1] for call in self.client.names('set_status')),
            ['fipi-aa0001', 'fipi-ab0002'],
        )
        self.assertEqual(self.client.tasks['fipi-aa0003']['status'], 'draft')

    def test_refuses_when_count_differs(self):
        self.run_main()
        self.client.calls.clear()
        code, output = self.run_main('--publish', expected_publish=139)
        self.assertEqual(code, 1)
        self.assertIn('не публикую ничего', output)
        self.assertEqual(self.client.calls, [])

    def test_refuses_task_with_files(self):
        self.run_main()
        self.client.tasks['fipi-ab0002']['files'] = [{'filename': 'x.txt'}]
        code, output = self.run_main('--publish')
        self.assertEqual(code, 1)
        self.assertEqual(self.client.names('set_status'), [])

    def test_refuses_unloaded_task(self):
        code, output = self.run_main('--publish')
        self.assertEqual(code, 1)
        self.assertEqual(self.client.names('set_status'), [])


class SecrecyTest(DumpTestCase):
    def test_output_has_no_answers_or_references(self):
        outputs = [
            self.run_main('--dry-run')[1],
            self.run_main()[1],
            self.run_main('--publish')[1],
        ]
        self.client.mismatch.add('fipi-aa0001')
        self.client.tasks['fipi-aa0001']['answer'] = None
        outputs.append(self.run_main()[1])
        for output in outputs:
            self.assertNotIn(SECRET_ANSWER, output)
            self.assertNotIn(SECRET_REFERENCE_MARK, output)

    def test_api_error_message_is_redacted(self):
        def failing(payload):
            raise ContentApiError('bad_answer', f'Ответ «{payload["answer"]}» не подошёл.')

        self.client.set_answer = failing
        code, output = self.run_main('--slug', 'AA0001')
        self.assertEqual(code, 1)
        self.assertIn('[bad_answer]', output)
        self.assertNotIn(SECRET_ANSWER, output)


class NormalizeTest(unittest.TestCase):
    """Перенос public.normalize_answer: те же правила, что в базе."""

    def test_numbers(self):
        normalize = importer.normalize_answer
        self.assertEqual(normalize(' 007 ', 'single'), '7')
        self.assertEqual(normalize('-0', 'single'), '0')
        self.assertEqual(normalize('1.50', 'single'), '1.5')
        self.assertEqual(normalize('2.0', 'single'), '2')
        self.assertEqual(normalize('10', 'single'), '10')
        self.assertEqual(normalize('1\n2\t 3', 'multi'), '1 2 3')
        self.assertIsNone(normalize('1 2', 'single'))
        self.assertIsNone(normalize('1', 'pair'))
        self.assertIsNone(normalize('А', 'multi'))
        self.assertIsNone(normalize('', 'multi'))

    def test_string_keeps_case(self):
        self.assertEqual(importer.normalize_answer('  wxYz ', 'string'), 'wxYz')

    def test_edges_trimmed_only_from_spaces(self):
        # btrim в базе срезает только пробелы: перевод строки на краю
        # становится пробелом и ломает числовой ответ.
        self.assertEqual(importer.normalize_answer('42\n', 'string'), '42 ')
        self.assertIsNone(importer.normalize_answer('42\n', 'single'))


class ThrottleTest(unittest.TestCase):
    def test_no_more_than_limit_per_window(self):
        clock = FakeClock()
        throttle = importer.Throttle(limit=50, window=60, clock=clock, sleep=clock.sleep)
        for _ in range(50):
            throttle.wait()
        self.assertEqual(clock.sleeps, [])
        throttle.wait()
        self.assertEqual(clock.sleeps, [60])


if __name__ == '__main__':
    unittest.main()
