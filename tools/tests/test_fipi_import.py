#!/usr/bin/env python3
"""Юнит-тесты импорта банка ФИПИ.

Выгрузка для них не нужна: проверяются правила преобразования, а не данные.

    python3 -m unittest discover -s tools/tests -t .
"""

from __future__ import annotations

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from fipi_import import bank  # noqa: E402
from fipi_import.html_to_md import html_to_markdown  # noqa: E402
from fipi_import.image_size import image_size  # noqa: E402
from fipi_import.sql import copy_block, copy_text  # noqa: E402


# Ограда блока кода: тройной обратный апостроф.
FENCE = chr(96) * 3


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


class TablesTest(unittest.TestCase):
    """Таблицы: вёрстка, объединённые ячейки, ячейки с листингами."""

    def test_data_table_without_border_stays_a_table(self):
        # Word ставит border="0" и на таблицы с данными: рамки заданы стилем.
        html = ('<table border="0" class="MsoNormalTable">'
                '<tr><td>1</td><td>8</td></tr>'
                '<tr><td>10</td><td>1</td></tr></table>')
        self.assertEqual(
            markdown(html),
            '|  |  |\n| --- | --- |\n| 1 | 8 |\n| 10 | 1 |',
        )

    def test_rowspan_keeps_values_in_their_columns(self):
        # Ячейка «Имя» занимает две строки: во второй строке на её месте
        # должна стоять пустая ячейка, иначе значения съедут влево.
        html = ('<table border="1">'
                '<tr><td>шапка</td><td>A</td><td>B</td></tr>'
                '<tr><td rowspan="2">Имя</td><td>1</td><td>2</td></tr>'
                '<tr><td>3</td><td>4</td></tr></table>')
        self.assertEqual(
            markdown(html),
            '| шапка | A | B |\n| --- | --- | --- |\n'
            '| Имя | 1 | 2 |\n|  | 3 | 4 |',
        )

    def test_single_cell_wrapper_is_transparent(self):
        html = '<table border="1"><tr><td><p>Одна ячейка.</p></td></tr></table>'
        self.assertEqual(markdown(html), 'Одна ячейка.')

    def test_table_holding_a_table_is_a_wrapper(self):
        # Вордовская обёртка: слева таблица с данными, справа картинка.
        html = ('<table border="1"><tr>'
                '<td><table border="1"><tr><td>1</td><td>2</td></tr>'
                '<tr><td>3</td><td>4</td></tr></table></td>'
                '<td><p>рядом</p></td></tr></table>')
        result = markdown(html)
        self.assertIn('| 1 | 2 |', result)
        self.assertIn('| 3 | 4 |', result)
        self.assertTrue(result.endswith('рядом'))

    def test_listing_cell_becomes_a_code_block(self):
        html = ('<table border="1">'
                '<tr><td>Python</td></tr>'
                '<tr><td><p>n = 1</p><p>while n &lt; 5:</p>'
                '<p>    n = n + 1</p><p>print(n)</p></td></tr></table>')
        self.assertEqual(
            markdown(html),
            '**Python**\n\n' + FENCE + 'python\n'
            'n = 1\nwhile n < 5:\n    n = n + 1\nprint(n)\n' + FENCE,
        )

    def test_language_row_pairs_with_its_listing(self):
        html = ('<table border="1">'
                '<tr><td>Паскаль</td><td>Python</td></tr>'
                '<tr><td><p>begin</p><p>  x := 1;</p><p>end.</p></td>'
                '<td><p>x = 1</p><p>if x:</p><p>  print(x)</p></td></tr>'
                '</table>')
        result = markdown(html)
        self.assertIn('**Паскаль**', result)
        self.assertIn('**Python**', result)
        # Подпись стоит непосредственно перед своим листингом.
        self.assertLess(result.index('begin'), result.index('**Python**'))
        self.assertLess(result.index('**Паскаль**'), result.index('begin'))

    def test_listing_keeps_indentation_made_of_nbsp(self):
        html = ('<table border="1"><tr><td>Код</td></tr><tr><td>'
                '<p>for i in a:</p><p>\xa0\xa0\xa0\xa0s = s + i</p>'
                '<p>print(s)</p></td></tr></table>')
        self.assertIn('\n    s = s + i\n', markdown(html))

    def test_prose_cells_are_not_mistaken_for_code(self):
        html = ('<table border="1"><tr><td>Пояснение</td></tr><tr><td>'
                '<p>Первое предложение занимает довольно много слов подряд.</p>'
                '<p>  Второе предложение тоже длинное и содержит много слов.</p>'
                '<p>Третье предложение написано так же подробно, как прочие.</p>'
                '</td></tr></table>')
        self.assertNotIn(FENCE, markdown(html))


