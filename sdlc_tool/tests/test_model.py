"""Тесты разбора: имена, id, код и ссылки, шапки, требования, пути UC,
вердикты, supersedes, названия, метки, папки.

    python3 -m unittest discover -s sdlc_tool/tests -t .
"""

from __future__ import annotations

import unittest

from sdlc_tool import model


class ArtifactNameTest(unittest.TestCase):
    def parse(self, filename):
        parsed, reason = model.parse_artifact_name(filename)
        self.assertIsNotNone(parsed, reason)
        return parsed

    def refuse(self, filename, fragment=''):
        parsed, reason = model.parse_artifact_name(filename)
        self.assertIsNone(parsed, filename)
        self.assertIn(fragment, reason)

    def test_every_type_parses(self):
        cases = {
            'BT-9-ERROR-LOGIN-TIMEOUT.md': 'BT-9',
            'MOD-1-AUTH.md': 'MOD-1',
            'ACTOR-1-STUDENT-IN-AUTH.md': 'ACTOR-1',
            'ENT-3-ACCOUNT-IN-AUTH.md': 'ENT-3',
            'EVT-2-SIGNED-IN-IN-AUTH.md': 'EVT-2',
            'UC-4-ACTOR-1-EVT-2-ENT-3-LOGGED-IN-IN-AUTH.md': 'UC-4',
            'TOKEN-1-COLOR.md': 'TOKEN-1',
            'COMP-2-PRIMARY-BUTTON.md': 'COMP-2',
            'FIG-3-LOGIN.md': 'FIG-3',
            'TASK-7-LOGIN.md': 'TASK-7',
            'RESULT-TASK-7-02.md': 'RESULT-TASK-7-02',
            'RESULT-TASK-7-02-FIX.md': 'RESULT-TASK-7-02',
            'ACC-TASK-7-02.md': 'ACC-TASK-7-02',
            'ACC-TASK-7-100-LATE.md': 'ACC-TASK-7-100',
            'TC-5-LOGIN-ON-PHONE.md': 'TC-5',
            'SEC-1-FIRST-PUSH.md': 'SEC-1',
            'REL-1-MVP.md': 'REL-1',
        }
        for filename, artifact_id in cases.items():
            with self.subTest(filename=filename):
                self.assertEqual(self.parse(filename).id, artifact_id)

    def test_fields(self):
        uc = self.parse('UC-4-ACTOR-1-EVT-2-ENT-3-SIGNED-IN-IN-AUTH.md')
        self.assertEqual(uc.module, 'AUTH')
        self.assertEqual(uc.uc_refs, (('ACTOR', 1), ('EVT', 2), ('ENT', 3)))
        self.assertEqual(uc.name, 'ACTOR-1-EVT-2-ENT-3-SIGNED-IN-IN-AUTH')
        event = self.parse('EVT-2-SIGNED-IN-IN-AUTH.md')
        self.assertEqual(event.module, 'AUTH')  # делится по последнему -IN-
        result = self.parse('RESULT-TASK-7-02-FIX.md')
        self.assertEqual((result.number, result.nn, result.name), (7, '02', 'FIX'))
        self.assertEqual(self.parse('RESULT-TASK-7-02.md').name, '')
        self.assertEqual(self.parse('BT-9-ERROR-LOGIN-TIMEOUT.md').bt_type, 'ERROR')
        self.assertEqual(self.parse('MOD-1-AUTH.md').module, 'AUTH')

    def test_numbers(self):
        self.refuse('UC-03-ACTOR-1-EVT-2-ENT-3-X-IN-AUTH.md', 'не по грамматике')
        self.refuse('TASK-0-X.md', 'не по грамматике')
        self.refuse('RESULT-TASK-7-2.md', 'не по грамматике')
        self.refuse('RESULT-TASK-7-00.md', 'не по грамматике')
        self.refuse('RESULT-TASK-7-002.md', 'не по грамматике')
        self.assertEqual(self.parse('RESULT-TASK-7-09.md').nn, '09')

    def test_words(self):
        self.refuse('TASK-1-login.md', 'не по грамматике')
        self.refuse('TASK-1-.md', 'не по грамматике')
        self.refuse('TASK-1.md', 'не по грамматике')
        self.refuse('MOD-1-AUTH-SERVICE.md', 'одно слово')
        self.refuse('TOKEN-1-COLOR-DARK.md', 'одно слово')
        self.refuse('ACTOR-1-STUDENT.md', '-IN-')
        self.refuse('ACTOR-1-IN-AUTH.md', '-IN-')
        self.refuse('ACTOR-1-STUDENT-IN-AUTH-X.md', 'не одно слово')
        self.refuse('BT-1-BUG-LOGIN.md', 'тип бизнес-задачи BUG')
        self.refuse('notes.md', 'не начинается с типа')
        self.refuse('UC-1-X.txt', 'не файл .md')

    def test_type_words_forbidden(self):
        self.refuse('ENT-3-TASK-LIST-IN-CATALOG.md', 'слово-тип TASK')
        self.refuse('MOD-1-COMP.md', 'слово-тип COMP')
        self.refuse('ACTOR-1-STUDENT-IN-UC.md', 'слово-тип UC')
        self.refuse('UC-4-ACTOR-1-EVT-2-ENT-3-ACTOR-ADDED-IN-AUTH.md', 'слово-тип ACTOR')
        self.refuse('BT-1-PLANNING-FIX-RESULT.md', 'слово-тип RESULT')
        self.refuse('RESULT-TASK-7-02-TC.md', 'слово-тип TC')
        # Слово-тип внутри другого слова — можно.
        self.parse('ENT-3-TASKS-IN-CATALOG.md')
        self.parse('COMP-1-UCBUTTON.md')

    def test_looks_like_artifact(self):
        self.assertTrue(model.looks_like_artifact_name('UC-3-notes.md'))
        self.assertTrue(model.looks_like_artifact_name('RESULT-TASK-7-x.md'))
        self.assertFalse(model.looks_like_artifact_name('UCX-3.md'))
        self.assertFalse(model.looks_like_artifact_name('PROMPT_STAGE3.md'))
        self.assertFalse(model.looks_like_artifact_name('RESULT-7.md'))


