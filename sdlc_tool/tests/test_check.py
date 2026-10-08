"""Тесты `check` без базы: ошибки 1–12, предупреждения, формат сообщений.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import io
import os
from unittest import mock

from sdlc_tool import check, model
from sdlc_tool.tests.helpers import (
    ACC_1, ACTOR_1, BT_1, COMP_1, ENT_1, EVT_1, FIG_1, MOD_1, PRD, RAW_DAY, TASK_1,
    TC_1, TOKEN_1, UC_1, TreeTestCase, bury, link, obsolete_mark, prd_text,
    requirement, seed, uc_text,
)

UC_2 = 'sdlc/2-specs/use-cases/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'


class CleanTreeTest(TreeTestCase):
    def test_empty_tree(self):
        self.assertEqual(self.tree.check(), [])

    def test_seeded_world(self):
        seed(self.tree)
        self.assertEqual([item.format() for item in self.tree.check()], [])

    def test_no_sdlc(self):
        self.tree.remove('sdlc')
        self.assertOnly(self.tree.errors(), 'sdlc/', 'нет папки sdlc/')


class StructureTest(TreeTestCase):
    def test_structure_folder_needs_conventions(self):
        self.tree.write('sdlc/2-specs/extra/notes.md', 'заметка\n')
        self.assertOnly(self.tree.errors(), 'sdlc/2-specs/extra/',
                        'в папке структуры нет README.md, AGENTS.md, CLAUDE.md')
        self.tree.write('sdlc/2-specs/extra/README.md', '# extra\n')
        self.assertOnly(self.tree.errors(), 'sdlc/2-specs/extra/',
                        'в папке структуры нет AGENTS.md, CLAUDE.md')
        self.tree.remove('sdlc/2-specs/extra')
        os.makedirs(self.tree.abs('sdlc/2-specs/empty'))
        self.assertEqual(self.tree.errors(), [])  # пустой папки нет и в git

    def test_raw_folder_without_date_is_structure(self):
        self.tree.write('sdlc/0-vibes/raw/misc/a.md', 'x\n')
        self.assertOnly(self.tree.errors(), 'sdlc/0-vibes/raw/misc/', 'в папке структуры нет')
        self.tree.remove('sdlc/0-vibes/raw/misc')
        self.tree.write('sdlc/0-vibes/raw/2026-11-01/a.md', 'x\n')
        self.tree.write('sdlc/6-eval/auto/2026-11-01-abc1234/summary.md', 'x\n')
        self.tree.write('sdlc/6-eval/manual/2026-11-01/TC-1/transcript.md', '**Вердикт:** PASS\n')
        self.assertEqual(self.tree.errors(), [])

    def test_content_folder_without_conventions(self):
        self.tree.write('sdlc/0-vibes/raw/2026-11-01/README.md', '# x\n')
        self.tree.write('sdlc/2-specs/actors/obsolete/AGENTS.md', 'x\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, 'sdlc/0-vibes/raw/2026-11-01/README.md',
                           'в папке содержимого не должно быть README.md')
        self.assertMessage(errors, 'sdlc/2-specs/actors/obsolete/AGENTS.md',
                           'в папке содержимого не должно быть AGENTS.md')

    def test_grammar_in_artifact_folder(self):
        seed(self.tree)
        self.tree.write('sdlc/2-specs/actors/student.md', 'x\n')
        self.tree.write('sdlc/2-specs/actors/obsolete/ACTOR-2-PUPIL.md', 'x\n')
        self.tree.write('sdlc/2-specs/actors/INDEX.md', 'x\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, 'sdlc/2-specs/actors/student.md',
                           'файл в папке артефактов не по грамматике имени')
        self.assertMessage(errors, 'sdlc/2-specs/actors/obsolete/ACTOR-2-PUPIL.md', '-IN-')

    def test_artifact_in_wrong_folder(self):
        seed(self.tree)
        path = 'sdlc/2-specs/actors/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
        self.tree.write(path, uc_text(2))
        self.assertOnly(self.tree.errors(), path,
                        'артефакт UC-2 не в своей папке: его место — sdlc/2-specs/use-cases/')

    def test_business_task_type_must_match_folder(self):
        path = 'sdlc/1-business-tasks/observation/errors/BT-2-WARNING-SLOW.md'
        self.tree.write(path, '# BT-2\n')
        self.assertOnly(self.tree.errors(), path,
                        'у бизнес-задачи тип WARNING, а папка '
                        '1-business-tasks/observation/errors/ — для ERROR')
        self.tree.remove(path)
        path = 'sdlc/1-business-tasks/BT-3-ERROR-CRASH.md'
        self.tree.write(path, '# BT-3\n')
        self.assertOnly(self.tree.errors(), path,
                        'его место — sdlc/1-business-tasks/observation/errors/')

    def test_artifact_like_names_outside_artifact_folders(self):
        seed(self.tree)
        self.tree.write(f'{RAW_DAY}/UC-3-feedback.md', 'x\n')
        self.tree.write('sdlc/2-specs/obsolete/MOD-2-CATALOG.md',
                        '> **Похоронен:** 2026-11-02\n> **Почему:** x\n'
                        '> **Заменён:** ничем\n\n# MOD-2\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, f'{RAW_DAY}/UC-3-feedback.md', 'имя похоже на id артефакта')
        self.assertMessage(errors, 'sdlc/2-specs/obsolete/MOD-2-CATALOG.md',
                           'артефакт MOD-2 не в своей папке')

    def test_history_names(self):
        history = 'sdlc/0-vibes/prd/history'
        self.tree.write(f'{history}/PRD-2026-11-01.md', '# PRD\n')
        self.tree.write(f'{history}/PRD-2026-11-01-02.md', '# PRD\n')
        self.tree.write(f'{history}/PRD-old.md', '# PRD\n')
        self.assertOnly(self.tree.errors(), f'{history}/PRD-old.md', 'только снимки')


class DuplicateIdTest(TreeTestCase):
    def test_two_files_one_id(self):
        seed(self.tree)
        other = 'sdlc/2-specs/actors/ACTOR-1-PUPIL-IN-AUTH.md'
        self.tree.write(other, '# ACTOR-1\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, ACTOR_1, f'id ACTOR-1 у нескольких файлов: ещё {other}')
        self.assertMessage(errors, other, f'id ACTOR-1 у нескольких файлов: ещё {ACTOR_1}')

    def test_live_and_buried_copy(self):
        seed(self.tree)
        copy = 'sdlc/2-specs/modules/obsolete/MOD-1-AUTH.md'
        self.tree.write(copy, '> **Похоронен:** 2026-11-02\n> **Почему:** x\n'
                              '> **Заменён:** ничем\n\n# MOD-1\n')
        errors = self.tree.errors()
        self.assertMessage(errors, MOD_1, 'id MOD-1 у нескольких файлов')
        self.assertMessage(errors, copy, 'id MOD-1 у нескольких файлов')


class NameReferencesTest(TreeTestCase):
    def test_module_must_exist(self):
        seed(self.tree)
        path = 'sdlc/2-specs/actors/ACTOR-2-TEACHER-IN-CATALOG.md'
        self.tree.write(path, '# ACTOR-2\n')
        self.assertOnly(self.tree.errors(), path,
                        '-IN-CATALOG не ведёт на модуль: нет файла MOD-*-CATALOG.md')

    def test_buried_module_still_counts(self):
        seed(self.tree)
        bury(self.tree, MOD_1)
        self.assertEqual(self.tree.errors(), [])

    def test_uc_name_references(self):
        seed(self.tree)
        path = 'sdlc/2-specs/use-cases/UC-2-ACTOR-5-EVT-1-ENT-7-RESET-IN-AUTH.md'
        self.tree.write(path, uc_text(2))
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, path, 'в имени UC — несуществующий ACTOR-5')
        self.assertMessage(errors, path, 'в имени UC — несуществующий ENT-7')

    def test_result_and_acceptance_owners(self):
        seed(self.tree)
        result = 'sdlc/5-results/RESULT-TASK-9-01.md'
        acceptance = 'sdlc/6-eval/acceptance/ACC-TASK-1-02.md'
        self.tree.write(result, '# RESULT-TASK-9-01\n')
        self.tree.write(acceptance, '# ACC\n\n**Вердикт:** принято\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, result, 'нет задания TASK-9')
        self.assertMessage(errors, acceptance, 'нет сдачи RESULT-TASK-1-02 с тем же номером')


class RequirementCheckTest(TreeTestCase):
    def test_requirement_errors(self):
        self.tree.write(PRD, prd_text(
            requirement(1, 'Первое.'),
            requirement(1, 'Повтор.'),
            requirement(2, 'Устаревшее.', obsolete_mark(by=9)),
            '<a id="r3"></a>**R4.** Разные номера.',
        ))
        errors = self.tree.errors()
        self.assertEqual(len(errors), 4, errors)
        self.assertMessage(errors, PRD, 'номер R1 повторён')
        self.assertMessage(errors, PRD, 'R2 заменено R9, а такого требования нет')
        self.assertMessage(errors, PRD, f'нет якоря #r9 в {PRD}')
        self.assertMessage(errors, PRD, 'номер в якоре r3 и в тексте R4 разный')

    def test_mark_format(self):
        self.tree.write(PRD, prd_text(
            requirement(1, 'Старое.', ' **Устарело 2026-11-02, заменено R2.**'),
            requirement(2, 'Новое.')))
        self.assertOnly(self.tree.errors(), PRD, 'отметка устаревания R1 не по формату')

    def test_obsolete_requirement_with_replacement(self):
        self.tree.write(PRD, prd_text(
            requirement(1, 'Старое.', obsolete_mark(by=2)), requirement(2, 'Новое.')))
        self.assertEqual(self.tree.errors(), [])


class UcPathCheckTest(TreeTestCase):
    def test_path_errors_reported(self):
        seed(self.tree)
        self.tree.replace(UC_1, '**Исход:** UC-1-O-01', '**Исход:** UC-1-O-02')
        self.assertOnly(self.tree.errors(), UC_1, 'исход UC-1-O-02 не совпадает с путём UC-1-P-01')


class LinkCheckTest(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def add(self, path, line):
        self.tree.write(path, self.tree.read(path) + '\n' + line + '\n')

    def test_missing_target(self):
        self.add(MOD_1, '[раздел](../nope.md)')
        self.assertOnly(self.tree.errors(), MOD_1, 'цель ссылки не существует: ../nope.md')

    def test_artifact_link_text_is_id(self):
        self.add(MOD_1, f'{link(MOD_1, ACTOR_1, "ACTOR-4")} и {link(MOD_1, ENT_1, "учётная запись")}')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, MOD_1, 'текст ссылки ACTOR-4, а ведёт она на ACTOR-1')
        self.assertMessage(errors, MOD_1, 'текст ссылки учётная запись, а ведёт она на ENT-1')

    def test_uc_path_link_text(self):
        self.add(TASK_1, link(TASK_1, UC_1, 'UC-1', 'uc-1-p-01'))
        self.assertOnly(self.tree.errors(), TASK_1,
                        'текст ссылки UC-1, а ведёт она на UC-1-P-01')

    def test_anchor_must_exist(self):
        self.add(COMP_1, link(COMP_1, TOKEN_1, 'TOKEN-1', 'missing'))
        self.add(TASK_1, link(TASK_1, UC_1, 'UC-1-P-07', 'uc-1-p-07'))
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, COMP_1, f'нет якоря #missing в {TOKEN_1}')
        self.assertMessage(errors, TASK_1, f'нет якоря #uc-1-p-07 в {UC_1}')

    def test_requirement_links(self):
        self.add(BT_1, f'{link(BT_1, PRD, "R2", "r1")} {link(BT_1, PRD, "R5", "r5")}')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, BT_1, 'текст ссылки R2, а ведёт она на R1')
        self.assertMessage(errors, BT_1, f'нет якоря #r5 в {PRD}')

    def test_id_like_text_elsewhere(self):
        self.add(MOD_1, f'{link(MOD_1, PRD, "R1")} {link(MOD_1, "sdlc/README.md", "UC-1")}')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, MOD_1, 'текст ссылки R1 похож на id')
        self.assertMessage(errors, MOD_1, 'текст ссылки UC-1 похож на id')

    def test_requirement_link_only_into_current_prd(self):
        snapshot = 'sdlc/0-vibes/prd/history/PRD-2026-11-01.md'
        self.tree.write(snapshot, prd_text(requirement(1, 'Ученик входит.')))
        self.add(MOD_1, link(MOD_1, snapshot, 'R1', 'r1'))
        self.assertOnly(self.tree.errors(), MOD_1, 'текст ссылки R1 похож на id')

    def test_not_checked(self):
        self.add(MOD_1, '`[R9](nope.md)` [сайт](https://example.invalid/x) [почта](mailto:a@b.c)')
        self.add(MOD_1, '```\n[R9](nope.md)\n```')
        self.tree.write(f'{RAW_DAY}/copy.md', '[R9](nope.md)\n')
        self.tree.write('sdlc/6-eval/auto/run/summary.md', '[R9](nope.md)\n')
        self.tree.write('sdlc/6-eval/manual/2026-11-01/TC-1/transcript.md',
                        '**Вердикт:** PASS\n[R9](nope.md)\n')
        self.assertEqual(self.tree.errors(), [])

    def test_rule_files_are_checked(self):
        self.add('sdlc/2-specs/AGENTS.md', '[README](nope.md)')
        self.assertOnly(self.tree.errors(), 'sdlc/2-specs/AGENTS.md', 'цель ссылки не существует')

    def test_targets_folder_root_and_case(self):
        self.add(MOD_1, '[raw](../../0-vibes/raw/2026-11-01/) [закон](/sdlc/AGENTS.md)')
        self.assertEqual(self.tree.errors(), [])
        self.add(MOD_1, '[MOD-1](mod-1-auth.md) [x](../../../../../../x.md)')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, MOD_1, 'цель ссылки не существует: mod-1-auth.md')


class StaleWarningTest(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def test_link_to_buried_artifact(self):
        bury(self.tree, ENT_1)
        self.assertEqual(self.tree.errors(), [])
        warnings = self.tree.warnings()
        self.assertEqual(len(warnings), 2, warnings)
        self.assertMessage(warnings, ACTOR_1, 'ссылается на похороненный ENT-1 — к пересмотру')
        self.assertMessage(warnings, EVT_1, 'ссылается на похороненный ENT-1 — к пересмотру')

    def test_link_to_obsolete_requirement(self):
        self.tree.write(PRD, prd_text(
            requirement(1, 'Ученик входит по логину и паролю.', obsolete_mark()),
            requirement(2, 'Ученик видит каталог задач.')))
        warnings = self.tree.warnings()
        self.assertEqual(len(warnings), 2, warnings)
        self.assertMessage(warnings, BT_1, 'ссылается на устаревшее требование R1 — к пересмотру')
        self.assertMessage(warnings, UC_1, 'ссылается на устаревшее требование R1')

    def test_supersedes_is_not_stale(self):
        self.tree.write(UC_2, uc_text(2) + f'\nsupersedes: {link(UC_2, UC_1, "UC-1")}\n')
        bury(self.tree, UC_1, by=('UC-2', UC_2))
        self.assertEqual(self.tree.errors(), [])
        warnings = self.tree.warnings()
        self.assertFalse([item for item in warnings if UC_2 in item], warnings)
        self.assertMessage(warnings, TASK_1, 'ссылается на похороненный UC-1-P-01')


class LabelCheckTest(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def test_valid_labels(self):
        self.tree.write('lib/app/theme/app_colors.dart', '// TOKEN-1\n')
        self.tree.write('lib/widgets/button.dart', '// COMP-1\n// UC-1\n')
        self.tree.write('test/login_test.dart', "test('UC-1-P-01: вход', () {});\n")
        self.tree.write('supabase/tests/rls.sql', '-- UC-1-P-01\n')
        self.assertEqual(self.tree.check(), [])

    def test_missing_targets(self):
        self.tree.write('lib/a.dart', '// UC-7\n// TOKEN-9\n// COMP-9\n// UC-1-P-07\n// UC-01\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 5, errors)
        self.assertMessage(errors, 'lib/a.dart:1', 'метка UC-7 ведёт на несуществующий UC')
        self.assertMessage(errors, 'lib/a.dart:2', 'метка TOKEN-9 ведёт на несуществующий токен')
        self.assertMessage(errors, 'lib/a.dart:3', 'метка COMP-9 ведёт на несуществующий компонент')
        self.assertMessage(errors, 'lib/a.dart:4', 'метка UC-1-P-07 ведёт на несуществующий путь UC')
        self.assertMessage(errors, 'lib/a.dart:5', 'метка UC-01 ведёт на несуществующий UC')

    def test_files_without_labels(self):
        for path in ('lib/a.g.dart', 'lib/l10n/gen/app.dart', 'lib/a.txt', 'docs/a.dart',
                     'tools/a.py', 'lib/ignored.dart'):
            self.tree.write(path, '// UC-7\n')
        self.tree.write('.gitignore', 'lib/ignored.dart\n')
        self.assertEqual(self.tree.errors(), [])

    def test_old_label_to_buried(self):
        self.tree.write('lib/a.dart', '// UC-1\n')
        bury(self.tree, UC_1)
        self.assertMessage(self.tree.warnings(), 'lib/a.dart:1',
                           'метка UC-1 ведёт на похороненный UC-1 — к пересмотру')


class AcceptanceCheckTest(TreeTestCase):
    def test_verdict_line(self):
        seed(self.tree)
        self.tree.replace(ACC_1, '**Вердикт:** принято', 'Вердикт: да')
        self.assertOnly(self.tree.errors(), ACC_1, 'строка вердикта не по формату')
        self.tree.replace(ACC_1, 'Вердикт: да', 'Всё хорошо.')
        self.assertOnly(self.tree.errors(), ACC_1, 'нет строки вердикта')


class SupersedesCheckTest(TreeTestCase):
    def setUp(self):
        super().setUp()
        seed(self.tree)

    def write_uc2(self, extra=''):
        self.tree.write(UC_2, uc_text(2) + f'\nsupersedes: {link(UC_2, UC_1, "UC-1")}\n' + extra)

    def test_consistent_pair(self):
        self.write_uc2()
        bury(self.tree, UC_1, by=('UC-2', UC_2))
        self.assertEqual(self.tree.errors(), [])

    def test_supersedes_live(self):
        self.write_uc2()
        self.assertOnly(self.tree.errors(), UC_2, 'supersedes ведёт на живой UC-1')

    def test_supersedes_nothing(self):
        self.tree.write(UC_2, uc_text(2) + '\nsupersedes: [UC-1](nope.md)\n')
        errors = self.tree.errors()
        self.assertMessage(errors, UC_2, 'supersedes ведёт на несуществующий артефакт: nope.md')

    def test_header_says_nothing(self):
        self.write_uc2()
        bury(self.tree, UC_1)
        self.assertOnly(self.tree.errors(), UC_2, 'supersedes: UC-1, а в шапке UC-1 «Заменён: ничем»')

    def test_header_without_supersedes(self):
        self.tree.write(UC_2, uc_text(2))
        new_path = bury(self.tree, UC_1, by=('UC-2', UC_2))
        self.assertOnly(self.tree.errors(), new_path,
                        '«Заменён: UC-2», а у UC-2 нет строки supersedes: [UC-1](…)')

    def test_buried_without_header(self):
        moved = 'sdlc/2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md'
        bury(self.tree, ENT_1)
        text = self.tree.read(moved)
        self.tree.write(moved, model.strip_tomb_header(text))
        self.assertOnly(self.tree.errors(), moved, 'у похороненного нет шапки')
        self.tree.write(moved, '> **Похоронен:** вчера\n> **Почему:** x\n> **Заменён:** ничем\n\n'
                        + model.strip_tomb_header(text))
        self.assertOnly(self.tree.errors(), moved, 'шапка похороненного не по формату')

    def test_live_with_header(self):
        self.tree.write(ENT_1, '> **Похоронен:** 2026-11-02\n> **Почему:** x\n'
                               '> **Заменён:** ничем\n\n' + self.tree.read(ENT_1))
        self.assertOnly(self.tree.errors(), ENT_1, 'у живого артефакта шапка похороненного')

    def test_bad_supersedes_line(self):
        self.tree.write(UC_2, uc_text(2) + '\nsupersedes: UC-1\n')
        self.assertOnly(self.tree.errors(), UC_2, 'строка supersedes не по формату')


class ImportCheckTest(TreeTestCase):
    def test_imports(self):
        self.tree.write('sdlc/2-specs/CLAUDE.md',
                        '<!-- x -->\n@AGENTS.md\n@../AGENTS.md\n@../NOPE.md\n@../2-specs\n'
                        '@~/x.md\n```\n@nope.md\n```\n')
        errors = self.tree.errors()
        self.assertEqual(len(errors), 2, errors)
        self.assertMessage(errors, 'sdlc/2-specs/CLAUDE.md:4', 'импорт @../NOPE.md не разрешается')
        self.assertMessage(errors, 'sdlc/2-specs/CLAUDE.md:5', 'импорт @../2-specs не разрешается')


class FigValueCheckTest(TreeTestCase):
    def test_values_instead_of_tokens(self):
        seed(self.tree)
        self.tree.write(FIG_1, self.tree.read(FIG_1) + '\n'.join([
            'Фон #1E1E1E, рамка #abc, тень #11223344.',
            'Отступ 16px, поле 8 dp, шрифт 14sp, линия 1.5pt.',
            'В коде можно: `#1E1E1E`, `16px`; ссылки тоже: [x](https://e.x/#ffffff/16px).',
            'Не значения: R2D2, h1, #1E1E1EE, &#123;, 360pxx, v16px.', '']))
        errors = self.tree.errors()
        self.assertEqual(len(errors), 7, errors)
        for value in ('#1E1E1E', '#abc', '#11223344', '16px', '8 dp', '14sp', '1.5pt'):
            self.assertMessage(errors, FIG_1, f'значение {value} вместо токена')

    def test_only_screens(self):
        seed(self.tree)
        self.tree.write(COMP_1, self.tree.read(COMP_1) + 'Радиус 8px, цвет #FFFFFF.\n')
        self.assertEqual(self.tree.errors(), [])


class DerivedCheckTest(TreeTestCase):
    INDEX = 'sdlc/2-specs/use-cases/INDEX.md'
    STRAY = 'sdlc/2-specs/INDEX.md'

    def test_skipped_while_views_missing(self):
        with mock.patch('sdlc_tool.views.render_all', side_effect=NotImplementedError('нет')):
            messages = self.tree.check(derived=True)
        self.assertEqual([item.format() for item in messages],
                         ['ПРЕДУПРЕЖДЕНИЕ sdlc_tool/views.py: проверка производных файлов (12) '
                          'пропущена: views.render_all ещё не реализован'])

    def test_compares_with_render(self):
        actors = 'sdlc/2-specs/actors/INDEX.md'
        events = 'sdlc/2-specs/events/INDEX.md'
        self.tree.write(self.INDEX, 'a\nb\nc\n')
        self.tree.write(actors, 'лишний\n')
        self.tree.write(self.STRAY, 'лишний\n')
        self.tree.write(model.DASHBOARD_PATH, 'x\n')
        expected = {self.INDEX: 'a\nB\nc\n', actors: None, events: 'нужен\n',
                    model.DASHBOARD_PATH: 'x\n'}
        with mock.patch('sdlc_tool.views.render_all', return_value=expected) as render:
            errors = [item.format() for item in self.tree.check(derived=True)]
        render.assert_called_once()
        self.assertEqual(len(errors), 4, errors)
        self.assertMessage(errors, f'{self.INDEX}:2', 'производный файл устарел')
        self.assertMessage(errors, actors, 'лишний производный файл')
        self.assertMessage(errors, self.STRAY, 'лишний производный файл')
        self.assertMessage(errors, events, 'производного файла нет')


class SizeWarningTest(TreeTestCase):
    def test_prd_length(self):
        self.tree.write(PRD, '# PRD\n' + 'строка\n' * 299)
        self.assertEqual(self.tree.warnings(), [])
        self.tree.write(PRD, '# PRD\n' + 'строка\n' * 300)
        self.assertEqual(self.tree.warnings(),
                         [f'ПРЕДУПРЕЖДЕНИЕ {PRD}: 301 строка — пора разбивать'])

    def test_rules_length(self):
        self.tree.write('sdlc/AGENTS.md', 'правило\n' * 299)
        self.tree.write('sdlc/2-specs/README.md', 'текст\n' * 299)
        self.assertEqual(self.tree.warnings(), [])
        self.tree.write('sdlc/AGENTS.md', 'правило\n' * 300)
        self.tree.write('sdlc/2-specs/README.md', 'текст\n' * 302)
        warnings = self.tree.warnings()
        self.assertEqual(warnings, [
            'ПРЕДУПРЕЖДЕНИЕ sdlc/2-specs/README.md: 302 строки — пора сокращать',
            'ПРЕДУПРЕЖДЕНИЕ sdlc/AGENTS.md: 300 строк — пора сокращать',
        ])


class MessageTest(TreeTestCase):
    def test_format_and_order(self):
        messages = [
            check.Message(check.WARNING, 'b.md', 0, 'текст'),
            check.Message(check.ERROR, 'a.md', 12, 'б'),
            check.Message(check.ERROR, 'a.md', 12, 'а'),
            check.Message(check.ERROR, 'a.md', 3, 'в'),
        ]
        ordered = sorted(messages, key=lambda item: item.sort_key)
        self.assertEqual([item.format() for item in ordered], [
            'ОШИБКА a.md:3: в', 'ОШИБКА a.md:12: а', 'ОШИБКА a.md:12: б',
            'ПРЕДУПРЕЖДЕНИЕ b.md: текст'])

    def test_summary_plurals(self):
        def summary(errors, warnings):
            return check.summary_line(
                [check.Message(check.ERROR, 'a', 0, str(i)) for i in range(errors)]
                + [check.Message(check.WARNING, 'a', 0, str(i)) for i in range(warnings)])
        self.assertEqual(summary(0, 0), 'Итог: 0 ошибок, 0 предупреждений')
        self.assertEqual(summary(1, 1), 'Итог: 1 ошибка, 1 предупреждение')
        self.assertEqual(summary(2, 3), 'Итог: 2 ошибки, 3 предупреждения')
        self.assertEqual(summary(5, 11), 'Итог: 5 ошибок, 11 предупреждений')
        self.assertEqual(summary(21, 22), 'Итог: 21 ошибка, 22 предупреждения')
        self.assertEqual(summary(12, 14), 'Итог: 12 ошибок, 14 предупреждений')

    def test_run_prints_and_returns_code(self):
        seed(self.tree)
        stream = io.StringIO()
        with mock.patch('sdlc_tool.views.render_all', side_effect=NotImplementedError):
            self.assertEqual(check.run(self.tree.root, None, stream), 0)
        self.assertTrue(stream.getvalue().endswith('Итог: 0 ошибок, 1 предупреждение\n'))
        self.tree.write(MOD_1, self.tree.read(MOD_1) + '[x](nope.md)\n')
        stream = io.StringIO()
        with mock.patch('sdlc_tool.views.render_all', return_value={}):
            self.assertEqual(check.run(self.tree.root, None, stream), 1)
        self.assertEqual(stream.getvalue().splitlines(), [
            f'ОШИБКА {MOD_1}:4: цель ссылки не существует: nope.md',
            'Итог: 1 ошибка, 0 предупреждений'])

    def test_deterministic_order(self):
        seed(self.tree)
        for path in (MOD_1, ACTOR_1, TC_1):
            self.tree.write(path, self.tree.read(path) + '[x](nope.md)\n[R1](nope.md)\n')
        first = [item.format() for item in self.tree.check()]
        self.assertEqual(first, sorted(first, key=lambda line: (
            line.split(' ', 1)[1].split(':')[0],
            int(line.split(':')[1]) if line.split(':')[1].isdigit() else 0)))
        self.assertEqual(first, [item.format() for item in self.tree.check()])
