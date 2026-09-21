#!/usr/bin/env python3
"""Юнит-тесты импорта банка ФИПИ.

Выгрузка для них не нужна: проверяются правила преобразования, а не данные.

    python3 -m unittest discover -s tools/tests -t .
"""

from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from fipi_import import bank  # noqa: E402
from fipi_import.html_to_md import html_to_markdown  # noqa: E402
from fipi_import.sql import copy_block, copy_text  # noqa: E402


def markdown(html, asset_url=None):
    return html_to_markdown(html, asset_url)[0]


class HtmlToMarkdownTest(unittest.TestCase):
    def test_paragraphs_become_blocks(self):
        result = markdown('<p>Первый абзац.</p> <p>Второй абзац.</p>')
        self.assertEqual(result, 'Первый абзац.\n\nВторой абзац.')

    def test_emphasis_keeps_spaces_outside_markers(self):
        result = markdown('<p>Число <i>N </i>задано.</p>')
        self.assertEqual(result, 'Число *N* задано.')

    def test_empty_emphasis_does_not_produce_markers(self):
        self.assertEqual(markdown('<p>Текст<i> </i>дальше.</p>'),
                         'Текст дальше.')

    def test_subscript_uses_unicode(self):
        self.assertEqual(markdown('<p>1100<sub>2</sub></p>'), '1100₂')

    def test_superscript_uses_unicode(self):
        self.assertEqual(markdown('<p>2<sup>10</sup></p>'), '2¹⁰')

    def test_letter_subscript_falls_back_to_underscore(self):
        self.assertEqual(markdown('<p>x<sub>k</sub></p>'), r'x\_(k)')

    def test_markdown_specials_are_escaped(self):
        self.assertEqual(markdown('<p>1 &lt; N &lt; 30, a*b, c_d</p>'),
                         r'1 \< N \< 30, a\*b, c\_d')

    def test_line_break_is_hard(self):
        # CommonMark понимает и два пробела, и слэш; схлопывание пробелов
        # съело бы пробелы, поэтому перенос помечается слэшем.
        self.assertEqual(markdown('<p>Первая<br/>вторая</p>'),
                         'Первая\\\nвторая')

    def test_trailing_line_break_leaves_no_slash(self):
        self.assertEqual(markdown('<p>Текст<br/></p>'), 'Текст')

    def test_data_table_becomes_grid(self):
        html = ('<table border="1"><tr><td>1</td><td>8</td></tr>'
                '<tr><td>10</td><td>1</td></tr></table>')
        self.assertEqual(
            markdown(html),
            '|  |  |\n| --- | --- |\n| 1 | 8 |\n| 10 | 1 |',
        )

    def test_first_text_row_becomes_header(self):
        html = ('<table border="1"><tr><td>Имя</td><td>Вес</td></tr>'
                '<tr><td>А</td><td>3</td></tr></table>')
        self.assertEqual(
            markdown(html),
            '| Имя | Вес |\n| --- | --- |\n| А | 3 |',
        )

    def test_colspan_is_padded_with_empty_cells(self):
        # Объединённых ячеек в Markdown нет: строка добивается пустыми,
        # чтобы столбцы не разъехались и ни одно значение не пропало.
        html = ('<table border="1"><tr><td colspan="2">Шапка</td></tr>'
                '<tr><td>1</td><td>2</td></tr></table>')
        self.assertEqual(
            markdown(html),
            '|  |  |\n| --- | --- |\n| Шапка |  |\n| 1 | 2 |',
        )

    def test_layout_table_is_transparent(self):
        html = ('<table border="0"><tr><td><p>Условие задачи.</p></td></tr>'
                '</table>')
        self.assertEqual(markdown(html), 'Условие задачи.')

    def test_single_cell_table_is_transparent(self):
        html = '<table><tr><td><p>Одна ячейка.</p></td></tr></table>'
        self.assertEqual(markdown(html), 'Одна ячейка.')

    def test_local_image_goes_through_asset_url(self):
        html = '<p><img src="assets/images/a_1.gif" alt=""></p>'
        result = markdown(html, lambda path: 'bucket/' + path)
        self.assertEqual(result, '![](bucket/assets/images/a_1.gif)')

    def test_show_picture_script_becomes_image_on_fipi(self):
        html = ("<p><script>ShowPictureQ('docs/x/img(copy1).png');</script></p>")
        result, missing = html_to_markdown(html)
        self.assertEqual(
            result, '![](https://ege.fipi.ru/docs/x/img%28copy1%29.png)')
        self.assertEqual(missing, ['docs/x/img(copy1).png'])

    def test_anchor_without_href_keeps_text_only(self):
        self.assertEqual(markdown('<p><a name="_GoBack"></a>Текст.</p>'),
                         'Текст.')

    def test_file_link_keeps_href(self):
        html = '<p><a href="assets/files/a_1.zip" download>a_1.zip</a></p>'
        result = markdown(html, lambda path: 'bucket/' + path)
        self.assertEqual(result, r'[a\_1.zip](bucket/assets/files/a_1.zip)')

    def test_word_mathml_is_reduced_to_text(self):
        html = '<p>Слово <m:math><m:semantics><m:mo>–</m:mo></m:semantics></m:math> это</p>'
        self.assertEqual(markdown(html), 'Слово – это')

    def test_unclosed_tags_do_not_lose_text(self):
        result = markdown('<p>Первый<p>Второй')
        self.assertEqual(result, 'Первый\n\nВторой')

    def test_nbsp_becomes_plain_space(self):
        self.assertEqual(markdown('<p>А\xa0Б</p>'), 'А Б')


