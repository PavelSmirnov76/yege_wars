"""Тесты `views`: `INDEX.md` по папкам, «К пересмотру» и «Похоронены»,
закрытость бизнес-задач планирования, сводка `DASHBOARD.md`, ссылки от папки
производного файла, детерминизм и запись.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import contextlib
import io
import json
import os
from typing import List, Optional, Sequence, Tuple

from sdlc_tool import model, views
from sdlc_tool.__main__ import main
from sdlc_tool.tests.helpers import (
    ACC_1, ACTOR_1, BT_1, COMP_1, ENT_1, FIG_1, PRD, RESULT_1, TASK_1, TC_1, TOKEN_1,
    UC_1, Tree, TreeTestCase, bury, link, obsolete_mark, prd_text, requirement, seed,
    uc_text,
)

UC_2 = 'sdlc/2-specs/use-cases/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
BT_2 = 'sdlc/1-business-tasks/planning/BT-2-PLANNING-CATALOG.md'
TC_2 = 'sdlc/6-eval/manual/TC-2-RESET.md'
TASK_2 = 'sdlc/4-tasks/TASK-2-RESET.md'
RESULT_2 = 'sdlc/5-results/RESULT-TASK-1-02.md'
ACC_2 = 'sdlc/6-eval/acceptance/ACC-TASK-1-02.md'
AUTO = 'sdlc/6-eval/auto'
MANUAL = 'sdlc/6-eval/manual'
DASHBOARD = model.DASHBOARD_PATH

PLANNING = '1-business-tasks/planning'
USE_CASES = '2-specs/use-cases'
DESIGN_SYSTEM = '3-design/design-system'
TASKS = '4-tasks'
RESULTS = '5-results'
ACCEPTANCE = '6-eval/acceptance'
MANUAL_FOLDER = '6-eval/manual'

R1_TEXT = 'Ученик входит по логину и паролю.'
R2_TEXT = 'Ученик видит каталог задач.'

SEEDED = [
    'sdlc/1-business-tasks/planning/INDEX.md',
    'sdlc/2-specs/actors/INDEX.md',
    'sdlc/2-specs/entities/INDEX.md',
    'sdlc/2-specs/events/INDEX.md',
    'sdlc/2-specs/modules/INDEX.md',
    'sdlc/2-specs/use-cases/INDEX.md',
    'sdlc/3-design/INDEX.md',
    'sdlc/3-design/design-system/INDEX.md',
    'sdlc/4-tasks/INDEX.md',
    'sdlc/5-results/INDEX.md',
    'sdlc/6-eval/DASHBOARD.md',
    'sdlc/6-eval/acceptance/INDEX.md',
    'sdlc/6-eval/manual/INDEX.md',
]


def section(text: str, title: Optional[str] = None) -> Optional[str]:
    """Часть текста до первого `## ` (title=None) или раздел `## title`."""
    parts = text.split('\n## ')
    if title is None:
        return parts[0]
    for part in parts[1:]:
        if part.startswith(title + '\n'):
            return part
    return None


def table_rows(text: str) -> List[List[str]]:
    """Строки таблиц текста (без заголовков) — списки ячеек."""
    rows = []
    for line in text.split('\n'):
        if line.startswith('| ') and line.endswith(' |'):
            cells = line[2:-2].split(' | ')
            if cells[0] not in ('Id', 'Требование'):
                rows.append(cells)
    return rows


def row_of(text: str, key: str) -> List[str]:
    """Первая строка таблицы, чья первая ячейка — ссылка с текстом `key`."""
    for cells in table_rows(text):
        if cells[0].startswith(f'[{key}]('):
            return cells
    raise AssertionError(f'нет строки {key} в:\n{text}')


class ViewsTestCase(TreeTestCase):
    """Дерево и разбор производных файлов."""

    def render(self):
        return views.render_all(self.tree.repo())

    def index(self, folder: str) -> str:
        text = self.render()[model.index_path(folder)]
        self.assertIsNotNone(text, folder)
        return text

    def dashboard(self) -> str:
        text = self.render()[DASHBOARD]
        self.assertIsNotNone(text)
        return text

    def write_run(self, name: str, tests: Sequence[Tuple[object, str]] = (),
                  paths: Optional[dict] = None, started_at: Optional[str] = None,
                  summary_md: bool = True) -> None:
        """Машинный прогон `auto/<name>/` с тестами (метка, вердикт)."""
        summary = {
            'commit_short': name[11:], 'date': name[:10],
            'started_at': started_at or f'{name[:10]}T10:00:00+03:00',
            'tests': [{'file': 'test/a_test.dart', 'name': f'тест {index}', 'label': label,
                       'verdict': verdict} for index, (label, verdict) in enumerate(tests)],
        }
        if paths is not None:
            summary['paths'] = paths
        self.tree.write(f'{AUTO}/{name}/summary.json', json.dumps(summary, ensure_ascii=False))
        if summary_md:
            self.tree.write(f'{AUTO}/{name}/summary.md', '# Прогон\n')

    def write_round(self, date: str, case: str, verdict: Optional[str]) -> None:
        """Раунд ручного кейса: `manual/<date>/<case>/transcript.md`."""
        line = f'**Вердикт:** {verdict}' if verdict else 'Вердикт не записан.'
        self.tree.write(f'{MANUAL}/{date}/{case}/transcript.md', f'# Прогон\n\n{line}\n')

    def assertDerivedLinksResolve(self) -> None:
        """Ссылки производных файлов на диске разрешаются от их папки."""
        repo = self.tree.repo()
        derived = [path for path in repo.files
                   if path == DASHBOARD or path.endswith('/' + model.INDEX_NAME)]
        self.assertTrue(derived)
        for path in derived:
            for item in repo.doc(path).links:
                resolved = repo.resolve(item)
                self.assertNotEqual(resolved.kind, model.MISSING, f'{path}: {item.target}')
                if resolved.kind in (model.ARTIFACT_LINK, model.REQUIREMENT_LINK):
                    self.assertEqual(item.text, resolved.target_id, f'{path}: {item.target}')
                    self.assertTrue(resolved.anchor_ok, f'{path}: {item.target}')


def uc2_text(paths=(('01', 'сброс'), ('02', 'неверный код')), extra: str = '') -> str:
    """UC-2 на R1 и BT-1."""
    basis = f'{link(UC_2, PRD, "R1", "r1")}, {link(UC_2, BT_1, "BT-1")}'
    return uc_text(2, paths=paths, basis=basis, title='сброс пароля') + extra


# --------------------------------------------------------------------------


class EmptyTreeTest(ViewsTestCase):
    def test_no_artifacts_no_files(self):
        rendered = self.render()
        for folder in model.ARTIFACT_FOLDERS:
            self.assertIn(model.index_path(folder), rendered)
        self.assertIn(DASHBOARD, rendered)
        self.assertEqual({path: text for path, text in rendered.items() if text is not None}, {})
        self.assertEqual(views.write_all(self.tree.repo()), [])
        self.assertFalse(self.tree.exists(DASHBOARD))
        self.assertFalse([path for path in self.tree.repo().files
                          if path.endswith('/INDEX.md')])
        self.assertEqual(self.tree.check(derived=True), [])

    def test_stray_derived_files_removed(self):
        stray = sorted([
            'sdlc/0-vibes/raw/2026-11-01/INDEX.md',
            'sdlc/2-specs/INDEX.md',
            'sdlc/2-specs/actors/INDEX.md',
            DASHBOARD,
        ])
        for path in stray:
            self.tree.write(path, 'старый\n')
        rendered = self.render()
        for path in stray:
            self.assertIn(path, rendered)
            self.assertIsNone(rendered[path])
        self.assertEqual(self.tree.errors(), [])
        errors = [item.format() for item in self.tree.check(derived=True)]
        self.assertEqual(len(errors), 4, errors)
        for path in stray:
            self.assertMessage(errors, path, 'лишний производный файл')
        self.assertEqual(views.write_all(self.tree.repo()), stray)
        for path in stray:
            self.assertFalse(self.tree.exists(path), path)
        self.assertEqual(self.tree.check(derived=True), [])

    def test_index_in_obsolete_removed(self):
        seed(self.tree)
        bury(self.tree, ENT_1)
        stray = 'sdlc/2-specs/entities/obsolete/INDEX.md'
        self.tree.write(stray, 'старый\n')
        self.assertIsNone(self.render()[stray])
        self.assertIn(stray, views.write_all(self.tree.repo()))
        self.assertFalse(self.tree.exists(stray))
        self.assertTrue(self.tree.exists('sdlc/2-specs/entities/INDEX.md'))


class SeededTest(ViewsTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def test_write_and_check(self):
        self.assertEqual(views.write_all(self.tree.repo()), SEEDED)
        self.assertEqual(views.write_all(self.tree.repo()), [])
        self.assertEqual([item.format() for item in self.tree.check(derived=True)], [])
        self.assertDerivedLinksResolve()
        for path in SEEDED:
            text = self.tree.read(path)
            self.assertTrue(text.startswith(model.DERIVED_HEADER + '\n'), path)
            self.assertTrue(text.endswith('\n') and not text.endswith('\n\n'), path)

    def test_render_only_reads(self):
        self.render()
        for path in SEEDED:
            self.assertFalse(self.tree.exists(path), path)

    def test_use_cases_index(self):
        self.assertEqual(self.index(USE_CASES), '\n'.join([
            model.DERIVED_HEADER,
            '',
            '# Индекс: `2-specs/use-cases/`',
            '',
            '| Id | Название | Ссылается на | Пути | Проверено | Где реализован |',
            '|---|---|---|---|---|---|',
            '| [UC-1](UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md) | вход по паролю | '
            '[R1](../../0-vibes/prd/PRD.md#r1), '
            '[BT-1](../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md), '
            '[MOD-1](../modules/MOD-1-AUTH.md) | 1 | 0 из 1 | не покрыто |',
            '']))

    def test_dashboard(self):
        uc = '../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md'
        self.assertEqual(self.dashboard(), '\n'.join([
            model.DERIVED_HEADER,
            '',
            '# Сводка проверки',
            '',
            'Последний машинный прогон: нет',
            '',
            '| Требование | UC | Путь | Вердикт | Источник |',
            '|---|---|---|---|---|',
            f'| [R1](../0-vibes/prd/PRD.md#r1) | [UC-1]({uc}) | [UC-1-P-01]({uc}#uc-1-p-01) '
            '| НЕ ПРОВЕРЕНО | — |',
            '| [R2](../0-vibes/prd/PRD.md#r2) | — | — | НЕ ПРОВЕРЕНО: нет UC | — |',
            '',
            'Итого путей: PASS 0, FAIL 0, BLOCKED 0, НЕ ПРОВЕРЕНО 1.',
            '']))

    def test_plain_folder_columns(self):
        text = self.index('2-specs/modules')
        self.assertIn('| Id | Название | Ссылается на |\n|---|---|---|\n', text)
        self.assertEqual(row_of(text, 'MOD-1'), [
            '[MOD-1](MOD-1-AUTH.md)', 'AUTH',
            '[BT-1](../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)'])
        self.assertIsNone(section(text, 'К пересмотру'))
        self.assertIsNone(section(text, 'Похоронены'))

    def test_references_order_anchor_self_and_repeats(self):
        index = model.index_path('3-design')
        self.tree.write(FIG_1, self.tree.read(FIG_1) + '\n'.join([
            f'Сам экран: {link(FIG_1, FIG_1, "FIG-1")}, повтор: {link(FIG_1, COMP_1, "COMP-1")}.',
            f'Битые якоря: {link(FIG_1, UC_1, "UC-1-P-07", "uc-1-p-07")}, '
            f'{link(FIG_1, PRD, "R9", "r9")}.', '']))
        self.assertEqual(row_of(self.index('3-design'), 'FIG-1')[2], ', '.join([
            link(index, UC_1, 'UC-1'),
            link(index, UC_1, 'UC-1-P-01', 'uc-1-p-01'),
            link(index, COMP_1, 'COMP-1'),
            link(index, TOKEN_1, 'TOKEN-1'),   # якорь #accent отброшен
            'UC-1-P-07', 'R9',                 # якоря нет — id без ссылки
        ]))
        views.write_all(self.tree.repo())
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        for message in errors:
            self.assertIn(FIG_1, message)      # ошибка — у источника, не в индексе

    def test_title_without_links_and_pipes(self):
        self.tree.write(UC_2, uc2_text().replace(
            '# UC-2 — сброс пароля',
            '# UC-2 — сброс [пароля](https://example.invalid) | ![код](x.png)'))
        self.assertEqual(row_of(self.index(USE_CASES), 'UC-2')[1], 'сброс пароля \\| код')
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.check(derived=True), [])

    def test_empty_title(self):
        self.assertEqual(row_of(self.index(RESULTS), 'RESULT-TASK-1-01')[1], '—')


class SectionsTest(ViewsTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def test_buried_without_replacement(self):
        moved = bury(self.tree, ENT_1)
        text = self.index('2-specs/entities')
        self.assertEqual(table_rows(section(text)), [])
        self.assertEqual(table_rows(section(text, 'Похоронены')), [[
            '[ENT-1](obsolete/ENT-1-ACCOUNT-IN-AUTH.md)', 'учётная запись', 'ничем']])
        self.assertIsNone(section(text, 'К пересмотру'))
        stale = link(model.index_path('2-specs/actors'), moved, 'ENT-1')
        self.assertEqual(table_rows(section(self.index('2-specs/actors'), 'К пересмотру')), [
            [link(model.index_path('2-specs/actors'), ACTOR_1, 'ACTOR-1'), stale]])
        self.assertEqual(row_of(self.index('2-specs/events'), 'EVT-1')[2],
                         link(model.index_path('2-specs/events'), moved, 'ENT-1'))
        self.assertIsNotNone(section(self.index('2-specs/events'), 'К пересмотру'))
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.errors(), [])
        self.assertDerivedLinksResolve()

    def test_buried_with_replacement_and_supersedes(self):
        self.tree.write(UC_2, uc2_text(extra=f'\nsupersedes: {link(UC_2, UC_1, "UC-1")}\n'))
        moved = bury(self.tree, UC_1, by=('UC-2', UC_2))
        text = self.index(USE_CASES)
        self.assertEqual(table_rows(section(text, 'Похоронены')), [[
            '[UC-1](obsolete/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md)', 'вход по паролю',
            '[UC-2](UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md)']])
        self.assertEqual([cells[0][:6] for cells in table_rows(section(text))], ['[UC-2]'])
        self.assertIn('[UC-1](obsolete/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md)',
                      row_of(text, 'UC-2')[2])
        self.assertIsNone(section(text, 'К пересмотру'))  # supersedes — не к пересмотру
        tasks = self.index(TASKS)
        self.assertEqual(table_rows(section(tasks, 'К пересмотру')), [[
            link(model.index_path(TASKS), TASK_1, 'TASK-1'),
            link(model.index_path(TASKS), moved, 'UC-1-P-01', 'uc-1-p-01')]])
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.errors(), [])
        self.assertDerivedLinksResolve()

    def test_buried_without_header(self):
        moved = bury(self.tree, ENT_1)
        self.tree.write(moved, model.strip_tomb_header(self.tree.read(moved)))
        self.assertEqual(row_of(section(self.index('2-specs/entities'), 'Похоронены'), 'ENT-1'),
                         ['[ENT-1](obsolete/ENT-1-ACCOUNT-IN-AUTH.md)', 'учётная запись', '—'])

    def test_obsolete_requirement_to_review(self):
        self.tree.write(PRD, prd_text(requirement(1, R1_TEXT, obsolete_mark(by=2)),
                                      requirement(2, R2_TEXT)))
        index = model.index_path(PLANNING)
        self.assertEqual(table_rows(section(self.index(PLANNING), 'К пересмотру')), [
            [link(index, BT_1, 'BT-1'), link(index, PRD, 'R1', 'r1')]])
        index = model.index_path(USE_CASES)
        self.assertEqual(row_of(section(self.index(USE_CASES), 'К пересмотру'), 'UC-1')[1],
                         link(index, PRD, 'R1', 'r1'))


class PlanningClosureTest(ViewsTestCase):
    INDEX = model.index_path(PLANNING)

    def setUp(self):
        super().setUp()
        seed(self.tree)

    def closed(self, key: str = 'BT-1') -> str:
        return row_of(self.index(PLANNING), key)[3]

    def path(self, uc: str, path_id: str) -> str:
        return link(self.INDEX, uc, path_id, path_id.lower())

    def test_not_checked(self):
        self.assertEqual(self.closed(), f'нет — не проверено: {self.path(UC_1, "UC-1-P-01")}')

    def test_pass_closes(self):
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.assertEqual(self.closed(), 'да')

    def test_fail_and_blocked(self):
        self.write_round('2026-11-04', 'TC-1', 'FAIL')
        self.assertEqual(self.closed(), f'нет — FAIL: {self.path(UC_1, "UC-1-P-01")}')
        self.write_run('2026-11-05-abc1234', [('UC-1-P-01', 'BLOCKED')])
        self.assertEqual(self.closed(), f'нет — BLOCKED: {self.path(UC_1, "UC-1-P-01")}')

    def test_reasons_in_order(self):
        self.tree.write(UC_2, uc2_text(paths=(('01', 'сброс'), ('02', 'код'), ('03', 'сеть'))))
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.write_run('2026-11-04-abc1234', [('UC-2-P-02', 'FAIL'), ('UC-2-P-03', 'BLOCKED')])
        self.assertEqual(self.closed(), (
            f'нет — FAIL: {self.path(UC_2, "UC-2-P-02")}; '
            f'BLOCKED: {self.path(UC_2, "UC-2-P-03")}; '
            f'не проверено: {self.path(UC_2, "UC-2-P-01")}'))

    def test_uc_without_paths_is_not_checked(self):
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.tree.write(UC_2, uc2_text(paths=()))
        self.assertEqual(self.closed(), f'нет — не проверено: {link(self.INDEX, UC_2, "UC-2")}')

    def test_no_uc(self):
        self.tree.write(BT_2, f'# BT-2 — каталог\n\nТребование: {link(BT_2, PRD, "R2", "r2")}.\n')
        self.assertEqual(self.closed('BT-2'), 'нет — нет UC')

    def test_buried_uc_does_not_count(self):
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        bury(self.tree, UC_1)
        self.assertEqual(self.closed(), 'нет — нет UC')


class UseCaseColumnsTest(ViewsTestCase):
    INDEX = model.index_path(USE_CASES)

    def setUp(self):
        super().setUp()
        seed(self.tree)
        self.tree.write(UC_2, uc2_text())

    def test_paths_checked_and_labels(self):
        self.write_run('2026-11-04-abc1234', [('UC-2-P-02', 'FAIL')])
        self.tree.write('lib/features/auth/reset.dart', '// UC-2\n// UC-1\n')
        self.tree.write('lib/features/auth/a_reset.dart', '// UC-2: сброс\n// UC-2\n')
        self.tree.write('test/reset_test.dart', "test('UC-2-P-01: сброс', () {});\n")
        text = self.index(USE_CASES)
        self.assertEqual(row_of(text, 'UC-2')[3:], ['2', '1 из 2', ', '.join([
            link(self.INDEX, 'lib/features/auth/a_reset.dart', '`lib/features/auth/a_reset.dart`'),
            link(self.INDEX, 'lib/features/auth/reset.dart', '`lib/features/auth/reset.dart`'),
        ])])
        self.assertEqual(row_of(text, 'UC-1')[3:], ['1', '0 из 1', link(
            self.INDEX, 'lib/features/auth/reset.dart', '`lib/features/auth/reset.dart`')])
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.check(derived=True), [])

    def test_not_covered(self):
        self.assertEqual(row_of(self.index(USE_CASES), 'UC-2')[5], 'не покрыто')


class DesignSystemColumnsTest(ViewsTestCase):
    INDEX = model.index_path(DESIGN_SYSTEM)

    def setUp(self):
        super().setUp()
        seed(self.tree)

    def file(self, path: str) -> str:
        return link(self.INDEX, path, f'`{path}`')

    def test_where_implemented_and_unlabeled_theme(self):
        self.tree.write('lib/app/theme/app_colors.dart', '// TOKEN-1\n')
        self.tree.write('lib/app/theme/app_spacing.dart', '// отступы\n')
        self.tree.write('lib/app/theme/legacy.dart', '// TOKEN-9\n')
        self.tree.write('lib/app/theme/sub/inner.dart', '// не файл темы\n')
        self.tree.write('lib/widgets/button.dart', '// COMP-1\n')
        text = self.index(DESIGN_SYSTEM)
        self.assertEqual(row_of(text, 'TOKEN-1')[3], self.file('lib/app/theme/app_colors.dart'))
        self.assertEqual(row_of(text, 'COMP-1')[3], self.file('lib/widgets/button.dart'))
        self.assertEqual(section(text, 'Файлы темы без метки'), '\n'.join([
            'Файлы темы без метки', '', f'- {self.file("lib/app/theme/app_spacing.dart")}', '']))
        self.assertTrue(text.endswith(f'- {self.file("lib/app/theme/app_spacing.dart")}\n'))

    def test_no_section_when_all_labeled(self):
        self.tree.write('lib/app/theme/app_colors.dart', '// TOKEN-1\n')
        text = self.index(DESIGN_SYSTEM)
        self.assertIsNone(section(text, 'Файлы темы без метки'))
        self.assertEqual(row_of(text, 'COMP-1')[3], 'не покрыто')


class TaskColumnsTest(ViewsTestCase):
    INDEX = model.index_path(TASKS)

    def setUp(self):
        super().setUp()
        seed(self.tree)
        self.tree.write(UC_2, uc2_text())

    def columns(self, key: str = 'TASK-1') -> List[str]:
        return row_of(self.index(TASKS), key)[3:]

    def test_seeded(self):
        self.assertEqual(self.columns(), [
            link(self.INDEX, UC_1, 'UC-1-P-01', 'uc-1-p-01'),
            link(self.INDEX, RESULT_1, 'RESULT-TASK-1-01'),
            f'{link(self.INDEX, ACC_1, "ACC-TASK-1-01")} — принято',
            'да'])

    def test_basis_paragraph_only(self):
        self.tree.write(TASK_2, '\n'.join([
            '# TASK-2: сброс', '',
            f'**Основание:** {link(TASK_2, UC_2, "UC-2-P-02", "uc-2-p-02")},',
            f'{link(TASK_2, UC_2, "UC-2-P-01", "uc-2-p-01")}, {link(TASK_2, BT_1, "BT-1")},',
            f'{link(TASK_2, UC_2, "UC-2-P-02", "uc-2-p-02")}.', '',
            '## Чего не делать', '',
            f'- не трогать {link(TASK_2, UC_1, "UC-1-P-01", "uc-1-p-01")}.', '']))
        cells = row_of(self.index(TASKS), 'TASK-2')
        self.assertEqual(cells[3], ', '.join([
            link(self.INDEX, UC_2, 'UC-2-P-02', 'uc-2-p-02'),
            link(self.INDEX, UC_2, 'UC-2-P-01', 'uc-2-p-01')]))
        self.assertIn(link(self.INDEX, UC_1, 'UC-1-P-01', 'uc-1-p-01'), cells[2])
        self.assertEqual(cells[4:], ['—', '—', 'нет'])

    def test_basis_section_and_missing(self):
        self.tree.write(TASK_2, '\n'.join([
            '# TASK-2: сброс', '', '## Основание', '',
            f'- {link(TASK_2, UC_2, "UC-2-P-01", "uc-2-p-01")}', '',
            '### Пояснение', '', f'{link(TASK_2, UC_2, "UC-2-P-02", "uc-2-p-02")}', '',
            '## Зачем', '', f'{link(TASK_2, UC_1, "UC-1-P-01", "uc-1-p-01")}', '']))
        self.assertEqual(self.columns('TASK-2')[0], ', '.join([
            link(self.INDEX, UC_2, 'UC-2-P-01', 'uc-2-p-01'),
            link(self.INDEX, UC_2, 'UC-2-P-02', 'uc-2-p-02')]))
        self.tree.write(TASK_2, '# TASK-2: сброс\n\n'
                                f'{link(TASK_2, UC_2, "UC-2-P-01", "uc-2-p-01")}\n')
        self.assertEqual(self.columns('TASK-2')[0], '—')

    def test_last_acceptance_decides(self):
        self.tree.write(RESULT_2, '# RESULT-TASK-1-02\n\n'
                                  f'Задание: {link(RESULT_2, TASK_1, "TASK-1")}.\n')
        self.tree.write(ACC_2, '# ACC-TASK-1-02\n\n**Вердикт:** возврат\n')
        self.assertEqual(self.columns(), [
            link(self.INDEX, UC_1, 'UC-1-P-01', 'uc-1-p-01'),
            f'{link(self.INDEX, RESULT_1, "RESULT-TASK-1-01")}, '
            f'{link(self.INDEX, RESULT_2, "RESULT-TASK-1-02")}',
            f'{link(self.INDEX, ACC_1, "ACC-TASK-1-01")} — принято, '
            f'{link(self.INDEX, ACC_2, "ACC-TASK-1-02")} — возврат',
            'нет'])
        self.tree.write(ACC_1, self.tree.read(ACC_1).replace('принято', 'возврат'))
        self.tree.write(ACC_2, '# ACC-TASK-1-02\n\n**Вердикт:** принято\n')
        self.assertEqual(self.columns()[3], 'да')
        self.tree.write(ACC_2, '# ACC-TASK-1-02\n\nВердикт: да\n')
        self.assertEqual(self.columns()[2].split(', ')[1],
                         f'{link(self.INDEX, ACC_2, "ACC-TASK-1-02")} — нет вердикта')
        self.assertEqual(self.columns()[3], 'нет')

    def test_buried_acceptance_does_not_count(self):
        bury(self.tree, ACC_1)
        self.assertEqual(self.columns()[2:], ['—', 'нет'])
        index = model.index_path(RESULTS)
        self.assertEqual(row_of(self.index(RESULTS), 'RESULT-TASK-1-01')[3:], [
            link(index, TASK_1, 'TASK-1'), 'нет'])

    def test_basis_lines(self):
        def block(*lines):
            return views.basis_lines(model.Document('', '\n'.join(lines)))
        self.assertEqual(block('# T', '', '**Основание:** a,', 'b.', '', 'c'), (3, 4))
        self.assertEqual(block('# T', '- Основание: a', '## Где', 'x'), (2, 2))
        self.assertEqual(block('# T', '## Основание', 'a', '### Под', 'b', '## Дальше'), (2, 5))
        self.assertEqual(block('# T', '```', '**Основание:** a', '```', 'b'), None)
        self.assertIsNone(block('# T', 'Основания нет.'))


class ResultAndAcceptanceColumnsTest(ViewsTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def test_result_columns(self):
        index = model.index_path(RESULTS)
        self.tree.write(RESULT_2, '# RESULT-TASK-1-02 — вторая\n')
        text = self.index(RESULTS)
        self.assertEqual(row_of(text, 'RESULT-TASK-1-01')[3:], [
            link(index, TASK_1, 'TASK-1'), f'{link(index, ACC_1, "ACC-TASK-1-01")} — принято'])
        self.assertEqual(row_of(text, 'RESULT-TASK-1-02')[1:], [
            'вторая', '—', link(index, TASK_1, 'TASK-1'), 'нет'])

    def test_acceptance_columns(self):
        index = model.index_path(ACCEPTANCE)
        self.assertEqual(row_of(self.index(ACCEPTANCE), 'ACC-TASK-1-01')[3:], [
            link(index, RESULT_1, 'RESULT-TASK-1-01'), 'принято'])
        self.tree.write(ACC_1, '# ACC-TASK-1-01\n\nВердикт: да\n')
        self.assertEqual(row_of(self.index(ACCEPTANCE), 'ACC-TASK-1-01')[3:], [
            link(index, RESULT_1, 'RESULT-TASK-1-01'), '—'])


class ManualColumnsTest(ViewsTestCase):
    INDEX = model.index_path(MANUAL_FOLDER)

    def setUp(self):
        super().setUp()
        seed(self.tree)

    def columns(self) -> List[str]:
        return row_of(self.index(MANUAL_FOLDER), 'TC-1')[3:]

    def test_rounds(self):
        path = link(self.INDEX, UC_1, 'UC-1-P-01', 'uc-1-p-01')
        self.assertEqual(self.columns(), [path, 'нет'])
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.write_round('2026-11-10', 'TC-1', 'FAIL')
        self.write_round('2026-11-07', 'TC-1', 'BLOCKED')
        self.assertEqual(self.columns(),
                         [path, '[2026-11-10](2026-11-10/TC-1/transcript.md) — FAIL'])
        self.write_round('2026-11-11', 'TC-1', None)
        self.assertEqual(self.columns()[1],
                         '[2026-11-11](2026-11-11/TC-1/transcript.md) — нет вердикта')
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.check(derived=True), [])


class DashboardTest(ViewsTestCase):
    UC = '../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md'

    def setUp(self):
        super().setUp()
        seed(self.tree)

    def path_row(self, path_id: str = 'UC-1-P-01') -> List[str]:
        rows = [cells for cells in table_rows(self.dashboard())
                if cells[2].startswith(f'[{path_id}](')]
        self.assertTrue(rows, path_id)
        return rows[0]

    def verdict(self, path_id: str = 'UC-1-P-01') -> List[str]:
        return self.path_row(path_id)[3:]

    def test_no_prd(self):
        self.tree.remove(PRD)
        views.write_all(self.tree.repo())
        self.assertIsNone(self.render()[DASHBOARD])
        self.tree.write(DASHBOARD, 'старая сводка\n')
        self.assertEqual(views.write_all(self.tree.repo()), [DASHBOARD])
        self.assertFalse(self.tree.exists(DASHBOARD))

    def test_auto_verdict_worst_test(self):
        for tests, expected in (
                ([('UC-1-P-01', 'PASS'), ('UC-1-P-01', 'FAIL'), ('UC-1-P-01', 'BLOCKED')], 'FAIL'),
                ([('UC-1-P-01', 'PASS'), ('UC-1-P-01', 'BLOCKED')], 'BLOCKED'),
                ([('UC-1-P-01', 'PASS'), (None, 'FAIL'), ('UC-1-P-02', 'FAIL')], 'PASS'),
                ([(['UC-1-P-01', 'UC-1-P-02'], 'FAIL')], 'FAIL')):
            with self.subTest(tests=tests):
                self.write_run('2026-11-04-abc1234', tests)
                self.assertEqual(self.verdict(), [expected, 'auto 2026-11-04-abc1234'])
        self.write_run('2026-11-04-abc1234', [(None, 'FAIL'), ('UC-2-P-01', 'PASS')])
        self.assertEqual(self.verdict(), ['НЕ ПРОВЕРЕНО', '—'])

    def test_auto_paths_record(self):
        self.write_run('2026-11-04-abc1234', [], paths={'UC-1-P-01': 'BLOCKED'})
        self.assertEqual(self.verdict(), ['BLOCKED', 'auto 2026-11-04-abc1234'])

    def test_latest_run_link(self):
        self.write_run('2026-11-04-abc1234', [('UC-1-P-01', 'PASS')])
        self.assertIn('\nПоследний машинный прогон: '
                      '[2026-11-04-abc1234](auto/2026-11-04-abc1234/summary.md)\n',
                      self.dashboard())
        self.tree.remove(f'{AUTO}/2026-11-04-abc1234/summary.md')
        self.assertIn('\nПоследний машинный прогон: '
                      '[2026-11-04-abc1234](auto/2026-11-04-abc1234/)\n', self.dashboard())
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.check(derived=True), [])

    def test_latest_run_by_started_at_then_name(self):
        # 05:00Z раньше 06:00Z, хотя строка «08:00+03:00» больше «06:00Z».
        self.write_run('2026-11-05-bbbbbbb', [('UC-1-P-01', 'FAIL')],
                       started_at='2026-11-05T08:00:00+03:00')
        self.write_run('2026-11-05-aaaaaaa', [('UC-1-P-01', 'PASS')],
                       started_at='2026-11-05T06:00:00Z')
        self.tree.write(f'{AUTO}/2026-11-09-zzzzzzz/summary.json', '{не json')
        self.tree.write(f'{AUTO}/2026-11-09-yyyyyyy/summary.json', '[]')
        self.assertEqual(self.verdict(), ['PASS', 'auto 2026-11-05-aaaaaaa'])
        self.write_run('2026-11-05-ccccccc', [('UC-1-P-01', 'BLOCKED')],
                       started_at='2026-11-05T09:00:00+03:00')
        self.assertEqual(self.verdict(), ['BLOCKED', 'auto 2026-11-05-ccccccc'])
        self.write_run('2026-11-05-ddddddd', [('UC-1-P-01', 'FAIL')],
                       started_at='2026-11-05T09:00:00+03:00')
        self.assertEqual(self.verdict(), ['FAIL', 'auto 2026-11-05-ddddddd'])

    def test_partial_run_does_not_set_verdicts(self):
        # Прогон с --skip позже полного, но сводку задаёт полный.
        self.write_run('2026-11-05-aaaaaaa', [('UC-1-P-01', 'PASS')],
                       started_at='2026-11-05T06:00:00Z')
        partial = {'commit_short': 'bbbbbbb', 'date': '2026-11-05',
                   'started_at': '2026-11-05T07:00:00Z',
                   'checks': [{'name': 'flutter_test', 'verdict': None},
                              {'name': 'tools_tests', 'verdict': 'PASS'}],
                   'tests': []}
        self.tree.write(f'{AUTO}/2026-11-05-bbbbbbb/summary.json',
                        json.dumps(partial, ensure_ascii=False))
        self.assertEqual(self.verdict(), ['PASS', 'auto 2026-11-05-aaaaaaa'])
        self.assertIn('[2026-11-05-aaaaaaa]', self.dashboard())

    def test_only_unreadable_runs(self):
        self.tree.write(f'{AUTO}/2026-11-09-zzzzzzz/summary.json', '{не json')
        self.assertIn('\nПоследний машинный прогон: нет\n', self.dashboard())
        self.assertEqual(self.verdict(), ['НЕ ПРОВЕРЕНО', '—'])

    def test_run_date_from_folder_name(self):
        self.tree.write(f'{AUTO}/2026-11-06-abc1234/summary.json', json.dumps({
            'started_at': '2026-11-05T22:00:00+00:00',
            'tests': [{'label': 'UC-1-P-01', 'verdict': 'PASS'}]}))
        self.write_round('2026-11-05', 'TC-1', 'FAIL')
        self.assertEqual(self.verdict(), ['PASS', 'auto 2026-11-06-abc1234'])

    def test_manual_and_auto_by_date_then_worst(self):
        case = '[TC-1](manual/TC-1-LOGIN.md)'
        self.write_run('2026-11-04-abc1234', [('UC-1-P-01', 'PASS')])
        self.write_round('2026-11-05', 'TC-1', 'FAIL')
        self.assertEqual(self.verdict(), ['FAIL', f'manual 2026-11-05 {case}'])
        self.tree.remove(f'{MANUAL}/2026-11-05')
        self.write_round('2026-11-03', 'TC-1', 'FAIL')
        self.assertEqual(self.verdict(), ['PASS', 'auto 2026-11-04-abc1234'])
        self.write_round('2026-11-04', 'TC-1', 'BLOCKED')
        self.assertEqual(self.verdict(), ['BLOCKED', f'manual 2026-11-04 {case}'])
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.assertEqual(self.verdict(), ['PASS', 'auto 2026-11-04-abc1234'])

    def test_manual_round_without_verdict(self):
        self.write_round('2026-11-04', 'TC-1', 'PASS')
        self.write_round('2026-11-05', 'TC-1', None)
        self.assertEqual(self.verdict(), ['НЕ ПРОВЕРЕНО', '—'])

    def test_live_cases_only_and_latest_of_each(self):
        self.tree.write(TC_2, '# TC-2 — вход\n\n'
                              f'Путь UC: {link(TC_2, UC_1, "UC-1-P-01", "uc-1-p-01")}.\n')
        self.write_round('2026-11-04', 'TC-2', 'FAIL')
        self.write_round('2026-11-05', 'TC-1', 'PASS')
        self.assertEqual(self.verdict(), ['PASS', 'manual 2026-11-05 [TC-1](manual/TC-1-LOGIN.md)'])
        self.write_round('2026-11-05', 'TC-2', 'FAIL')
        self.assertEqual(self.verdict(), ['FAIL', 'manual 2026-11-05 [TC-2](manual/TC-2-RESET.md)'])
        bury(self.tree, TC_2)
        self.assertEqual(self.verdict(), ['PASS', 'manual 2026-11-05 [TC-1](manual/TC-1-LOGIN.md)'])
        bury(self.tree, TC_1)
        self.assertEqual(self.verdict(), ['НЕ ПРОВЕРЕНО', '—'])

    def test_rows_and_totals(self):
        self.tree.write(PRD, prd_text(requirement(1, R1_TEXT), requirement(2, R2_TEXT),
                                      requirement(3, 'Ученик выходит.')))
        uc2 = uc_text(2, paths=(('02', 'код'), ('01', 'сброс')), basis=(
            f'{link(UC_2, PRD, "R1", "r1")}, {link(UC_2, PRD, "R2", "r2")}'))
        self.tree.write(UC_2, uc2)
        uc3 = 'sdlc/2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md'
        self.tree.write(uc3, uc_text(3, paths=(), basis=link(uc3, PRD, 'R2', 'r2')))
        self.write_run('2026-11-04-abc1234', [('UC-2-P-01', 'PASS'), ('UC-2-P-02', 'FAIL')])
        uc2_link = '../2-specs/use-cases/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
        uc3_link = '../2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md'
        r1, r2, r3 = (f'[R{n}](../0-vibes/prd/PRD.md#r{n})' for n in (1, 2, 3))
        auto = 'auto 2026-11-04-abc1234'
        self.assertEqual(table_rows(self.dashboard()), [
            [r1, f'[UC-1]({self.UC})', f'[UC-1-P-01]({self.UC}#uc-1-p-01)', 'НЕ ПРОВЕРЕНО', '—'],
            [r1, f'[UC-2]({uc2_link})', f'[UC-2-P-01]({uc2_link}#uc-2-p-01)', 'PASS', auto],
            [r1, f'[UC-2]({uc2_link})', f'[UC-2-P-02]({uc2_link}#uc-2-p-02)', 'FAIL', auto],
            [r2, f'[UC-2]({uc2_link})', f'[UC-2-P-01]({uc2_link}#uc-2-p-01)', 'PASS', auto],
            [r2, f'[UC-2]({uc2_link})', f'[UC-2-P-02]({uc2_link}#uc-2-p-02)', 'FAIL', auto],
            [r2, f'[UC-3]({uc3_link})', '—', 'НЕ ПРОВЕРЕНО: нет путей', '—'],
            [r3, '—', '—', 'НЕ ПРОВЕРЕНО: нет UC', '—'],
        ])
        self.assertIn('\nИтого путей: PASS 1, FAIL 1, BLOCKED 0, НЕ ПРОВЕРЕНО 1.\n',
                      self.dashboard())
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.check(derived=True), [])

    def test_obsolete_requirements(self):
        self.assertIsNone(section(self.dashboard(), 'Устаревшие требования'))
        self.tree.write(PRD, prd_text(requirement(1, R1_TEXT, obsolete_mark(by=2)),
                                      requirement(2, R2_TEXT),
                                      requirement(3, 'Снято.', obsolete_mark())))
        text = self.dashboard()
        self.assertEqual([cells[0] for cells in table_rows(section(text))],
                         ['[R2](../0-vibes/prd/PRD.md#r2)'])
        self.assertEqual(table_rows(section(text, 'Устаревшие требования')), [
            ['[R1](../0-vibes/prd/PRD.md#r1)', '[R2](../0-vibes/prd/PRD.md#r2)'],
            ['[R3](../0-vibes/prd/PRD.md#r3)', 'ничем']])
        self.assertIn('\nИтого путей: PASS 0, FAIL 0, BLOCKED 0, НЕ ПРОВЕРЕНО 0.\n', text)
        views.write_all(self.tree.repo())
        self.assertEqual(self.tree.errors(), [])


class DeterminismTest(ViewsTestCase):
    def build(self, tree: Tree) -> None:
        seed(tree)
        tree.write(UC_2, uc2_text(extra=f'\nsupersedes: {link(UC_2, UC_1, "UC-1")}\n'))
        bury(tree, UC_1, by=('UC-2', UC_2))
        tree.write('lib/app/theme/app_colors.dart', '// TOKEN-1\n')
        tree.write('lib/widgets/b.dart', '// UC-2\n')
        tree.write('lib/widgets/a.dart', '// UC-2\n')
        tree.write(f'{AUTO}/2026-11-04-abc1234/summary.json', json.dumps({
            'date': '2026-11-04', 'started_at': '2026-11-04T10:00:00+03:00',
            'tests': [{'label': 'UC-2-P-01', 'verdict': 'PASS'}]}))

    def test_same_tree_same_output(self):
        self.build(self.tree)
        repo = self.tree.repo()
        first = views.render_all(repo)
        self.assertEqual(views.render_all(repo), first)
        self.assertEqual(self.render(), first)
        for text in first.values():
            self.assertNotIn(self.tree.root, text or '')

    def test_other_write_order_same_output(self):
        self.build(self.tree)
        other = Tree()
        self.addCleanup(other.cleanup)
        files = sorted(self.tree.repo().files + ['lib/app/theme/app_colors.dart',
                                                  'lib/widgets/a.dart', 'lib/widgets/b.dart'])
        for path in reversed(files):
            other.write(path, self.tree.read(path))
        for path in other.repo().files:
            if not self.tree.exists(path):
                other.remove(path)
        self.assertEqual(views.render_all(other.repo()), self.render())


class WriteAllTest(ViewsTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)
        views.write_all(self.tree.repo())

    def test_untouched_when_equal(self):
        path = model.index_path(TASKS)
        os.utime(self.tree.abs(path), (1, 1))
        self.assertEqual(views.write_all(self.tree.repo()), [])
        self.assertEqual(os.stat(self.tree.abs(path)).st_mtime, 1)

    def test_stale_file_rewritten(self):
        path = model.index_path(TASKS)
        expected = self.tree.read(path)
        self.tree.write(path, expected.replace('| да |', '| нет |'))
        self.assertMessage([item.format() for item in self.tree.check(derived=True)],
                           path, 'производный файл устарел')
        self.assertEqual(views.write_all(self.tree.repo()), [path])
        self.assertEqual(self.tree.read(path), expected)

    def test_crlf_compared_like_check(self):
        path = model.index_path(TASKS)
        crlf = self.tree.read(path).replace('\n', '\r\n')
        with open(self.tree.abs(path), 'w', encoding='utf-8', newline='') as handle:
            handle.write(crlf)
        self.assertEqual(self.tree.check(derived=True), [])
        self.assertEqual(views.write_all(self.tree.repo()), [])
        with open(self.tree.abs(path), encoding='utf-8', newline='') as handle:
            self.assertEqual(handle.read(), crlf)

    def test_case_clash(self):
        probe = self.tree.abs('sdlc/4-tasks/probe.txt')
        with open(probe, 'w', encoding='utf-8') as handle:
            handle.write('x')
        insensitive = os.path.exists(self.tree.abs('sdlc/4-tasks/PROBE.TXT'))
        os.remove(probe)
        self.tree.remove(model.index_path(TASKS))
        self.tree.write('sdlc/4-tasks/index.md', 'заметка\n')
        self.tree.remove(DASHBOARD)
        if insensitive:
            with self.assertRaises(model.Refusal) as caught:
                views.write_all(self.tree.repo())
            self.assertIn('sdlc/4-tasks/index.md', str(caught.exception))
            self.assertFalse(self.tree.exists(DASHBOARD))  # не записано ничего
        else:
            self.assertEqual(views.write_all(self.tree.repo()),
                             [model.index_path(TASKS), DASHBOARD])
        self.assertEqual(self.tree.read('sdlc/4-tasks/index.md'), 'заметка\n')


class CliViewsTest(ViewsTestCase):
    def call(self, *argv: str) -> Tuple[int, str]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
            code = main(list(argv))
        return code, out.getvalue()

    def test_views_command(self):
        self.assertEqual(self.call('views', '--root', self.tree.root), (0, ''))
        seed(self.tree)
        code, out = self.call('views', '--root', self.tree.root)
        self.assertEqual((code, out), (0, ''.join(f'обновлено: {path}\n' for path in SEEDED)))
        self.assertEqual(self.call('views', '--root', self.tree.root), (0, ''))
        code, out = self.call('check', '--root', self.tree.root, '--base', 'none')
        self.assertEqual((code, out), (0, 'Итог: 0 ошибок, 0 предупреждений\n'))