class EscapingAndScriptsTest(unittest.TestCase):
    """Экранирование и индексы."""

    def test_hash_at_line_start_is_escaped(self):
        self.assertEqual(markdown('<p># комментарий</p>'), r'\# комментарий')

    def test_space_inside_superscript_is_kept_outside(self):
        self.assertEqual(markdown('<p>2<sup>21 </sup>бит</p>'), '2²¹ бит')

    def test_empty_subscript_keeps_its_space(self):
        self.assertEqual(markdown('<p>a<sub> </sub>b</p>'), 'a b')

    def test_adjacent_subscripts_merge_into_one(self):
        self.assertEqual(
            markdown('<p>a<sub>n</sub><sub>-</sub><sub>1</sub></p>'),
            r'a\_(n-1)',
        )

    def test_adjacent_bold_runs_merge(self):
        self.assertEqual(markdown('<p><b>раз</b><b>два</b></p>'),
                         '**раздва**')


class TitleRulesTest(unittest.TestCase):
    """Заголовок задачи."""

    def test_second_wording_of_the_notice_is_skipped(self):
        text = ('Задание выполняется с использованием прилагаемых к заданию '
                'файлов. Квадрат разлинован на клетки.')
        self.assertEqual(bank.make_title(text),
                         'Квадрат разлинован на клетки.')

    def test_initials_do_not_end_the_sentence(self):
        text = 'Автор М.А. Иванов предложил алгоритм. Второе предложение.'
        self.assertEqual(bank.make_title(text),
                         'Автор М.А. Иванов предложил алгоритм.')

    def test_abbreviation_does_not_end_the_sentence(self):
        text = 'Числа даны в файле и т.д. Найдите наибольшее. Ещё одно.'
        self.assertEqual(bank.make_title(text),
                         'Числа даны в файле и т.д. Найдите наибольшее.')


class ChromeImagesTest(unittest.TestCase):
    """Служебные картинки сайта банка в условие не попадают."""

    def test_empty_url_drops_the_image(self):
        html = '<p>текст<img src="assets/images/icon.gif" alt=""></p>'
        self.assertEqual(markdown(html, lambda path: ''), 'текст')

    def test_empty_url_leaves_link_text(self):
        html = '<p><a href="assets/files/a.zip">a.zip</a></p>'
        self.assertEqual(markdown(html, lambda path: ''), 'a.zip')


class InlineSpacingTest(unittest.TestCase):
    """Пробел между инлайн-соседями — разделитель слов, а не мусор."""

    def test_space_between_two_inline_tags_survives(self):
        html = ('<p>прошло <strong>не менее</strong> '
                '<em><span>K</span></em> мин.</p>')
        self.assertEqual(markdown(html), 'прошло **не менее** *K* мин.')

    def test_non_breaking_space_between_numbers_survives(self):
        html = '<p><i>340</i>\xa0\xa0\xa0<i>90</i></p>'
        self.assertEqual(markdown(html), '*340* *90*')

    def test_space_before_math_operator_survives(self):
        html = ('<p>9<span>F</span><sub>16</sub> '
                '<m:math><m:semantics><m:mo>–</m:mo></m:semantics></m:math>'
                ' 96<sub>16</sub>.</p>')
        self.assertEqual(markdown(html), '9F₁₆ – 96₁₆.')

    def test_space_between_blocks_adds_nothing(self):
        self.assertEqual(markdown('<p>Раз.</p>  <p>Два.</p>'),
                         'Раз.\n\nДва.')


class EmphasisSeamTest(unittest.TestCase):
    """Стык двух выделений: Markdown прогон звёздочек не читает."""

    def test_bold_runs_split_by_span_merge(self):
        html = ('<p><span>выражение <b>6</b></span>'
                '<b><span lang="EN-US">B</span></b>'
                '<b><sub><span>16</span></sub></b>'
                '<b><span> – 65<sub>16</sub></span></b><span>.</span></p>')
        self.assertEqual(markdown(html), 'выражение **6B₁₆ – 65₁₆**.')

    def test_different_tags_same_marker_do_not_collide(self):
        self.assertEqual(markdown('<p><b>раз</b><strong>два</strong></p>'),
                         '**раздва**')

    def test_emphasis_around_line_break_only_is_dropped(self):
        html = '<p>сумму цифр, <i><br/> </i>НЕ кратных 3</p>'
        self.assertEqual(markdown(html),
                         'сумму цифр, \\\nНЕ кратных 3')

    def test_emphasis_around_punctuation_only_is_dropped(self):
        html = '<p><b>Поднять хвост<i>, </i></b>означающая переход</p>'
        self.assertEqual(markdown(html),
                         '**Поднять хвост**, означающая переход')

    def test_trailing_hyphen_moves_outside_the_marker(self):
        html = '<p>находясь в <i><span>i</span>-</i>м состоянии</p>'
        self.assertEqual(markdown(html), 'находясь в *i*-м состоянии')


