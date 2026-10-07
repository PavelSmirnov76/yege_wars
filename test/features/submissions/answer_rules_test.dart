import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/submissions/domain/answer_rules.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';

void main() {
  group('AnswerFormat.fromValue', () {
    test('знает все форматы базы', () {
      expect(AnswerFormat.fromValue('single'), AnswerFormat.single);
      expect(AnswerFormat.fromValue('pair'), AnswerFormat.pair);
      expect(AnswerFormat.fromValue('multi'), AnswerFormat.multi);
      expect(AnswerFormat.fromValue('string'), AnswerFormat.string);
    });

    test('неизвестное или пустое значение — строка, без падения', () {
      expect(AnswerFormat.fromValue('matrix'), AnswerFormat.string);
      expect(AnswerFormat.fromValue(null), AnswerFormat.string);
    });
  });

  group('AnswerRules.fromOutput', () {
    test('multi: таблица по строкам превращается в одну строку', () {
      expect(
        AnswerRules.fromOutput('108 54\n136 68\n164 82\n', AnswerFormat.multi),
        '108 54 136 68 164 82',
      );
    });

    test('multi: пустые строки и пробельные края выбрасываются', () {
      expect(
        AnswerRules.fromOutput(
          '\n  108 54  \n\n\t136 68\r\n   \n',
          AnswerFormat.multi,
        ),
        '108 54 136 68',
      );
    });

    test('single: последняя непустая строка вывода', () {
      expect(
        AnswerRules.fromOutput('отладка\n446\n\n', AnswerFormat.single),
        '446',
      );
    });

    test('pair: последняя строка, а не весь вывод', () {
      expect(
        AnswerRules.fromOutput('1 2\n  10 20 \n', AnswerFormat.pair),
        '10 20',
      );
    });

    test('string: последняя строка без пробельных краёв', () {
      expect(
        AnswerRules.fromOutput('черновик\n  бвгд \r\n\n', AnswerFormat.string),
        'бвгд',
      );
    });

    test('пустой вывод — пустой ответ при любом формате', () {
      for (final format in AnswerFormat.values) {
        expect(AnswerRules.fromOutput('', format), isEmpty, reason: '$format');
        expect(
          AnswerRules.fromOutput('\n \n\t\n', format),
          isEmpty,
          reason: '$format',
        );
      }
    });
  });
}
