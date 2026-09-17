import 'package:seed_tasks/seed_tasks.dart';
import 'package:test/test.dart';

const _validYaml = '''
slug: e17-pairs-file
title: "Задание 17. Пары чисел в файле"
ege_number: 17
difficulty: 2
answer_format: pair
tags:
  - обработка файлов
  - делимость
source: "Оригинальная задача"
''';

void main() {
  group('TaskYaml.parse', () {
    test('разбирает корректный task.yaml', () {
      final meta = TaskYaml.parse(_validYaml);
      expect(meta.slug, 'e17-pairs-file');
      expect(meta.title, 'Задание 17. Пары чисел в файле');
      expect(meta.egeNumber, 17);
      expect(meta.difficulty, 2);
      expect(meta.answerFormat, 'pair');
      expect(meta.tags, ['обработка файлов', 'делимость']);
      expect(meta.source, 'Оригинальная задача');
    });

    test('tags и source необязательны', () {
      final meta = TaskYaml.parse('''
slug: e5-simple
title: Задание 5
ege_number: 5
difficulty: 1
answer_format: single
''');
      expect(meta.tags, isEmpty);
      expect(meta.source, isNull);
    });

    test('ошибка: не YAML-объект', () {
      expect(
        () => TaskYaml.parse('- просто\n- список\n'),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: битый YAML', () {
      expect(
        () => TaskYaml.parse('slug: [незакрытая'),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: отсутствует slug', () {
      expect(
        () => TaskYaml.parse('''
title: Без slug
ege_number: 5
difficulty: 1
answer_format: single
'''),
        throwsA(
          isA<SeedValidationException>().having(
            (error) => error.message,
            'message',
            contains('slug'),
          ),
        ),
      );
    });

    test('ошибка: ege_number вне диапазона 2..27', () {
      for (final number in [1, 28, 0]) {
        expect(
          () => TaskYaml.parse('''
slug: x
title: x
ege_number: $number
difficulty: 1
answer_format: single
'''),
          throwsA(isA<SeedValidationException>()),
          reason: 'ege_number = $number',
        );
      }
    });

    test('ошибка: ege_number не число', () {
      expect(
        () => TaskYaml.parse('''
slug: x
title: x
ege_number: "17"
difficulty: 1
answer_format: single
'''),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: difficulty вне 1..3', () {
      for (final difficulty in [0, 4]) {
        expect(
          () => TaskYaml.parse('''
slug: x
title: x
ege_number: 5
difficulty: $difficulty
answer_format: single
'''),
          throwsA(isA<SeedValidationException>()),
          reason: 'difficulty = $difficulty',
        );
      }
    });

    test('ошибка: неизвестный answer_format', () {
      expect(
        () => TaskYaml.parse('''
slug: x
title: x
ege_number: 5
difficulty: 1
answer_format: number
'''),
        throwsA(
          isA<SeedValidationException>().having(
            (error) => error.message,
            'message',
            contains('answer_format'),
          ),
        ),
      );
    });

    test('принимает все 4 формата ответа', () {
      for (final format in answerFormats) {
        final meta = TaskYaml.parse('''
slug: x
title: x
ege_number: 5
difficulty: 1
answer_format: $format
''');
        expect(meta.answerFormat, format);
      }
    });

    test('ошибка: tags не список строк', () {
      expect(
        () => TaskYaml.parse('''
slug: x
title: x
ege_number: 5
difficulty: 1
answer_format: single
tags: просто строка
'''),
        throwsA(isA<SeedValidationException>()),
      );
      expect(
        () => TaskYaml.parse('''
slug: x
title: x
ege_number: 5
difficulty: 1
answer_format: single
tags:
  - 1
'''),
        throwsA(isA<SeedValidationException>()),
      );
    });
  });
}