class ScriptMergeTest(unittest.TestCase):
    """Составной индекс собирается целиком."""

    def test_subscript_merges_across_italic_boundary(self):
        html = '<p><i>y<sub>j </sub></i><sub>+ 1</sub></p>'
        self.assertEqual(markdown(html), r'*y\_(j + 1)*')

    def test_sentence_period_leaves_the_subscript(self):
        html = '<p><b><i><span>a</span></i><sub>0. </sub></b></p>'
        self.assertEqual(markdown(html), '***a*₀**.')

    def test_math_markup_whitespace_is_not_text(self):
        html = ('<table border="1"><tr><td>Алгоритм</td></tr><tr><td>'
                '<p>нц для i от 1 до 10</p>'
                '<p><span>    s = s + A[i] <m:math><m:mstyle> '
                '<m:semantics> <m:mo>–</m:mo> </m:semantics> '
                '</m:mstyle></m:math> A[i+1]</span></p>'
                '<p>кц</p></td></tr></table>')
        self.assertIn('    s = s + A[i] – A[i+1]\n', markdown(html))


class LayoutWrapperTest(unittest.TestCase):
    """Вёрсточная обёртка Word и настоящая таблица с данными."""

    WRAPPER = ('<table border="0" class="MsoNormalTable">'
               '<tr><td><img src="assets/images/a_1.png"></td>'
               '<td><b><i>Задание выполняется с использованием '
               'прилагаемых файлов.</i></b></td></tr>'
               '<tr><td colspan="2"><p> </p><p>{}</p><p> </p></td></tr>'
               '</table>')

    def test_notice_wrapper_unfolds_in_reading_order(self):
        body = ('В файле содержится последовательность натуральных чисел, '
                'найдите два идущих подряд элемента.')
        result = markdown(self.WRAPPER.format(body))
        self.assertNotIn('| --- |', result)
        self.assertLess(result.index('Задание выполняется'),
                        result.index('В файле содержится'))

    def test_full_width_row_alone_does_not_unfold_a_table(self):
        # Таблица с программами на пяти языках: столбец «Си» набран
        # строкой во всю ширину, но таблица остаётся таблицей.
        html = ('<table border="1">'
                '<tr><td>Паскаль</td><td>Python</td></tr>'
                '<tr><td><p>begin</p><p>  x := 1;</p><p>end.</p></td>'
                '<td><p>x = 1</p><p>if x:</p><p>  print(x)</p></td></tr>'
                '<tr><td colspan="2">Си</td></tr>'
                '<tr><td colspan="2"><p>int main()</p>'
                '<p>  { return 0; }</p><p>}</p></td></tr></table>')
        result = markdown(html)
        self.assertLess(result.index('**Паскаль**'), result.index('begin'))
        self.assertLess(result.index('begin'), result.index('**Python**'))
        self.assertLess(result.index('**Си**'), result.index('int main()'))

    def test_data_row_of_two_values_stays_a_table(self):
        html = '<table border="1"><tr><td>50</td><td>65</td></tr></table>'
        self.assertIn('| 50 | 65 |', markdown(html))

    def test_two_paragraph_header_cell_stays_a_table(self):
        html = ('<table border="1"><tr><td><p><b>Запрос</b></p></td>'
                '<td><p><b>Найдено страниц</b></p>'
                '<p><b>(в сотнях тысяч)</b></p></td></tr>'
                '<tr><td>Рыба</td><td>45</td></tr>'
                '<tr><td>Меч</td><td>69</td></tr></table>')
        result = markdown(html)
        self.assertIn('| Рыба | 45 |', result)
        self.assertIn('**Найдено страниц** **(в сотнях тысяч)**', result)