class IdTest(unittest.TestCase):
    def test_parse(self):
        self.assertEqual(model.parse_id('R7'), model.IdRef('R7', 'R', 7))
        self.assertEqual(model.parse_id('UC-3'), model.IdRef('UC-3', 'UC', 3))
        path = model.parse_id('UC-3-P-02')
        self.assertEqual((path.type, path.number, path.nn, path.part), ('UC', 3, '02', 'P'))
        self.assertEqual(path.artifact_id, 'UC-3')
        self.assertEqual(model.parse_id('UC-3-O-02').part, 'O')
        result = model.parse_id('RESULT-TASK-7-02')
        self.assertEqual((result.type, result.number, result.nn), ('RESULT', 7, '02'))
        self.assertEqual(result.artifact_id, 'RESULT-TASK-7-02')
        for text in ('UC-03', 'R07', 'UC-3-P-2', 'RESULT-7', 'X-1', 'uc-3', 'R'):
            self.assertIsNone(model.parse_id(text), text)

    def test_looks_like(self):
        for text in ('R7', 'UC-3', ' UC-3 ', 'UC-03', 'UC-3-P-02', 'UC-3-O-2',
                     'RESULT-TASK-7-02', 'ACC-TASK-7-2', 'TOKEN-1'):
            self.assertTrue(model.looks_like_id(text), text)
        for text in ('README', 'UC', 'UC-3 — вход', 'R7.', 'AGENTS.md', 'uc-3'):
            self.assertFalse(model.looks_like_id(text), text)

    def test_format_nn(self):
        self.assertEqual(model.format_nn(2), '02')
        self.assertEqual(model.format_nn(100), '100')


