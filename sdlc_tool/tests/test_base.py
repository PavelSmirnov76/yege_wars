"""Тесты раздела «База: что новое»: заморозка, удаление, перенос, требования,
порядок id, новые ссылки и новые метки на похороненное.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

from sdlc_tool import gitbase, model
from sdlc_tool.tests.helpers import (
    ACTOR_1, BT_1, ENT_1, EVT_1, MOD_1, PRD, RESULT_1, TASK_1, UC_1, TreeTestCase,
    bury, link, obsolete_mark, prd_text, requirement, seed, uc_text,
)

UC_2 = 'sdlc/2-specs/use-cases/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
UC_3 = 'sdlc/2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md'
ACTOR_2 = 'sdlc/2-specs/actors/ACTOR-2-TEACHER-IN-AUTH.md'
SNAPSHOT = 'sdlc/0-vibes/prd/history/PRD-2026-11-01.md'

R1_TEXT = 'Ученик входит по логину и паролю.'
R2_TEXT = 'Ученик видит каталог задач.'


class BaseTestCase(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)
        self.tree.commit('мир')

    def errors(self):
        return self.tree.errors('HEAD')

    def warnings(self):
        return self.tree.warnings('HEAD')

    def write_prd(self, *requirements):
        self.tree.write(PRD, prd_text(*requirements))


class FreezeTest(BaseTestCase):
    def test_unchanged(self):
        self.assertEqual(self.tree.check('HEAD'), [])

    def test_changed_text(self):
        self.tree.replace(ACTOR_1, 'Сущность:', 'Сущности:')
        self.assertOnly(self.errors(), f'{ACTOR_1}:3', 'артефакт ACTOR-1 изменён')

    def test_link_paths_may_change(self):
        self.tree.replace(ACTOR_1, '(../entities/', '(../../2-specs/entities/')
        self.assertEqual(self.errors(), [])

    def test_link_text_may_not_change(self):
        self.tree.replace(ACTOR_1, '[ENT-1]', '[EVT-1]')
        self.assertMessage(self.errors(), ACTOR_1, 'артефакт ACTOR-1 изменён')

    def test_burial_is_allowed(self):
        bury(self.tree, UC_1)
        self.assertEqual(self.errors(), [])
        self.assertMessage(self.warnings(), TASK_1, 'похороненный UC-1-P-01')

    def test_buried_body_still_frozen(self):
        new_path = bury(self.tree, ENT_1)
        self.tree.replace(new_path, '# ENT-1 — учётная запись', '# ENT-1 — аккаунт')
        self.assertOnly(self.errors(), f'{new_path}:5', 'артефакт ENT-1 изменён')

    def test_rename_in_place(self):
        renamed = 'sdlc/2-specs/modules/MOD-1-LOGIN.md'
        self.tree.move(MOD_1, renamed)
        errors = self.errors()
        self.assertMessage(errors, renamed, f'артефакт MOD-1 перенесён из {MOD_1}')

    def test_move_to_other_obsolete(self):
        moved = 'sdlc/2-specs/obsolete/MOD-1-AUTH.md'
        self.tree.move(MOD_1, moved)
        self.assertMessage(self.errors(), moved, 'артефакт MOD-1 перенесён из')

    def test_move_back_from_obsolete(self):
        buried = bury(self.tree, ENT_1)
        self.tree.commit('похоронили ENT-1')
        self.tree.write(ENT_1, model.strip_tomb_header(self.tree.read(buried)))
        self.tree.remove(buried)
        self.assertMessage(self.errors(), ENT_1, f'артефакт ENT-1 перенесён из {buried}')

    def test_delete(self):
        self.tree.remove(RESULT_1)
        errors = self.errors()
        self.assertMessage(errors, RESULT_1, 'артефакт RESULT-TASK-1-01 удалён')

    def test_new_artifact_is_a_draft(self):
        self.tree.write(UC_2, uc_text(2))
        self.tree.write(UC_2, uc_text(2, title='сброс пароля'))
        self.assertEqual(self.errors(), [])


class SnapshotFreezeTest(BaseTestCase):
    def setUp(self):
        super().setUp()
        self.tree.write(SNAPSHOT, (
            '> **Сменён:** 2026-11-01\n> **Почему:** новый вход\n'
            f'> **Вход:** {link(SNAPSHOT, "sdlc/0-vibes/raw/2026-11-01", "0-vibes/raw/2026-11-01/")}'
            '\n\n# PRD\n\nСм. [BT-1](../../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md).\n'))
        self.tree.commit('снимок')

    def test_changed(self):
        self.tree.replace(SNAPSHOT, '# PRD', '# PRD (правка)')
        self.assertOnly(self.errors(), f'{SNAPSHOT}:5', 'снимок PRD изменён')

    def test_deleted(self):
        self.tree.remove(SNAPSHOT)
        self.assertOnly(self.errors(), SNAPSHOT, 'снимок PRD удалён')

    def test_link_paths_may_change(self):
        bury(self.tree, BT_1)
        self.assertNotIn('obsolete', self.tree.read(SNAPSHOT).split('[BT-1]')[0])
        self.assertIn('planning/obsolete/BT-1', self.tree.read(SNAPSHOT))
        self.assertEqual(self.errors(), [])


class RequirementFreezeTest(BaseTestCase):
    def test_removed(self):
        self.write_prd(requirement(1, R1_TEXT))
        self.assertOnly(self.errors(), PRD, 'требование R2 пропало из PRD')

    def test_text_changed(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, 'Ученик видит каталог.'))
        self.assertOnly(self.errors(), f'{PRD}:11', 'текст требования R2 изменён')

    def test_mark_may_be_added(self):
        self.write_prd(requirement(1, R1_TEXT, obsolete_mark(by=3)),
                       requirement(2, R2_TEXT, obsolete_mark()),
                       requirement(3, 'Ученик входит по ссылке из письма.'))
        self.assertEqual(self.errors(), [])

    def test_mark_may_not_be_removed_or_changed(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()))
        self.tree.commit('R2 устарело')
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT))
        self.assertOnly(self.errors(), PRD, 'отметку устаревания R2 сняли или изменили')
        self.write_prd(requirement(1, R1_TEXT),
                       requirement(2, R2_TEXT, obsolete_mark(date='2026-11-03')))
        self.assertOnly(self.errors(), PRD, 'отметку устаревания R2 сняли или изменили')

    def test_link_paths_in_requirement_may_change(self):
        text = f'Как в {link(PRD, BT_1, "BT-1")}.'
        self.write_prd(requirement(1, R1_TEXT), requirement(2, text))
        self.tree.commit('ссылка в R2')
        self.write_prd(requirement(1, R1_TEXT),
                       requirement(2, text.replace('(../../', '(../../../sdlc/')))
        self.assertEqual(self.errors(), [])


class IdOrderTest(BaseTestCase):
    def test_artifact_numbers(self):
        self.tree.write(UC_3, uc_text(3))
        self.tree.commit('UC-3')
        self.tree.write(UC_2, uc_text(2))
        self.assertOnly(self.errors(), UC_2, 'новый id UC-2 не больше наибольшего в базе UC-3')

    def test_greater_number_is_fine(self):
        self.tree.write(UC_3, uc_text(3))
        self.assertEqual(self.errors(), [])

    def test_buried_numbers_count(self):
        bury(self.tree, ACTOR_1)
        self.tree.commit('похоронили ACTOR-1')
        # Номер 1 занят похороненным: новый ACTOR-1 рядом — тот же id, а не новый.
        self.tree.write('sdlc/2-specs/actors/ACTOR-1-PUPIL-IN-AUTH.md', '# ACTOR-1\n')
        self.assertMessage(self.errors(), 'sdlc/2-specs/actors/ACTOR-1-PUPIL-IN-AUTH.md',
                           'id ACTOR-1 у нескольких файлов')

    def test_results_per_task(self):
        self.tree.write('sdlc/5-results/RESULT-TASK-1-03.md', f'{link(RESULT_1, TASK_1, "TASK-1")}\n')
        self.tree.commit('сдача 03')
        late = 'sdlc/5-results/RESULT-TASK-1-02.md'
        self.tree.write(late, '# сдача\n')
        self.tree.write('sdlc/4-tasks/TASK-2-CATALOG.md', '# TASK-2\n')
        self.tree.write('sdlc/5-results/RESULT-TASK-2-01.md', '# сдача\n')
        self.assertOnly(self.errors(), late,
                        'новый id RESULT-TASK-1-02 не больше наибольшего в базе RESULT-TASK-1-03')

    def test_acceptances_per_task(self):
        for name in ('RESULT-TASK-1-02.md', 'RESULT-TASK-1-03.md'):
            self.tree.write(f'sdlc/5-results/{name}', '# сдача\n')
        self.tree.write('sdlc/6-eval/acceptance/ACC-TASK-1-03.md', '**Вердикт:** возврат\n')
        self.tree.commit('сдачи и приёмка 03')
        late = 'sdlc/6-eval/acceptance/ACC-TASK-1-02.md'
        self.tree.write(late, '**Вердикт:** возврат\n')
        self.assertOnly(self.errors(), late,
                        'новый id ACC-TASK-1-02 не больше наибольшего в базе ACC-TASK-1-03')

    def test_requirement_numbers(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT), requirement(4, 'Четвёртое.'))
        self.tree.commit('R4')
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT), requirement(4, 'Четвёртое.'),
                       requirement(3, 'Третье.'))
        self.assertOnly(self.errors(), PRD, 'новое требование R3 не больше наибольшего в базе R4')


class NewLinkTest(BaseTestCase):
    def test_new_artifact_to_buried(self):
        buried = bury(self.tree, ENT_1)
        self.tree.commit('похоронили ENT-1')
        self.tree.write(ACTOR_2, f'# ACTOR-2\n\n{link(ACTOR_2, buried, "ENT-1")}\n')
        self.assertOnly(self.errors(), f'{ACTOR_2}:3', 'новая ссылка ведёт на похороненный ENT-1')
        self.assertFalse([item for item in self.warnings() if ACTOR_2 in item])

    def test_new_artifact_to_obsolete_requirement(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()))
        self.tree.commit('R2 устарело')
        self.tree.write(UC_2, uc_text(2, basis=link(UC_2, PRD, 'R2', 'r2')))
        self.assertOnly(self.errors(), UC_2, 'новая ссылка ведёт на устаревшее требование R2')

    def test_supersedes_link_is_fine(self):
        self.tree.write(UC_2, uc_text(2) + f'\nsupersedes: {link(UC_2, UC_1, "UC-1")}\n')
        bury(self.tree, UC_1, by=('UC-2', UC_2))
        self.assertEqual(self.errors(), [])

    def test_prd_added_line(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()))
        self.tree.commit('R2 устарело')
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()),
                       requirement(3, 'Как [R2](#r2), но для учителя.'))
        self.assertOnly(self.errors(), f'{PRD}:13', 'новая ссылка ведёт на устаревшее требование R2')

    def test_prd_old_line(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT),
                       requirement(3, 'Как [R2](#r2), но для учителя.'))
        self.tree.commit('R3')
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()),
                       requirement(3, 'Как [R2](#r2), но для учителя.'))
        self.assertEqual(self.errors(), [])

    def test_prd_line_with_new_mark_only(self):
        self.write_prd(requirement(1, 'Вход как [R2](#r2).'), requirement(2, R2_TEXT))
        self.tree.commit('R1 ссылается на R2')
        self.write_prd(requirement(1, 'Вход как [R2](#r2).', obsolete_mark(by=3)),
                       requirement(2, R2_TEXT, obsolete_mark()),
                       requirement(3, 'Вход по ссылке.'))
        self.assertEqual(self.errors(), [])

    def test_prd_new_mark_to_obsolete(self):
        self.write_prd(requirement(1, R1_TEXT), requirement(2, R2_TEXT, obsolete_mark()))
        self.tree.commit('R2 устарело')
        self.write_prd(requirement(1, R1_TEXT, obsolete_mark(by=2)),
                       requirement(2, R2_TEXT, obsolete_mark()))
        self.assertOnly(self.errors(), f'{PRD}:9', 'новая ссылка ведёт на устаревшее требование R2')


class NewLabelTest(BaseTestCase):
    FEATURE = 'lib/feature.dart'

    def setUp(self):
        super().setUp()
        self.tree.write(self.FEATURE, '// UC-1\nvoid f() {}\n')
        self.tree.commit('метка')
        bury(self.tree, UC_1)

    def test_old_label_is_warning(self):
        self.assertEqual(self.errors(), [])
        self.assertMessage(self.warnings(), f'{self.FEATURE}:1', 'метка UC-1 ведёт на похороненный UC-1')

    def test_added_line(self):
        self.tree.write(self.FEATURE, '// UC-1\nvoid f() {}\n// UC-1-P-01\n')
        self.assertOnly(self.errors(), f'{self.FEATURE}:3',
                        'новая метка UC-1-P-01 ведёт на похороненный UC-1')

    def test_changed_line(self):
        self.tree.write(self.FEATURE, '// UC-1: вход\nvoid f() {}\n')
        self.assertOnly(self.errors(), f'{self.FEATURE}:1', 'новая метка UC-1')

    def test_untracked_file(self):
        self.tree.write('test/new_test.dart', "test('UC-1-P-01: вход', () {});\n")
        self.assertOnly(self.errors(), 'test/new_test.dart:1', 'новая метка UC-1-P-01')

    def test_without_base(self):
        self.tree.write('test/new_test.dart', "test('UC-1-P-01: вход', () {});\n")
        self.assertEqual(self.tree.errors(None), [])
        self.assertMessage(self.tree.warnings(None), 'test/new_test.dart:1', 'к пересмотру')


class BaseRefTest(TreeTestCase):
    def test_unknown_base(self):
        with self.assertRaises(model.Refusal) as caught:
            self.tree.check('nope')
        self.assertEqual(caught.exception.code, 2)
        self.assertIn('база nope недоступна', str(caught.exception))

    def test_without_base_deletion_is_not_checked(self):
        seed(self.tree)
        self.tree.commit('мир')
        self.tree.remove(RESULT_1)
        self.tree.write('sdlc/6-eval/acceptance/ACC-TASK-1-01.md', '**Вердикт:** принято\n')
        errors = self.tree.errors(None)
        self.assertMessage(errors, 'sdlc/6-eval/acceptance/ACC-TASK-1-01.md', 'нет сдачи')
        self.assertFalse([item for item in errors if 'удалён' in item])

    def test_base_is_any_commit(self):
        seed(self.tree)
        first = self.tree.commit('мир')
        self.tree.replace(EVT_1, 'Сущность:', 'Сущности:')
        self.tree.commit('правка EVT-1')
        self.assertEqual(self.tree.errors('HEAD'), [])
        self.assertMessage(self.tree.errors(first), EVT_1, 'артефакт EVT-1 изменён')


class GitBaseTest(TreeTestCase):
    def test_sources_and_added_lines(self):
        seed(self.tree)
        self.tree.write('lib/a.dart', 'один\nдва\n')
        commit = self.tree.commit('мир')
        self.tree.write('lib/a.dart', 'один\nновая\nдва\nещё\n')
        self.tree.write('lib/b.dart', 'x\ny\n')
        self.tree.move('lib/main.dart', 'lib/app.dart')
        added = gitbase.added_lines(self.tree.root, 'HEAD')
        self.assertEqual(added['lib/a.dart'], {2, 4})
        self.assertEqual(added['lib/b.dart'], {1, 2})
        self.assertNotIn('lib/app.dart', added)  # перенос без правки — не новые строки
        source = gitbase.GitSource(self.tree.root, 'HEAD')
        self.assertEqual(source.commit, commit)
        files, dirs = source.walk_sdlc()
        self.assertIn(UC_1, files)
        self.assertIn('sdlc/2-specs/use-cases', dirs)
        self.assertEqual(source.read(UC_1), self.tree.read(UC_1))
        self.assertTrue(source.exists('sdlc/2-specs') and source.is_dir('sdlc/2-specs'))
        self.assertFalse(source.exists('lib/b.dart'))
        self.assertEqual(source.code_files(), ['lib/a.dart', 'lib/main.dart'])
        base = model.load_base(self.tree.root, commit)
        self.assertEqual([item.id for item in base.of_type('UC')], ['UC-1'])
        self.assertEqual([item.id for item in base.requirements], ['R1', 'R2'])
        with self.assertRaises(FileNotFoundError):
            source.read('sdlc/nope.md')

    def test_staged_move_with_edit(self):
        self.tree.write('lib/a.dart', ''.join(f'строка {index}\n' for index in range(20)))
        self.tree.commit('файл')
        self.tree.git('mv', 'lib/a.dart', 'lib/b.dart')
        self.tree.write('lib/b.dart', self.tree.read('lib/b.dart') + '// UC-1\n')
        self.tree.git('add', 'lib/b.dart')
        self.assertEqual(gitbase.added_lines(self.tree.root, 'HEAD'), {'lib/b.dart': {21}})
