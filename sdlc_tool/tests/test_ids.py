"""Тесты `next`: следующий id, номер сдачи и приёмки, отказы.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

from sdlc_tool import ids, model
from sdlc_tool.tests.helpers import (
    PRD, UC_1, TreeTestCase, bury, obsolete_mark, prd_text, requirement, seed, uc_text,
)


class NextIdTest(TreeTestCase):
    def next(self, kind, owner=None):
        return ids.next_id(self.tree.repo(), kind, owner)

    def refuse(self, kind, owner, fragment):
        with self.assertRaises(model.Refusal) as caught:
            self.next(kind, owner)
        self.assertEqual(caught.exception.code, 2)
        self.assertIn(fragment, str(caught.exception))

    def test_empty_tree(self):
        self.assertEqual(self.next('UC'), 'UC-1')
        self.assertEqual(self.next('R'), 'R1')
        self.assertEqual(self.next('BT'), 'BT-1')

    def test_counts_buried(self):
        seed(self.tree)
        self.tree.write('sdlc/2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md',
                        uc_text(3))
        bury(self.tree, 'sdlc/2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md')
        self.assertEqual(self.next('UC'), 'UC-4')
        self.assertEqual(self.next('TOKEN'), 'TOKEN-2')

    def test_business_tasks_share_counter(self):
        seed(self.tree)
        self.tree.write('sdlc/1-business-tasks/observation/errors/BT-5-ERROR-CRASH.md', '# BT-5\n')
        self.assertEqual(self.next('BT'), 'BT-6')

    def test_requirements(self):
        self.tree.write(PRD, prd_text(
            requirement(1, 'Первое.', obsolete_mark(by=7)),
            requirement(7, 'Седьмое.'),
            '<a id="r9"></a>**R8.** Строка с ошибкой.',
        ))
        self.assertEqual(self.next('R'), 'R10')

    def test_results(self):
        seed(self.tree)
        self.assertEqual(self.next('RESULT', 'TASK-1'), 'RESULT-TASK-1-02')
        self.tree.write('sdlc/5-results/RESULT-TASK-1-09-LATE.md', '# сдача\n')
        self.assertEqual(self.next('RESULT', 'TASK-1'), 'RESULT-TASK-1-10')
        self.tree.write('sdlc/4-tasks/TASK-2-CATALOG.md', '# TASK-2\n')
        self.assertEqual(self.next('RESULT', 'TASK-2'), 'RESULT-TASK-2-01')

    def test_acceptance(self):
        seed(self.tree)
        self.tree.write('sdlc/5-results/RESULT-TASK-1-02.md', '# сдача\n')
        self.assertEqual(self.next('ACC', 'RESULT-TASK-1-02'), 'ACC-TASK-1-02')
        self.refuse('ACC', 'RESULT-TASK-1-01', 'уже есть приёмка ACC-TASK-1-01')
        self.refuse('ACC', 'RESULT-TASK-1-03', 'сдачи RESULT-TASK-1-03 нет')
        self.refuse('ACC', 'TASK-1', 'владелец — сдача')
        self.refuse('ACC', None, 'владелец — сдача')

    def test_refusals(self):
        seed(self.tree)
        self.refuse('XX', None, 'неизвестный тип XX')
        self.refuse('uc', None, 'неизвестный тип uc')
        self.refuse('UC', 'TASK-1', 'у UC владельца нет')
        self.refuse('R', 'TASK-1', 'у R владельца нет')
        self.refuse('RESULT', None, 'владелец — задание')
        self.refuse('RESULT', 'TASK-01', 'владелец — задание')
        self.refuse('RESULT', 'TASK-5', 'задания TASK-5 нет')

    def test_ignores_bad_names(self):
        seed(self.tree)
        self.tree.write('sdlc/2-specs/use-cases/UC-07-bad.md', 'x\n')
        self.assertEqual(self.next('UC'), 'UC-2')
        self.assertTrue(self.tree.exists(UC_1))