class CodeAndLinksTest(unittest.TestCase):
    def links(self, text):
        return [(link.text, link.target) for link in model.find_links(text)]

    def test_plain_link(self):
        text = 'См. [UC-3](../use-cases/UC-3-X.md#uc-3-p-02) и [docs](https://x.y).'
        found = model.find_links(text, 'sdlc/a.md')
        self.assertEqual([(item.text, item.target) for item in found],
                         [('UC-3', '../use-cases/UC-3-X.md#uc-3-p-02'), ('docs', 'https://x.y')])
        first = found[0]
        self.assertEqual(text[first.target_start:first.target_end], first.target)
        self.assertEqual(text[first.start:first.end],
                         '[UC-3](../use-cases/UC-3-X.md#uc-3-p-02)')
        self.assertEqual(first.split_target(), ('../use-cases/UC-3-X.md', 'uc-3-p-02'))
        self.assertFalse(first.is_external)
        self.assertTrue(found[1].is_external)
        self.assertEqual(first.path, 'sdlc/a.md')

    def test_line_numbers(self):
        text = 'а\n\nб [A](a.md)\nв\n[B](b.md)\n'
        self.assertEqual([item.line for item in model.find_links(text)], [3, 5])

    def test_inline_code_is_not_a_link(self):
        self.assertEqual(self.links('Пример: `[R7](PRD.md#r7)` и [R1](PRD.md#r1).'),
                         [('R1', 'PRD.md#r1')])

    def test_double_backtick_span(self):
        text = 'Из компонента: `` `accent` — [TOKEN-1](TOKEN-1-COLOR.md#accent) ``.'
        self.assertEqual(self.links(text), [])

    def test_unclosed_backtick_is_literal(self):
        self.assertEqual(self.links('Кавычка ` одна и [A](a.md).'), [('A', 'a.md')])

    def test_code_span_stops_at_blank_line(self):
        text = 'начало `кода\n\n[A](a.md) и `конец'
        self.assertEqual(self.links(text), [('A', 'a.md')])

    def test_fenced_blocks(self):
        text = '\n'.join([
            '```markdown', '[R7](PRD.md#r7)', '```',
            '~~~', '[R8](PRD.md#r8)', '~~~',
            '- пункт:', '  ```', '  [R9](PRD.md#r9)', '  ```',
            '````', '```', '[R10](PRD.md#r10)', '````',
            '[R1](PRD.md#r1)',
        ])
        self.assertEqual(self.links(text), [('R1', 'PRD.md#r1')])

    def test_unclosed_fence_runs_to_end(self):
        self.assertEqual(self.links('[A](a.md)\n```\n[B](b.md)\n'), [('A', 'a.md')])

    def test_images(self):
        text = '![схема](img/a.png) и [![логотип](img/b.png)](https://x.y) и \\[не](ссылка)'
        doc = model.Document('a.md', text)
        self.assertEqual([(item.text, item.target) for item in doc.links],
                         [('![логотип](img/b.png)', 'https://x.y')])
        self.assertEqual([item.target for item in doc.images], ['img/a.png', 'img/b.png'])

    def test_nested_brackets_title_and_angle(self):
        self.assertEqual(self.links('[a [b] c](x.md "заголовок")'), [('a [b] c', 'x.md')])
        self.assertEqual(self.links('[A](<путь с пробелом.md>)'), [('A', 'путь с пробелом.md')])
        self.assertEqual(self.links('[A] (a.md) и [B][ref]'), [])

    def test_split_target_decodes(self):
        found = model.find_links('[A](raw/2026%2D11%2D02/my%20file.md#r%37)')
        self.assertEqual(found[0].split_target(), ('raw/2026-11-02/my file.md', 'r7'))
        self.assertEqual(model.find_links('[A](#r7)')[0].split_target(), ('', 'r7'))
        self.assertEqual(model.find_links('[A](a.md)')[0].split_target(), ('a.md', None))

    def test_mask_keeps_length_and_lines(self):
        text = 'a `код` b\n```\nx\n```\nc'
        masked = model.mask_code(text)
        self.assertEqual(len(masked), len(text))
        self.assertEqual(masked.count('\n'), text.count('\n'))
        self.assertNotIn('код', masked)
        self.assertIn('c', masked)

    def test_anchors_outside_code(self):
        text = '<a id="r1"></a>**R1.** x\n`<a id="r2"></a>`\n```\n<a id="r3"></a>\n```\n'
        self.assertEqual(model.find_anchors(text), {'r1'})

    def test_strip_link_paths(self):
        text = ('[UC-3](a/UC-3.md#uc-3-p-01) `[X](y)` ![i](p.png) [![l](b.png)](c.md)\n'
                '```\n[Z](z.md)\n```\n')
        self.assertEqual(model.strip_link_paths(text),
                         '[UC-3]() `[X](y)` ![i]() [![l]()]()\n```\n[Z](z.md)\n```\n')


