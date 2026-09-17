import 'dart:io';

import 'package:seed_tasks/seed_tasks.dart';
import 'package:test/test.dart';

TaskSeed task(String slug) => TaskSeed(
  slug: slug,
  egeNumber: 5,
  title: 'Задача $slug',
  statementMd: 'Условие.',
  difficulty: 1,
  answerFormat: 'single',
  files: const [],
  tags: const [],
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('seed_tasks_answers_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  File answersFile(String content) =>
      File('${tempDir.path}/answers.json')..writeAsStringSync(content);

  group('loadAnswers', () {
    test('читает JSON-объект slug -> ответ', () {
      final answers = loadAnswers(
        answersFile('{"e05-x": "42", "e17-y": "302 19011"}'),
      );
      expect(answers, {'e05-x': '42', 'e17-y': '302 19011'});
    });

    test('числовой ответ приводится к строке', () {
      final answers = loadAnswers(answersFile('{"e05-x": 42}'));
      expect(answers, {'e05-x': '42'});
    });

    test('ошибка: файл не найден', () {
      expect(
        () => loadAnswers(File('${tempDir.path}/нет.json')),
        throwsA(
          isA<SeedValidationException>().having(
            (error) => error.message,
            'message',
            contains('не найден'),
          ),
        ),
      );
    });

    test('ошибка: некорректный JSON', () {
      expect(
        () => loadAnswers(answersFile('{битый json')),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: не JSON-объект', () {
      expect(
        () => loadAnswers(answersFile('["e05-x"]')),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: ответ не строка и не число', () {
      expect(
        () => loadAnswers(answersFile('{"e05-x": ["42"]}')),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: пустой ответ', () {
      expect(
        () => loadAnswers(answersFile('{"e05-x": "  "}')),
        throwsA(
          isA<SeedValidationException>().having(
            (error) => error.message,
            'message',
            contains('e05-x'),
          ),
        ),
      );
    });
  });

  group('checkAnswers', () {
    test('находит недостающие и лишние slug, списки отсортированы', () {
      final check = checkAnswers(
        tasks: [task('b-task'), task('a-task'), task('c-task')],
        answers: {'c-task': '1', 'z-extra': '2', 'a-extra': '3'},
      );
      expect(check.missing, ['a-task', 'b-task']);
      expect(check.extra, ['a-extra', 'z-extra']);
    });

    test('полное совпадение — пустые списки', () {
      final check = checkAnswers(
        tasks: [task('a-task')],
        answers: {'a-task': '1'},
      );
      expect(check.missing, isEmpty);
      expect(check.extra, isEmpty);
    });
  });
}