class FieldRulesTest(unittest.TestCase):
    def test_task_uuid_is_derived_from_bank_guid(self):
        self.assertEqual(
            bank.task_uuid('05318E7F3A02BE124C04F61811E5FC47'),
            '05318e7f-3a02-be12-4c04-f61811e5fc47',
        )

    def test_task_uuid_rejects_foreign_identifier(self):
        with self.assertRaises(bank.BankError):
            bank.task_uuid('не-guid')

    def test_theme_slug_replaces_dot(self):
        self.assertEqual(bank.theme_slug('3.13'), 'kes-3-13')

    def test_storage_path_drops_assets_prefix(self):
        self.assertEqual(bank.storage_path('assets/files/a_1.zip'),
                         'fipi/files/a_1.zip')

    def test_title_skips_attachment_notice(self):
        text = ('Задание выполняется с использованием прилагаемых файлов. '
                'Квадрат разлинован на клетки.')
        self.assertEqual(bank.make_title(text), 'Квадрат разлинован на клетки.')

    def test_title_is_cut_by_word_boundary(self):
        text = 'Слово ' * 40
        title = bank.make_title(text)
        self.assertLessEqual(len(title), bank.MAX_TITLE_LENGTH + 1)
        self.assertTrue(title.endswith('…'))

    def test_title_never_empty(self):
        self.assertTrue(bank.make_title(''))

    def test_article_title_taken_from_heading(self):
        markdown_text = '# 3.13 Стеки\n\nТекст статьи.'
        self.assertEqual(bank.article_title(markdown_text, 'Длинный КЭС'),
                         '3.13 Стеки')

    def test_article_summary_skips_heading(self):
        markdown_text = '# 3.13 Стеки\n\n**Где встречается:** задание 24.'
        self.assertEqual(bank.article_summary(markdown_text),
                         'Где встречается: задание 24.')

    def test_answer_formats_cover_bank_types(self):
        self.assertEqual(
            set(bank.ANSWER_FORMATS),
            {'Краткий ответ', 'Выбор ответа', 'Последовательность',
             'Развернутый ответ'},
        )


class CopyFormatTest(unittest.TestCase):
    def test_none_becomes_null_marker(self):
        self.assertEqual(copy_text(None), r'\N')

    def test_control_characters_are_escaped(self):
        self.assertEqual(copy_text('a\tb\nc\\d'), r'a\tb\nc\\d')

    def test_boolean_uses_postgres_letters(self):
        self.assertEqual(copy_text(True), 't')
        self.assertEqual(copy_text(False), 'f')

    def test_array_literal_quotes_elements(self):
        self.assertEqual(copy_text(['1.1', '2.3']), '{"1.1","2.3"}')

    def test_empty_array_is_empty_literal(self):
        self.assertEqual(copy_text([]), '{}')

    def test_copy_block_ends_with_terminator(self):
        block = copy_block('public.t', ['a', 'b'], [{'a': 1, 'b': None}])
        self.assertEqual(
            block.split('\n')[:3],
            ['copy public.t (a, b) from stdin;', '1\t\\N', '\\.'],
        )


if __name__ == '__main__':
    unittest.main()