class HeaderTest(unittest.TestCase):
    TOMB = ('> **Похоронен:** 2026-11-02\n> **Почему:** понятие снято\n'
            '> **Заменён:** [UC-9](../UC-9-X.md)\n\n# UC-5 — старый\n')

    def test_tomb_header_with_replacement(self):
        header = model.parse_tomb_header(self.TOMB, 'p.md')
        self.assertIsNone(header.error)
        self.assertEqual((header.date, header.why, header.replaced_by, header.size),
                         ('2026-11-02', 'понятие снято', 'UC-9', 4))
        self.assertEqual(header.link.target, '../UC-9-X.md')
        self.assertEqual(self.TOMB[header.link.target_start:header.link.target_end],
                         '../UC-9-X.md')
        self.assertEqual(model.strip_tomb_header(self.TOMB), '# UC-5 — старый\n')

    def test_tomb_header_without_replacement(self):
        text = self.TOMB.replace('[UC-9](../UC-9-X.md)', 'ничем')
        header = model.parse_tomb_header(text)
        self.assertIsNone(header.error)
        self.assertIsNone(header.replaced_by)
        self.assertIsNone(header.link)

    def test_no_header(self):
        self.assertIsNone(model.parse_tomb_header('# UC-5\n'))
        self.assertEqual(model.strip_tomb_header('# UC-5\n'), '# UC-5\n')

    def test_malformed_headers(self):
        cases = {
            'две строки': '> **Похоронен:** 2026-11-02\n> **Почему:** x\n\n# A\n',
            'нет пустой строки': self.TOMB.replace('\n\n# UC-5', '\n# UC-5'),
            'плохая дата': self.TOMB.replace('2026-11-02', '2026-13-02'),
            'не ссылка': self.TOMB.replace('[UC-9](../UC-9-X.md)', 'UC-9'),
            'лишний текст': self.TOMB.replace('[UC-9](../UC-9-X.md)', '[UC-9](../UC-9-X.md) и всё'),
            'не то поле': self.TOMB.replace('**Почему:**', '**Причина:**'),
        }
        for name, text in cases.items():
            with self.subTest(name):
                header = model.parse_tomb_header(text)
                self.assertIsNotNone(header)
                self.assertIsNotNone(header.error)
        stripped = model.strip_tomb_header(cases['не ссылка'])
        self.assertEqual(stripped, '# UC-5 — старый\n')

    def test_format_round_trip(self):
        text = model.format_tomb_header('2026-11-02', 'понятие\nснято', ('UC-9', '../UC-9-X.md'))
        header = model.parse_tomb_header(text + '# UC-5\n')
        self.assertIsNone(header.error)
        self.assertEqual((header.why, header.replaced_by, header.size), ('понятие снято', 'UC-9', 4))
        header = model.parse_tomb_header(model.format_tomb_header('2026-11-02', 'x') + '# A\n')
        self.assertEqual((header.error, header.replaced_by), (None, None))
        text = model.format_snapshot_header('2026-11-02', 'вход', '0-vibes/raw/2026-11-02/',
                                            '../../raw/2026-11-02/')
        header = model.parse_snapshot_header(text + '# PRD\n')
        self.assertIsNone(header.error)
        self.assertEqual(header.link.target, '../../raw/2026-11-02/')

    def test_frozen_form(self):
        live = '# UC-5\n\n[R1](../../0-vibes/prd/PRD.md#r1)\n'
        buried = ('> **Похоронен:** 2026-11-02\n> **Почему:** x\n> **Заменён:** ничем\n\n'
                  '# UC-5\n\n[R1](../../../0-vibes/prd/PRD.md#r1)\n')
        self.assertEqual(model.frozen_form(live), model.frozen_form(buried))

    def test_snapshot_header(self):
        text = ('> **Сменён:** 2026-11-02\n> **Почему:** новый вход\n'
                '> **Вход:** [0-vibes/raw/2026-11-02/](../../raw/2026-11-02/)\n\n# PRD\n')
        header = model.parse_snapshot_header(text)
        self.assertIsNone(header.error)
        self.assertEqual((header.date, header.why, header.size), ('2026-11-02', 'новый вход', 4))
        self.assertEqual(header.link.target, '../../raw/2026-11-02/')
        self.assertIsNotNone(model.parse_snapshot_header(
            text.replace('[0-vibes/raw/2026-11-02/](../../raw/2026-11-02/)', 'raw')).error)
        self.assertIsNone(model.parse_snapshot_header('# PRD\n'))


