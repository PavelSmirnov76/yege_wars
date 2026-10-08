"""Тесты `entomb` и `snapshot-prd`: перенос в `obsolete/` с шапкой, ссылки
дерева на старое место и собственные ссылки перенесённого файла, отметка
устаревания требования, снимок PRD, отказы, вызов из CLI с пересборкой
производных файлов.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import contextlib
import io
import os
from typing import Dict
from unittest import mock

from sdlc_tool import check, model, tomb
from sdlc_tool.__main__ import main
from sdlc_tool.tests.helpers import (
    ACTOR_1, BT_1, ENT_1, EVT_1, FIG_1, PRD, RAW_DAY, TASK_1, TC_1, TOKEN_1, UC_1,
    TreeTestCase, bury, link, obsolete_mark, prd_text, requirement, seed, uc_text,
)

DATE = '2026-11-02'
UC_2 = 'sdlc/2-specs/use-cases/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
UC_3 = 'sdlc/2-specs/use-cases/UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md'
TASK_2 = 'sdlc/4-tasks/TASK-2-LINKS.md'
BURIED_ENT_1 = 'sdlc/2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md'
BURIED_UC_1 = 'sdlc/2-specs/use-cases/obsolete/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md'
BURIED_TASK_2 = 'sdlc/4-tasks/obsolete/TASK-2-LINKS.md'
HISTORY = 'sdlc/0-vibes/prd/history'
SNAPSHOT = f'{HISTORY}/PRD-{DATE}.md'

R1_TEXT = 'Ученик входит по логину и паролю.'
R2_TEXT = 'Ученик видит каталог задач.'
R3_TEXT = 'Ученик входит по ссылке из письма.'


def supersedes(path: str, old_path: str, old_id: str) -> str:
    """Строка `supersedes` заменяющего артефакта."""
    return f'\nsupersedes: {link(path, old_path, old_id)}\n'


class TombTestCase(TreeTestCase):
    """Мир `seed` и `prepare` в коммите: база `check` — дерево до команды."""

    def setUp(self):
        super().setUp()
        seed(self.tree)
        self.prepare()
        self.tree.commit('мир')

    def prepare(self):
        """Что дописать в мир до коммита."""

    def entomb(self, target, by=None, why='понятие снято', date=DATE):
        return tomb.entomb(self.tree.repo(), target, by, why, date)

    def snapshot(self, source='0-vibes/raw/2026-11-01/', why='новый вход', date=DATE):
        return tomb.snapshot_prd(self.tree.repo(), why, source, date)

    def files(self) -> Dict[str, bytes]:
        """Все файлы рабочего дерева, кроме `.git`, с содержимым."""
        result = {}
        for current, dirs, names in os.walk(self.tree.root):
            dirs[:] = [name for name in dirs if name != '.git']
            for name in names:
                path = os.path.join(current, name)
                with open(path, 'rb') as handle:
                    result[os.path.relpath(path, self.tree.root)] = handle.read()
        return result

    def assertRefused(self, call, fragment):
        """Отказ с кодом 1 и текстом `fragment`; ни один файл не изменился."""
        before = self.files()
        with self.assertRaises(model.Refusal) as caught:
            call()
        self.assertEqual(caught.exception.code, 1)
        self.assertIn(fragment, str(caught.exception))
        self.assertEqual(self.files(), before)

    def assertClean(self):
        """`check` с базой — коммитом до команды — ошибок не находит."""
        self.assertEqual(self.tree.errors('HEAD'), [])


class EntombArtifactTest(TombTestCase):
    def test_moves_into_obsolete_with_header(self):
        changed = self.entomb('ENT-1', why='понятие\n  снято')
        self.assertEqual(changed, [ACTOR_1, ENT_1, BURIED_ENT_1, EVT_1])
        self.assertFalse(self.tree.exists(ENT_1))
        self.assertEqual(self.tree.read(BURIED_ENT_1), '\n'.join([
            '> **Похоронен:** 2026-11-02',
            '> **Почему:** понятие снято',
            '> **Заменён:** ничем',
            '',
            '# ENT-1 — учётная запись',
            '',
            'Модуль: [MOD-1](../../modules/MOD-1-AUTH.md).',
            '']))
        for path in (ACTOR_1, EVT_1):
            self.assertIn('[ENT-1](../entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md)',
                          self.tree.read(path))
        self.assertClean()
        warnings = self.tree.warnings('HEAD')
        self.assertMessage(warnings, ACTOR_1, 'похороненный ENT-1 — к пересмотру')
        self.assertMessage(warnings, EVT_1, 'похороненный ENT-1 — к пересмотру')

    def test_replacement(self):
        self.tree.write(UC_2, uc_text(2) + supersedes(UC_2, UC_1, 'UC-1'))
        changed = self.entomb('UC-1', by='UC-2', why='вход теперь по ссылке')
        self.assertEqual(changed, sorted([BURIED_UC_1, FIG_1, TASK_1, TC_1, TOKEN_1, UC_1, UC_2]))
        text = self.tree.read(BURIED_UC_1)
        self.assertTrue(text.startswith(
            '> **Похоронен:** 2026-11-02\n'
            '> **Почему:** вход теперь по ссылке\n'
            '> **Заменён:** [UC-2](../UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md)\n'
            '\n# UC-1 — вход по паролю\n'), text)
        self.assertIn('[R1](../../../0-vibes/prd/PRD.md#r1), '
                      '[BT-1](../../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md), '
                      '[MOD-1](../../modules/MOD-1-AUTH.md).', text)
        self.assertIn('supersedes: [UC-1](obsolete/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md)',
                      self.tree.read(UC_2))
        self.assertIn('[UC-1-P-01](../2-specs/use-cases/obsolete/'
                      'UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md#uc-1-p-01)',
                      self.tree.read(TASK_1))
        self.assertClean()

    def test_chain_of_replacements(self):
        self.tree.write(UC_2, uc_text(2) + supersedes(UC_2, UC_1, 'UC-1'))
        self.entomb('UC-1', by='UC-2')
        self.tree.write(UC_3, uc_text(3) + supersedes(UC_3, UC_2, 'UC-2'))
        buried_uc_2 = 'sdlc/2-specs/use-cases/obsolete/UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'
        self.assertEqual(self.entomb('UC-2', by='UC-3'),
                         sorted([UC_2, UC_3, BURIED_UC_1, buried_uc_2]))
        self.assertIn('> **Заменён:** [UC-2](UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md)\n',
                      self.tree.read(BURIED_UC_1))
        text = self.tree.read(buried_uc_2)
        self.assertIn('> **Заменён:** [UC-3](../UC-3-ACTOR-1-EVT-1-ENT-1-LOGOUT-IN-AUTH.md)\n',
                      text)
        self.assertIn('supersedes: [UC-1](UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md)', text)
        self.assertClean()

    def test_own_links_rebased(self):
        self.tree.write(TASK_2, '\n'.join([
            '# TASK-2 — ссылки',
            '',
            'Путь: [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md'
            '#uc-1-p-01).',
            'Основание: [BT-1](<../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md> '
            '"бизнес-задача").',
            'Токен: [TOKEN-1](../3-design/design-system/TOKEN-1-COLOR.md#%61ccent), '
            'экран: [FIG-1](../3-design/FIG%2D1-LOGIN.md).',
            'Вход: [0-vibes/raw/2026-11-01/](../0-vibes/raw/2026-11-01/), '
            '[0-vibes/raw/2026-11-01](./../0-vibes/raw/2026-11-01).',
            'Свои якоря: [TASK-2](#низ), [TASK-2](TASK-2-LINKS.md#низ), '
            '[TASK-2](/sdlc/4-tasks/TASK-2-LINKS.md).',
            'От корня: [README](/sdlc/README.md); снаружи: [сайт](https://example.invalid/a.md).',
            'Картинки: ![схема](../3-design/нет.png), '
            '[![значок](../3-design/нет.png)](../README.md).',
            'Код: `[BT-1](../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)`.',
            '',
            '```text',
            '[BT-1](../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)',
            '```',
            '',
            '<a id="низ"></a>Низ.',
            '']))
        self.tree.commit('TASK-2')
        self.assertEqual(self.entomb('TASK-2'), [TASK_2, BURIED_TASK_2])
        self.assertEqual(self.tree.read(BURIED_TASK_2), '\n'.join([
            '> **Похоронен:** 2026-11-02',
            '> **Почему:** понятие снято',
            '> **Заменён:** ничем',
            '',
            '# TASK-2 — ссылки',
            '',
            'Путь: [UC-1-P-01](../../2-specs/use-cases/'
            'UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md#uc-1-p-01).',
            'Основание: [BT-1](<../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md> '
            '"бизнес-задача").',
            'Токен: [TOKEN-1](../../3-design/design-system/TOKEN-1-COLOR.md#%61ccent), '
            'экран: [FIG-1](../../3-design/FIG-1-LOGIN.md).',
            'Вход: [0-vibes/raw/2026-11-01/](../../0-vibes/raw/2026-11-01/), '
            '[0-vibes/raw/2026-11-01](../../0-vibes/raw/2026-11-01).',
            'Свои якоря: [TASK-2](#низ), [TASK-2](TASK-2-LINKS.md#низ), '
            '[TASK-2](TASK-2-LINKS.md).',
            'От корня: [README](/sdlc/README.md); снаружи: [сайт](https://example.invalid/a.md).',
            'Картинки: ![схема](../../3-design/нет.png), '
            '[![значок](../../3-design/нет.png)](../../README.md).',
            'Код: `[BT-1](../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)`.',
            '',
            '```text',
            '[BT-1](../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)',
            '```',
            '',
            '<a id="низ"></a>Низ.',
            '']))
        self.assertClean()

    def test_links_from_everywhere(self):
        note = f'{RAW_DAY}/found.md'
        old_snapshot = f'{HISTORY}/PRD-2026-11-01.md'
        summary = 'sdlc/6-eval/auto/2026-11-01-abc1234/summary.md'
        transcript = 'sdlc/6-eval/manual/2026-11-01/TC-1/transcript.md'
        readme = 'sdlc/2-specs/README.md'
        outside = 'docs/notes.md'
        self.tree.write(note, 'Нашли: [ENT-1](../../../2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md'
                              '#%D1%83%D1%87%D1%91%D1%82), [EVT-1](../../../2-specs/events/'
                              'EVT-1-SIGNED-IN-IN-AUTH.md), [битая](nope.md).\n')
        self.tree.write(old_snapshot, model.format_snapshot_header(
            '2026-11-01', 'новый вход', '0-vibes/raw/2026-11-01/', '../../raw/2026-11-01/')
            + '# PRD\n\nСм. [ENT-1](../../../2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md).\n')
        self.tree.write(summary, '[ENT-1](../../../2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md)\n')
        self.tree.write(transcript, '**Вердикт:** PASS\n\n[ENT-1](../../../../2-specs/'
                                    'entities/ENT-1-ACCOUNT-IN-AUTH.md)\n')
        self.tree.write(readme, '# 2-specs\n\n'
                                '[ENT-1](/sdlc/2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md), '
                                '[ENT-1](./entities/ENT-1-ACCOUNT-IN-AUTH.md).\n\n'
                                '```\n[ENT-1](entities/ENT-1-ACCOUNT-IN-AUTH.md)\n```\n')
        self.tree.write(outside, '[ENT-1](../sdlc/2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md)\n')
        self.tree.commit('ссылки отовсюду')
        changed = self.entomb('ENT-1')
        self.assertEqual(changed, sorted([ACTOR_1, ENT_1, BURIED_ENT_1, EVT_1, note,
                                          old_snapshot, summary, transcript, readme]))
        self.assertEqual(self.tree.read(note), (
            'Нашли: [ENT-1](../../../2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md'
            '#%D1%83%D1%87%D1%91%D1%82), [EVT-1](../../../2-specs/events/'
            'EVT-1-SIGNED-IN-IN-AUTH.md), [битая](nope.md).\n'))
        self.assertIn('[ENT-1](../../../2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md)',
                      self.tree.read(old_snapshot))
        self.assertIn('[ENT-1](../../../2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md)',
                      self.tree.read(summary))
        self.assertIn('[ENT-1](../../../../2-specs/entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md)',
                      self.tree.read(transcript))
        self.assertEqual(self.tree.read(readme), (
            '# 2-specs\n\n'
            '[ENT-1](entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md), '
            '[ENT-1](entities/obsolete/ENT-1-ACCOUNT-IN-AUTH.md).\n\n'
            '```\n[ENT-1](entities/ENT-1-ACCOUNT-IN-AUTH.md)\n```\n'))
        self.assertEqual(self.tree.read(outside),
                         '[ENT-1](../sdlc/2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md)\n')
        self.assertClean()

    def test_derived_files_left_to_views(self):
        index = 'sdlc/2-specs/entities/INDEX.md'
        dashboard = 'sdlc/6-eval/DASHBOARD.md'
        texts = {
            index: f'{model.DERIVED_HEADER}\n\n[ENT-1](ENT-1-ACCOUNT-IN-AUTH.md)\n',
            dashboard: f'{model.DERIVED_HEADER}\n\n'
                       '[ENT-1](../2-specs/entities/ENT-1-ACCOUNT-IN-AUTH.md)\n',
        }
        for path, text in texts.items():
            self.tree.write(path, text)
        self.tree.commit('производные')
        changed = self.entomb('ENT-1')
        self.assertEqual(changed, [ACTOR_1, ENT_1, BURIED_ENT_1, EVT_1])
        for path, text in texts.items():
            self.assertEqual(self.tree.read(path), text)

    def test_draft_may_be_buried(self):
        self.tree.write(UC_2, uc_text(2, basis=link(UC_2, PRD, 'R1', 'r1')))
        self.assertEqual(self.entomb('UC-2'),
                         [UC_2, 'sdlc/2-specs/use-cases/obsolete/'
                                'UC-2-ACTOR-1-EVT-1-ENT-1-RESET-IN-AUTH.md'])
        self.assertClean()

    def test_bury_everything_in_turn(self):
        base = self.tree.git('rev-parse', 'HEAD').strip()
        for artifact in self.tree.repo().artifacts:
            with self.subTest(artifact.id):
                self.entomb(artifact.id)
                self.assertEqual(self.tree.errors(base), [])
        self.assertTrue(all(item.buried for item in self.tree.repo().artifacts))


class EntombRefusalTest(TombTestCase):
    def test_not_an_artifact_id(self):
        for target in ('нечто', 'uc-1', 'UC-01', 'R07'):
            with self.subTest(target):
                self.assertRefused(lambda: self.entomb(target), 'не id артефакта или требования')
        self.assertRefused(lambda: self.entomb('UC-1-P-01'), 'хоронят UC целиком')

    def test_unknown(self):
        self.assertRefused(lambda: self.entomb('UC-9'), 'артефакта UC-9 нет')

    def test_already_buried(self):
        self.entomb('UC-1')
        self.assertRefused(lambda: self.entomb('UC-1'), f'UC-1 уже похоронен: {BURIED_UC_1}')

    def test_reason_and_date(self):
        for why in (None, '', ' \n '):
            with self.subTest(why=why):
                self.assertRefused(lambda: self.entomb('UC-1', why=why), 'нужна причина')
        self.assertRefused(lambda: self.entomb('UC-1', date='2026-13-01'), 'дата 2026-13-01')

    def test_replacement_must_exist_and_live(self):
        self.assertRefused(lambda: self.entomb('UC-1', by='UC-9'), 'замены UC-9 нет')
        self.tree.write(UC_2, uc_text(2) + supersedes(UC_2, UC_1, 'UC-1'))
        bury(self.tree, UC_2)
        self.assertRefused(lambda: self.entomb('UC-1', by='UC-2'), 'замена UC-2 похоронена')

    def test_replacement_kind(self):
        for by in ('R1', 'UC-1-P-01'):
            with self.subTest(by):
                self.assertRefused(lambda: self.entomb('UC-1', by=by),
                                   'артефакт заменяют артефактом')
        self.assertRefused(lambda: self.entomb('UC-1', by='UC-1'), 'UC-1 не заменяют им самим')

    def test_replacement_writes_supersedes(self):
        self.tree.write(UC_2, uc_text(2))
        self.assertRefused(lambda: self.entomb('UC-1', by='UC-2'),
                           'у UC-2 нет строки supersedes: '
                           '[UC-1](UC-1-ACTOR-1-EVT-1-ENT-1-LOGGED-IN-IN-AUTH.md)')

    def test_supersedes_decides_replacement(self):
        self.tree.write(UC_2, uc_text(2) + supersedes(UC_2, UC_1, 'UC-1'))
        self.assertRefused(lambda: self.entomb('UC-1'), 'хороните с --by UC-2')
        self.tree.write(UC_3, uc_text(3) + supersedes(UC_3, UC_1, 'UC-1'))
        self.assertRefused(lambda: self.entomb('UC-1', by='UC-2'), 'не только UC-2, но и UC-3')

    def test_ambiguous_or_misplaced(self):
        self.tree.write('sdlc/2-specs/entities/ENT-1-USER-IN-AUTH.md', '# ENT-1\n')
        self.assertRefused(lambda: self.entomb('ENT-1'), 'id ENT-1 у нескольких файлов')
        self.tree.write('sdlc/2-specs/actors/ENT-2-ROLE-IN-AUTH.md', '# ENT-2\n')
        self.assertRefused(lambda: self.entomb('ENT-2'), 'ENT-2 лежит не в своей папке')

    def test_live_with_tomb_header(self):
        self.tree.write('sdlc/2-specs/entities/ENT-2-ROLE-IN-AUTH.md',
                        model.format_tomb_header(DATE, 'x') + '# ENT-2\n')
        self.assertRefused(lambda: self.entomb('ENT-2'), 'у живого ENT-2 уже есть шапка')

    def test_place_in_obsolete_taken(self):
        os.makedirs(self.tree.abs(BURIED_ENT_1))
        self.assertRefused(lambda: self.entomb('ENT-1'), f'{BURIED_ENT_1} уже есть')

    def test_file_to_rewrite_not_utf8(self):
        with open(self.tree.abs(f'{RAW_DAY}/latin1.md'), 'wb') as handle:
            handle.write(b'\xe9t\xe9: [ENT-1](../../../2-specs/entities/'
                         b'ENT-1-ACCOUNT-IN-AUTH.md)\n')
        self.assertRefused(lambda: self.entomb('ENT-1'), f'{RAW_DAY}/latin1.md не в UTF-8')


class ObsoleteRequirementTest(TombTestCase):
    def prepare(self):
        self.tree.write(PRD, prd_text(requirement(1, f'{R1_TEXT}\nВторая строка R1.'),
                                      requirement(2, R2_TEXT), requirement(3, R3_TEXT)))

    def test_replaced(self):
        self.assertEqual(self.entomb('R1', by='R3', why=None), [PRD])
        self.assertEqual(self.tree.read(PRD), prd_text(
            requirement(1, f'{R1_TEXT}\nВторая строка R1.', obsolete_mark(DATE, by=3)),
            requirement(2, R2_TEXT), requirement(3, R3_TEXT)))
        self.assertIn('<a id="r1"></a>**R1.** **Устарело 2026-11-02, заменено [R3](#r3).** '
                      'Ученик входит по логину и паролю.', self.tree.read(PRD).split('\n'))
        requirement_1 = self.tree.repo().requirement(1)
        self.assertEqual((requirement_1.mark.date, requirement_1.replaced_by), (DATE, 3))
        self.assertClean()
        self.assertMessage(self.tree.warnings('HEAD'), UC_1,
                           'устаревшее требование R1 — к пересмотру')

    def test_replaced_by_nothing(self):
        self.assertEqual(self.entomb('R2', why='не нужно'), [PRD])
        self.assertIn('<a id="r2"></a>**R2.** **Устарело 2026-11-02, заменено ничем.** '
                      'Ученик видит каталог задач.', self.tree.read(PRD).split('\n'))
        self.assertTrue(self.tree.repo().requirement(2).obsolete)
        self.assertClean()

    def test_refusals(self):
        self.assertRefused(lambda: self.entomb('R9'), 'требования R9 нет в PRD')
        self.assertRefused(lambda: self.entomb('R1', by='R9'), 'заменяющего требования R9 нет')
        self.assertRefused(lambda: self.entomb('R1', by='R1'), 'R1 не заменяют им самим')
        self.assertRefused(lambda: self.entomb('R1', by='UC-1'), 'требование заменяют требованием')
        self.entomb('R2')
        self.assertRefused(lambda: self.entomb('R2', by='R3'), 'R2 уже устарело 2026-11-02')
        self.assertRefused(lambda: self.entomb('R1', by='R2'), 'заменяющее требование R2 устарело')

    def test_broken_prd(self):
        self.tree.replace(PRD, '**R1.** ', '**R1.** **Устарело вчера.** ')
        self.assertRefused(lambda: self.entomb('R1'),
                           'строка R1 с ошибкой: отметка устаревания R1 не по формату')
        self.tree.write(PRD, prd_text(requirement(1, R1_TEXT), requirement(1, R2_TEXT)))
        self.assertRefused(lambda: self.entomb('R1'), 'номер R1 повторён')
        self.tree.remove(PRD)
        self.assertRefused(lambda: self.entomb('R1'), f'PRD нет: {PRD}')

    def test_split_prd(self):
        part_a = 'sdlc/0-vibes/prd/PRD/PRD.md'
        part_b = 'sdlc/0-vibes/prd/PRD/PRD-B.md'
        self.tree.remove(PRD)
        self.tree.write(part_a, prd_text(requirement(1, R1_TEXT)))
        self.tree.write(part_b, f'## Ещё\n\n{requirement(3, R3_TEXT)}\n')
        self.assertEqual(self.entomb('R1', by='R3'), [part_a])
        self.assertIn(f'**R1.** **Устарело {DATE}, заменено [R3](PRD-B.md#r3).** {R1_TEXT}',
                      self.tree.read(part_a))
        self.assertEqual(self.tree.repo().requirement(1).replaced_by, 3)


SNAPSHOT_SOURCE = '\n'.join([
    '# PRD',
    '',
    '## Назначение и границы',
    '',
    'Платформа тренировки: [требования](#требования), '
    '[BT-1](../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md), '
    '[вход](../raw/2026-11-01/), ![схема](img/схема.png), [сайт](https://example.invalid/), '
    '[README](/sdlc/README.md), [PRD](PRD.md).',
    '',
    '## Требования',
    '',
    requirement(1, R1_TEXT, obsolete_mark('2026-11-01', by=3)),
    '',
    requirement(2, f'{R2_TEXT} Как [R3](PRD.md#r3).'),
    '',
    requirement(3, f'{R3_TEXT} `[R1](#r1)`'),
    '',
])


class SnapshotTest(TombTestCase):
    def prepare(self):
        self.tree.write(PRD, SNAPSHOT_SOURCE)

    def test_snapshot(self):
        self.assertEqual(self.snapshot(why='новый\nвход'), SNAPSHOT)
        self.assertEqual(self.tree.read(SNAPSHOT), '\n'.join([
            '> **Сменён:** 2026-11-02',
            '> **Почему:** новый вход',
            '> **Вход:** [0-vibes/raw/2026-11-01/](../../raw/2026-11-01/)',
            '',
            '# PRD',
            '',
            '## Назначение и границы',
            '',
            'Платформа тренировки: [требования](#требования), '
            '[BT-1](../../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md), '
            '[вход](../../raw/2026-11-01/), ![схема](../img/схема.png), '
            '[сайт](https://example.invalid/), [README](/sdlc/README.md), [PRD](../PRD.md).',
            '',
            '## Требования',
            '',
            requirement(1, R1_TEXT, ' **Устарело 2026-11-01, заменено [R3](../PRD.md#r3).**'),
            '',
            requirement(2, f'{R2_TEXT} Как [R3](../PRD.md#r3).'),
            '',
            requirement(3, f'{R3_TEXT} `[R1](#r1)`'),
            '',
        ]))
        self.assertEqual(self.tree.read(PRD), SNAPSHOT_SOURCE)
        header = model.parse_snapshot_header(self.tree.read(SNAPSHOT), SNAPSHOT)
        self.assertEqual((header.error, header.date, header.why), (None, DATE, 'новый вход'))
        self.assertEqual(self.tree.repo().snapshots, [SNAPSHOT])
        self.assertClean()

    def test_numbering_within_a_day(self):
        self.assertEqual([self.snapshot() for _ in range(3)],
                         [SNAPSHOT, f'{HISTORY}/PRD-{DATE}-02.md', f'{HISTORY}/PRD-{DATE}-03.md'])
        self.assertEqual(self.snapshot(date='2026-11-03'), f'{HISTORY}/PRD-2026-11-03.md')
        self.tree.remove(SNAPSHOT)
        self.assertEqual(self.snapshot(), f'{HISTORY}/PRD-{DATE}-04.md')

    def test_input_forms(self):
        raw_day = '[0-vibes/raw/2026-11-01/](../../raw/2026-11-01/)'
        cases = (
            ('sdlc/0-vibes/raw/2026-11-01/', raw_day),
            ('0-vibes/raw/2026-11-01', raw_day),
            (self.tree.abs(RAW_DAY), raw_day),
            (f'{RAW_DAY}/notes.md',
             '[0-vibes/raw/2026-11-01/notes.md](../../raw/2026-11-01/notes.md)'),
            (BT_1, '[BT-1](../../../1-business-tasks/planning/BT-1-PLANNING-LOGIN.md)'),
        )
        for source, expected in cases:
            with self.subTest(source):
                path = self.snapshot(source)
                self.assertEqual(self.tree.read(path).split('\n')[2], f'> **Вход:** {expected}')
        self.assertClean()

    def test_refusals(self):
        self.assertRefused(lambda: self.snapshot('0-vibes/raw/2030-01-01/'),
                           'входа sdlc/0-vibes/raw/2030-01-01 нет')
        for source in ('', 'sdlc', '../outside/', os.path.dirname(self.tree.root)):
            with self.subTest(source):
                self.assertRefused(lambda: self.snapshot(source), 'не файл и не папка под sdlc/')
        os.makedirs(self.tree.abs('sdlc/0-vibes/raw/2026-11-05'))
        self.assertRefused(lambda: self.snapshot('0-vibes/raw/2026-11-05/'),
                           'входа sdlc/0-vibes/raw/2026-11-05 нет')
        self.assertRefused(lambda: self.snapshot(why=' '), 'нужна причина')
        self.assertRefused(lambda: self.snapshot(date='2026-02-30'), 'дата 2026-02-30')

    def test_prd_must_be_whole(self):
        self.tree.write('sdlc/0-vibes/prd/PRD/PRD.md', prd_text(requirement(1, R1_TEXT)))
        self.assertRefused(lambda: self.snapshot(), 'PRD разбит')
        self.tree.remove('sdlc/0-vibes/prd/PRD')
        self.tree.remove(PRD)
        self.assertRefused(lambda: self.snapshot(), f'PRD нет: {PRD}')

    def test_snapshot_links_follow_entomb(self):
        path = self.snapshot()
        self.tree.commit('снимок')
        self.entomb('BT-1')
        self.assertIn('[BT-1](../../../1-business-tasks/planning/obsolete/BT-1-PLANNING-LOGIN.md)',
                      self.tree.read(path))
        self.assertClean()


class CliTest(TombTestCase):
    INDEX = 'sdlc/2-specs/entities/INDEX.md'

    def call(self, *argv):
        """`main` с `--root` дерева; `views.write_all` подменён."""
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err), \
                mock.patch('sdlc_tool.views.write_all', return_value=[self.INDEX]) as write:
            code = main(list(argv) + ['--root', self.tree.root])
        return code, out.getvalue(), err.getvalue(), write

    def test_entomb_then_views(self):
        code, out, _, write = self.call('entomb', 'ENT-1', '--by', 'none', '--why', 'снято',
                                        '--date', DATE)
        self.assertEqual(code, 0)
        self.assertEqual(out.splitlines(), [f'обновлено: {path}' for path in
                                            (ACTOR_1, ENT_1, BURIED_ENT_1, EVT_1, self.INDEX)])
        write.assert_called_once()
        self.assertTrue(write.call_args[0][0].get('ENT-1').buried)

    def test_refusal_skips_views(self):
        before = self.files()
        code, out, err, write = self.call('entomb', 'UC-9', '--by', 'none', '--why', 'снято')
        self.assertEqual((code, out), (1, ''))
        self.assertIn('ОТКАЗ: артефакта UC-9 нет', err)
        write.assert_not_called()
        self.assertEqual(self.files(), before)

    def test_requirement_and_snapshot(self):
        code, out, _, write = self.call('entomb', 'R1', '--by', 'R2', '--date', DATE)
        self.assertEqual((code, out.splitlines()), (0, [f'обновлено: {PRD}',
                                                        f'обновлено: {self.INDEX}']))
        self.assertTrue(write.call_args[0][0].requirement(1).obsolete)
        code, out, _, write = self.call('snapshot-prd', '--why', 'новый вход', '--input',
                                        'sdlc/0-vibes/raw/2026-11-01/', '--date', DATE)
        self.assertEqual((code, out.splitlines()), (0, [f'снимок: {SNAPSHOT}',
                                                        f'обновлено: {self.INDEX}']))
        self.assertEqual(write.call_args[0][0].snapshots, [SNAPSHOT])

    def test_with_views_tree_passes_check(self):
        self.tree.write(UC_2, uc_text(2, basis=link(UC_2, PRD, 'R2', 'r2'))
                        + supersedes(UC_2, UC_1, 'UC-1'))
        for argv in (('entomb', 'UC-1', '--by', 'UC-2', '--why', 'вход по ссылке'),
                     ('snapshot-prd', '--why', 'новый вход', '--input', RAW_DAY),
                     ('entomb', 'R1', '--by', 'none')):
            with self.subTest(argv[0]):
                with contextlib.redirect_stdout(io.StringIO()), \
                        contextlib.redirect_stderr(io.StringIO()) as err:
                    code = main(list(argv) + ['--root', self.tree.root, '--date', DATE])
                self.assertEqual((code, err.getvalue()), (0, ''))
        messages = check.check(self.tree.repo(), 'HEAD', derived=True)
        self.assertEqual([item.format() for item in messages if item.severity == check.ERROR], [])
        self.assertTrue(self.tree.exists('sdlc/2-specs/use-cases/INDEX.md'))