class ListingRecognitionTest(unittest.TestCase):
    """Что считается листингом программы."""

    def test_dense_c_line_does_not_reject_the_listing(self):
        html = ('<table border="1"><tr><td>С++</td></tr><tr><td>'
                '<p>{ int s, n;</p><p>  cin &gt;&gt; s;</p>'
                '<p>  while (s &lt; 47) { s = s + 4; n = n * 2; }</p>'
                '<p>  return 0;</p><p>}</p></td></tr></table>')
        result = markdown(html)
        self.assertIn(FENCE, result)
        self.assertIn('  while (s < 47) { s = s + 4; n = n * 2; }', result)

    def test_listing_split_by_line_breaks_becomes_a_block(self):
        html = ('<table border="1"><tr><td>Python</td></tr><tr><td><p><span>'
                'while x &lt;= 100:<i><span><br/></span></i>'
                '  K1 = K1 + 1<i><span><br/></span></i>'
                '  x = x + P</span></p></td></tr></table>')
        self.assertEqual(
            markdown(html),
            '**Python**\n\n' + FENCE + 'python\n'
            'while x <= 100:\n  K1 = K1 + 1\n  x = x + P\n' + FENCE)

    def test_listing_without_indentation_needs_a_language_label(self):
        cell = '<p>FOR n=1 TO 3</p><p>A(n)=n</p><p>NEXT n</p>'
        labelled = ('<table border="1"><tr><td>Бейсик</td><td>Паскаль</td>'
                    '</tr><tr><td>' + cell + '</td>'
                    '<td><p>for n:=1 to 3 do</p><p>  A[n]:=n;</p>'
                    '<p>end.</p></td></tr></table>')
        self.assertIn(FENCE + '\nFOR n=1 TO 3', markdown(labelled))
        plain = '<div>' + cell + '</div>'
        self.assertNotIn(FENCE, markdown(plain))

    def test_natural_language_column_is_not_code(self):
        html = ('<table border="1"><tr><td>Естественный язык</td></tr>'
                '<tr><td><p>Сложить два числа.</p>'
                '<p>Вывести результат.</p><p>Закончить.</p></td></tr>'
                '</table>')
        self.assertNotIn(FENCE, markdown(html))


class DocumentListingTest(unittest.TestCase):
    """Программа, набранная такими же абзацами, как окружающая проза."""

    PROGRAM = ('<p>НАЧАЛО</p><p>ПОКА  нашлось (47)</p>'
               '<p>         ЕСЛИ  нашлось (47)</p>'
               '<p>              ТО заменить (47, 74)</p>'
               '<p>         КОНЕЦ ЕСЛИ</p><p>КОНЕЦ ПОКА</p><p>КОНЕЦ</p>')

    def test_program_between_prose_becomes_a_block(self):
        html = ('<p>Напишите программу для исполнителя Редактор, которая '
                'обрабатывает строку и выдаёт результат.</p>'
                + self.PROGRAM +
                '<p>Определите, что будет на экране после выполнения этой '
                'программы для данной строки.</p>')
        result = markdown(html)
        self.assertEqual(result.count(FENCE), 2)
        self.assertIn('              ТО заменить (47, 74)', result)
        self.assertNotIn('Напишите программу', result[result.index(FENCE):])

    def test_introduction_stays_outside_the_block(self):
        html = '<p>Дана программа для Редактора:</p>' + self.PROGRAM
        result = markdown(html)
        self.assertTrue(result.startswith('Дана программа для Редактора:'))

    def test_single_word_introduction_stays_outside(self):
        html = ('<p>Цикл</p><p>ПОКА  условие</p>'
                '<p>         последовательность команд</p>'
                '<p>КОНЕЦ ПОКА</p>')
        self.assertTrue(markdown(html).startswith('Цикл\n\n' + FENCE))

    def test_sentence_ending_in_brackets_is_not_code(self):
        html = (self.PROGRAM +
                '<p>На вход программе поступает строка, начинающаяся '
                'с цифры «4», а затем содержащая n цифр «2» '
                '(3 &lt; n &lt; 2000).</p>')
        result = markdown(html)
        self.assertNotIn('На вход программе',
                         result[:result.rindex(FENCE) + 3])


class ImageSizeTest(unittest.TestCase):
    """Размер картинки читается по заголовку файла."""

    def test_png_header(self):
        header = (b'\x89PNG\r\n\x1a\n' + b'\x00\x00\x00\x0dIHDR'
                  + b'\x00\x00\x00\x31' + b'\x00\x00\x00\x2b'
                  + b'\x08\x06\x00\x00\x00')
        self.assertEqual(self._size(header, '.png'), (49, 43))

    def test_gif_header(self):
        header = b'GIF89a' + b'\xc8\x00' + b'\x2c\x00' + b'\x00' * 8
        self.assertEqual(self._size(header, '.gif'), (200, 44))

    def test_unknown_format_gives_none(self):
        self.assertIsNone(self._size(b'not an image at all', '.bin'))

    def _size(self, data, suffix):
        handle = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
        try:
            handle.write(data)
            handle.close()
            return image_size(handle.name)
        finally:
            os.unlink(handle.name)


if __name__ == '__main__':
    unittest.main()