class RequirementTest(unittest.TestCase):
    def parse(self, text):
        return model.parse_requirements(text, 'sdlc/0-vibes/prd/PRD.md')

    def test_text_boundaries(self):
        text = '\n'.join([
            '# PRD', '## Требования',
            '<a id="r1"></a>**R1.** Первое,', 'продолжение.',
            '<a id="r2"></a>**R2.** Второе.', '',
            'Абзац не требование.',
            '<a id="r3"></a>**R3.** Третье.', '## Метрики', 'текст',
        ])
        requirements, issues, numbers = self.parse(text)
        self.assertEqual(issues, [])
        self.assertEqual([(item.id, item.line, item.end_line) for item in requirements],
                         [('R1', 3, 4), ('R2', 5, 5), ('R3', 8, 8)])
        self.assertEqual(requirements[0].text,
                         '<a id="r1"></a>**R1.** Первое,\nпродолжение.')
        self.assertEqual(numbers, {1, 2, 3})
        self.assertFalse(requirements[0].obsolete)

    def test_marks(self):
        text = '\n\n'.join([
            '<a id="r1"></a>**R1.** **Устарело 2026-11-02, заменено [R3](#r3).** Старое.',
            '<a id="r2"></a>**R2.** **Устарело 2026-11-03, заменено ничем.** Снятое.',
            '<a id="r3"></a>**R3.** Новое.',
        ])
        requirements, issues, _ = self.parse(text)
        self.assertEqual(issues, [])
        first, second, third = requirements
        self.assertEqual((first.mark.date, first.replaced_by), ('2026-11-02', 3))
        self.assertTrue(second.obsolete)
        self.assertIsNone(second.replaced_by)
        self.assertFalse(third.obsolete)
        self.assertEqual(first.body, '<a id="r1"></a>**R1.** Старое.')
        self.assertEqual(model.strip_obsolete_mark(first.text), first.body)
        self.assertEqual(model.strip_obsolete_mark('просто строка'), 'просто строка')

    def test_format_mark_round_trip(self):
        line = '<a id="r1"></a>**R1.** Старое.'
        requirements, _, _ = self.parse(line)
        offset = model.mark_offset(requirements[0])
        for mark, replaced in ((model.format_obsolete_mark('2026-11-02', 3), 3),
                               (model.format_obsolete_mark('2026-11-02'), None),
                               (model.format_obsolete_mark('2026-11-02', 3, 'PRD-B.md'), 3)):
            marked = line[:offset] + mark + line[offset:]
            parsed, issues, _ = self.parse(marked)
            self.assertEqual(issues, [])
            self.assertTrue(parsed[0].obsolete)
            self.assertEqual(parsed[0].replaced_by, replaced)
            self.assertEqual(parsed[0].body, line)

    def test_mark_may_carry_path(self):
        text = '<a id="r1"></a>**R1.** **Устарело 2026-11-02, заменено [R3](PRD-B.md#r3).** x'
        requirements, issues, _ = self.parse(text)
        self.assertEqual(issues, [])
        self.assertEqual(requirements[0].replaced_by, 3)

    def test_format_errors(self):
        cases = {
            '<a id="r1"></a>**R2.** Текст.': 'номер в якоре r1 и в тексте R2 разный',
            '**R3.** Без якоря.': 'строка требования не по формату',
            '<a id="r04"></a>**R04.** Ведущий ноль.': 'строка требования не по формату',
            '<a id="r5"></a> **R5.** Пробел.': 'строка требования не по формату',
            '- <a id="r6"></a>**R6.** В списке.': 'строка требования не по формату',
            '<a id="r7"></a>**R7.**Без пробела.': 'строка требования не по формату',
            '<a id="r8"></a>**R8.** Устарело 2026-11-02, заменено ничем. x': 'отметка устаревания R8',
            '<a id="r9"></a>**R9.** x **Устарело 2026-11-02, заменено ничем.**': 'отметка устаревания R9',
            '<a id="r10"></a>**R10.** **Устарело 2026-02-30, заменено ничем.** x': 'дата 2026-02-30',
            '<a id="r11"></a>**R11.** **Устарело 2026-11-02, заменено [R3](#r4).** x': 'текст R3, а якорь #r4',
            '<a id="r12"></a>**R12.** **Устарело 2026-11-02, заменён R3.** x': 'отметка устаревания R12',
        }
        for line, fragment in cases.items():
            with self.subTest(line):
                requirements, issues, _ = self.parse(line)
                self.assertEqual(len(issues), 1, issues)
                self.assertIn(fragment, issues[0].text)
                self.assertEqual(issues[0].line, 1)

    def test_bad_mark_leaves_requirement_live(self):
        requirements, issues, _ = self.parse(
            '<a id="r8"></a>**R8.** Устарело 2026-11-02, заменено ничем. x')
        self.assertEqual(len(requirements), 1)
        self.assertFalse(requirements[0].obsolete)

    def test_code_and_other_anchors_ignored(self):
        text = '```\n<a id="r7"></a>**R7.** пример\n```\n`<a id="r8"></a>**R8.**`\n<a id="glossary"></a>\n'
        self.assertEqual(self.parse(text), ([], [], set()))

    def test_numbers_include_bad_lines(self):
        _, _, numbers = self.parse('<a id="r1"></a>**R9.** x\n\n**R12.** y\n')
        self.assertEqual(numbers, {1, 9, 12})


class UcPathTest(unittest.TestCase):
    def parse(self, lines, number=3):
        return model.parse_uc_paths('\n'.join(lines), 'uc.md', number)

    @staticmethod
    def path(nn, uc=3, anchor=None):
        anchor = anchor or f'uc-{uc}-p-{nn}'
        return f'### <a id="{anchor}"></a>UC-{uc}-P-{nn} — путь {nn}'

    @staticmethod
    def outcome(nn, uc=3):
        return f'**Исход:** UC-{uc}-O-{nn} — исход {nn}'

    def test_valid(self):
        paths, issues = self.parse([
            '# UC-3 — вход', '## Пути',
            self.path('01'), 'текст', '#### деталь', self.outcome('01'),
            self.path('02'), self.outcome('02'),
            '## Постусловия', 'ничего',
        ])
        self.assertEqual(issues, [])
        self.assertEqual([(item.id, item.anchor, item.line, item.outcome_id) for item in paths],
                         [('UC-3-P-01', 'uc-3-p-01', 3, 'UC-3-O-01'),
                          ('UC-3-P-02', 'uc-3-p-02', 7, 'UC-3-O-02')])
        self.assertEqual((paths[0].name, paths[0].outcome_name, paths[0].outcome_line),
                         ('путь 01', 'исход 01', 6))

    def assertIssue(self, lines, fragment, line=None):
        _, issues = self.parse(lines)
        self.assertEqual(len(issues), 1, issues)
        self.assertIn(fragment, issues[0].text)
        if line is not None:
            self.assertEqual(issues[0].line, line)

    def test_no_outcome(self):
        _, issues = self.parse([self.path('01'), 'текст', '## Дальше', self.outcome('01')])
        self.assertEqual([(item.line, item.text) for item in issues],
                         [(1, 'у пути UC-3-P-01 нет исхода'), (4, 'исход вне раздела пути')])
        self.assertIssue([self.path('01'), 'текст'], 'у пути UC-3-P-01 нет исхода', 1)

    def test_two_outcomes(self):
        self.assertIssue([self.path('01'), self.outcome('01'), self.outcome('01')],
                         'строк исхода 2', 1)

    def test_outcome_number(self):
        self.assertIssue([self.path('01'), self.outcome('02')],
                         'исход UC-3-O-02 не совпадает с путём UC-3-P-01', 2)
        self.assertIssue([self.path('01'), self.outcome('01', uc=4)],
                         'исход UC-4-O-01 не совпадает', 2)

    def test_heading_errors(self):
        self.assertIssue([self.path('01', anchor='uc-3-p-02'), self.outcome('01')],
                         'якорь uc-3-p-02 не совпадает с заголовком UC-3-P-01', 1)
        self.assertIssue([self.path('01', uc=4), self.outcome('01', uc=4)],
                         'номер UC не тот', 1)
        self.assertIssue([self.path('1', anchor='uc-3-p-1'), self.outcome('1')],
                         'номер пути UC-3-P-1 не по формату', 1)
        self.assertIssue(['### UC-3-P-01 — без якоря', self.outcome('01')],
                         'заголовок пути не по формату', 1)
        self.assertIssue(['### <a id="uc-3-p-01"></a>UC-3-P-01 - дефис', self.outcome('01')],
                         'заголовок пути не по формату', 1)

    def test_repeated_path(self):
        self.assertIssue([self.path('01'), self.outcome('01'), self.path('01'), self.outcome('01')],
                         'путь UC-3-P-01 повторён', 3)

    def test_bad_outcome_line(self):
        self.assertIssue([self.path('01'), '**Исход:** UC-3-O-01 - дефис'],
                         'строка исхода не по формату', 2)

    def test_other_h3_and_code_ignored(self):
        paths, issues = self.parse([
            '### Примечания', 'текст',
            '```', self.path('09'), self.outcome('09'), '```',
            self.path('01'), self.outcome('01'),
        ])
        self.assertEqual(issues, [])
        self.assertEqual([item.id for item in paths], ['UC-3-P-01'])


class VerdictTest(unittest.TestCase):
    def test_acceptance(self):
        for text, verdict in (('**Вердикт:** принято\n', 'принято'),
                              ('## Вердикт\n\n**Вердикт:** возврат\n', 'возврат'),
                              ('2. **Вердикт:** принято\n', 'принято'),
                              ('- **Вердикт:** принято\n', 'принято')):
            with self.subTest(text):
                self.assertEqual(model.parse_acceptance_verdict(text), (verdict, []))

    def test_acceptance_errors(self):
        verdict, issues = model.parse_acceptance_verdict('# ACC\n\nВсё хорошо.\n', 'a.md')
        self.assertIsNone(verdict)
        self.assertEqual([(item.line, 'нет строки вердикта' in item.text) for item in issues],
                         [(0, True)])
        for text in ('**Вердикт:** Принято\n', '**Вердикт**: принято\n',
                     'Вердикт: принято\n', '**Вердикт:** принято.\n',
                     '**Вердикт:** возврат — см. ниже\n'):
            with self.subTest(text):
                verdict, issues = model.parse_acceptance_verdict(text)
                self.assertIsNone(verdict)
                self.assertEqual(len(issues), 1)
                self.assertIn('не по формату', issues[0].text)
        verdict, issues = model.parse_acceptance_verdict(
            '**Вердикт:** принято\n\n**Вердикт:** возврат\n')
        self.assertIsNone(verdict)
        self.assertIn('строк вердикта 2', issues[0].text)
        self.assertEqual(model.parse_acceptance_verdict('```\n**Вердикт:** x\n```\n**Вердикт:** принято\n'),
                         ('принято', []))

    def test_manual(self):
        self.assertEqual(model.parse_manual_verdict('**Вердикт:** BLOCKED\n'), ('BLOCKED', []))
        verdict, issues = model.parse_manual_verdict('**Вердикт:** PASSED\n')
        self.assertIsNone(verdict)
        self.assertEqual(len(issues), 1)


class SupersedesTest(unittest.TestCase):
    def test_valid(self):
        text = '# UC-9\n\nsupersedes: [UC-5](obsolete/UC-5-X.md)\nsupersedes: [UC-6](a.md), [UC-7](b.md)\n'
        links, issues = model.parse_supersedes(text)
        self.assertEqual(issues, [])
        self.assertEqual([(item.text, item.line) for item in links],
                         [('UC-5', 3), ('UC-6', 4), ('UC-7', 4)])

    def test_errors(self):
        for line in ('supersedes: UC-5', 'Supersedes: [UC-5](a.md)', 'supersedes: [UC-5](a.md) и всё',
                     ' supersedes: [UC-5](a.md)', 'supersedes:[UC-5](a.md)'):
            with self.subTest(line):
                links, issues = model.parse_supersedes(f'# X\n{line}\n')
                self.assertEqual(links, [])
                self.assertEqual([item.line for item in issues], [2])

    def test_code_ignored(self):
        self.assertEqual(model.parse_supersedes('`supersedes: <старый id>`\n'), ([], []))


class TitleTest(unittest.TestCase):
    def test_titles(self):
        cases = [
            ('# UC-3 — Вход по паролю\n', 'Вход по паролю'),
            ('# UC-3: Вход\n', 'Вход'),
            ('# UC-3 – Вход\n', 'Вход'),
            ('# UC-3 - Вход\n', 'Вход'),
            ('# Вход по паролю\n', 'Вход по паролю'),
            ('# UC-30 — другой\n', 'UC-30 — другой'),
            ('# UC-3\n', 'ИМЯ'),
            ('Текст без заголовка\n## UC-3 — второй уровень\n', 'ИМЯ'),
            ('```\n# UC-3 — в коде\n```\n# UC-3 — Настоящий\n', 'Настоящий'),
            ('> **Похоронен:** 2026-11-02\n\n# UC-3 — Старый\n', 'Старый'),
        ]
        for text, title in cases:
            with self.subTest(text):
                self.assertEqual(model.parse_title(text, 'UC-3', 'ИМЯ'), title)


class LabelTest(unittest.TestCase):
    def ids(self, text):
        return [label.id for label in model.find_labels(text)]

    def test_kinds_and_lines(self):
        text = "// UC-3\ntest('UC-3-P-02: неверный пароль', () {});\n-- TOKEN-1\n# COMP-12\n"
        labels = model.find_labels(text, 'test/a.dart')
        self.assertEqual([(item.id, item.line, item.type, item.nn) for item in labels],
                         [('UC-3', 1, 'UC', None), ('UC-3-P-02', 2, 'UC', '02'),
                          ('TOKEN-1', 3, 'TOKEN', None), ('COMP-12', 4, 'COMP', None)])
        self.assertEqual(labels[1].artifact_id, 'UC-3')
        self.assertTrue(labels[1].is_path)

    def test_neighbours(self):
        self.assertEqual(self.ids('XUC-3 UC-3a UC-3- -UC-3 1UC-3 UC-3-O-02 UC-3-P- ЖUC-3 UC-3ж'), [])
        self.assertEqual(self.ids('_UC-3_ (UC-4) "TOKEN-1" UC-03'), ['UC-3', 'UC-4', 'TOKEN-1', 'UC-03'])
        self.assertEqual(model.find_labels('UC-03')[0].artifact_id, 'UC-03')


class FoldersTest(unittest.TestCase):
    def test_classify(self):
        content = ['sdlc/0-vibes/raw/2026-10-08', 'sdlc/0-vibes/raw/2026-10-08/img',
                   'sdlc/2-specs/use-cases/obsolete', 'sdlc/obsolete',
                   'sdlc/6-eval/auto/2026-10-12-1a2b3c4', 'sdlc/6-eval/manual/2026-10-12',
                   'sdlc/6-eval/manual/2026-10-12/TC-1/screenshots', 'sdlc/0-vibes/prd/PRD']
        structure = ['sdlc', 'sdlc/0-vibes/raw', 'sdlc/0-vibes/raw/misc', 'sdlc/6-eval/auto',
                     'sdlc/6-eval/manual', 'sdlc/6-eval/manual/old', 'sdlc/0-vibes/prd/history']
        for path in content:
            self.assertEqual(model.classify_dir(path), model.CONTENT, path)
        for path in structure:
            self.assertEqual(model.classify_dir(path), model.STRUCTURE, path)

    def test_link_checked(self):
        self.assertTrue(model.is_link_checked('sdlc/AGENTS.md'))
        self.assertTrue(model.is_link_checked('sdlc/0-vibes/raw/AGENTS.md'))
        self.assertTrue(model.is_link_checked('sdlc/2-specs/use-cases/obsolete/UC-1-X.md'))
        self.assertTrue(model.is_link_checked('sdlc/0-vibes/prd/history/PRD-2026-11-02.md'))
        self.assertFalse(model.is_link_checked('sdlc/0-vibes/raw/2026-10-08/STATE.md'))
        self.assertFalse(model.is_link_checked('sdlc/6-eval/auto/run/summary.md'))
        self.assertFalse(model.is_link_checked('sdlc/6-eval/manual/2026-10-12/TC-1/transcript.md'))
        self.assertFalse(model.is_link_checked('docs/SPEC.md'))

    def test_artifact_home(self):
        self.assertEqual(model.artifact_home('sdlc/3-design'), ('3-design', False))
        self.assertEqual(model.artifact_home('sdlc/3-design/design-system/obsolete'),
                         ('3-design/design-system', True))
        self.assertEqual(model.artifact_home('sdlc/2-specs'), (None, False))
        self.assertEqual(model.artifact_home('sdlc/2-specs/obsolete'), (None, False))

    def test_rel_link(self):
        self.assertEqual(model.rel_link('sdlc/2-specs/use-cases/UC-1.md',
                                        'sdlc/2-specs/actors/ACTOR-1.md'),
                         '../actors/ACTOR-1.md')
        self.assertEqual(model.rel_link('sdlc/2-specs/use-cases/obsolete/UC-1.md',
                                        'sdlc/0-vibes/prd/PRD.md', 'r1'),
                         '../../../0-vibes/prd/PRD.md#r1')
        self.assertEqual(model.rel_link('sdlc/0-vibes/prd/PRD.md', 'sdlc/0-vibes/prd/PRD.md', 'r3'),
                         '#r3')
        self.assertEqual(model.rel_link('sdlc/0-vibes/prd/history/PRD-2026-11-02.md',
                                        'sdlc/0-vibes/raw/2026-11-02', is_dir=True),
                         '../../raw/2026-11-02/')
        self.assertEqual(model.rel_link('a/b.md', 'a/my file (1).md'), 'my%20file%20%281%29.md')

    def test_count_lines(self):
        self.assertEqual(model.count_lines(''), 0)
        self.assertEqual(model.count_lines('a\nb\n'), 2)
        self.assertEqual(model.count_lines('a\nb'), 2)


if __name__ == '__main__':
    unittest.main()
