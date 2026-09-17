import 'dart:io';

import 'package:seed_tasks/seed_tasks.dart';
import 'package:test/test.dart';

/// Минимальный корректный task.yaml для тестов.
String taskYaml({
  required String slug,
  required int egeNumber,
  String answerFormat = 'single',
}) =>
    'slug: $slug\n'
    'title: Задача $slug\n'
    'ege_number: $egeNumber\n'
    'difficulty: 1\n'
    'answer_format: $answerFormat\n';

void main() {
  late Directory bankDir;

  setUp(() {
    bankDir = Directory.systemTemp.createTempSync('seed_tasks_bank_');
  });

  tearDown(() {
    bankDir.deleteSync(recursive: true);
  });

  /// Создаёт папку задачи `<egeDir>/<slug>` с указанными файлами.
  ///
  /// `yaml`/`statement` со значением null — файл не создаётся.
  void createTask({
    required String egeDir,
    required String slug,
    String? yaml,
    String? statement = 'Условие задачи.',
    Iterable<String> dataFiles = const [],
  }) {
    final dirPath = '${bankDir.path}/$egeDir/$slug';
    Directory(dirPath).createSync(recursive: true);
    if (yaml != null) {
      File('$dirPath/task.yaml').writeAsStringSync(yaml);
    }
    if (statement != null) {
      File('$dirPath/statement.md').writeAsStringSync(statement);
    }
    for (final name in dataFiles) {
      File('$dirPath/$name').writeAsStringSync('данные');
    }
  }

  group('scanBank', () {
    test('находит валидную задачу и строит список файлов данных', () {
      createTask(
        egeDir: '17',
        slug: 'e17-x',
        yaml: taskYaml(slug: 'e17-x', egeNumber: 17, answerFormat: 'pair'),
        statement: '# Условие\n\nТекст.',
        dataFiles: ['17_B.txt', '17_A.txt'],
      );
      final result = scanBank(bankDir);
      expect(result.errors, isEmpty);
      expect(result.tasks, hasLength(1));
      final task = result.tasks.single;
      expect(task.slug, 'e17-x');
      expect(task.egeNumber, 17);
      expect(task.answerFormat, 'pair');
      expect(task.statementMd, '# Условие\n\nТекст.');
      expect(task.files, [
        'task_files/17/e17-x/17_A.txt',
        'task_files/17/e17-x/17_B.txt',
      ]);
    });

    test('сортирует задачи по (ege_number, slug)', () {
      createTask(
        egeDir: '17',
        slug: 'e17-b',
        yaml: taskYaml(slug: 'e17-b', egeNumber: 17),
      );
      createTask(
        egeDir: '17',
        slug: 'e17-a',
        yaml: taskYaml(slug: 'e17-a', egeNumber: 17),
      );
      createTask(
        egeDir: '2',
        slug: 'e02-a',
        yaml: taskYaml(slug: 'e02-a', egeNumber: 2),
      );
      final result = scanBank(bankDir);
      expect(result.errors, isEmpty);
      expect(result.tasks.map((task) => task.slug), [
        'e02-a',
        'e17-a',
        'e17-b',
      ]);
    });

    test('пропускает нечисловые каталоги верхнего уровня', () {
      createTask(
        egeDir: 'drafts',
        slug: 'e05-x',
        yaml: taskYaml(slug: 'e05-x', egeNumber: 5),
      );
      final result = scanBank(bankDir);
      expect(result.errors, isEmpty);
      expect(result.tasks, isEmpty);
    });

    test('ошибка: slug не совпадает с именем папки', () {
      createTask(
        egeDir: '5',
        slug: 'e05-folder',
        yaml: taskYaml(slug: 'e05-other', egeNumber: 5),
      );
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('slug'));
      expect(result.errors.single, contains('e05-folder'));
    });

    test('ошибка: ege_number не совпадает с папкой номера', () {
      createTask(
        egeDir: '5',
        slug: 'e05-x',
        yaml: taskYaml(slug: 'e05-x', egeNumber: 6),
      );
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('ege_number'));
    });

    test('ошибка: отсутствует task.yaml', () {
      createTask(egeDir: '5', slug: 'e05-x');
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('task.yaml'));
    });

    test('ошибка: отсутствует statement.md', () {
      createTask(
        egeDir: '5',
        slug: 'e05-x',
        yaml: taskYaml(slug: 'e05-x', egeNumber: 5),
        statement: null,
      );
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('statement.md'));
    });

    test('ошибка: statement.md пуст', () {
      createTask(
        egeDir: '5',
        slug: 'e05-x',
        yaml: taskYaml(slug: 'e05-x', egeNumber: 5),
        statement: '   \n',
      );
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('пуст'));
    });

    test('ошибка: некорректный task.yaml с путём до файла', () {
      createTask(
        egeDir: '5',
        slug: 'e05-x',
        yaml: 'slug: [незакрытая',
      );
      final result = scanBank(bankDir);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('task.yaml'));
    });

    test('ошибка: дубликат slug в разных папках номера', () {
      createTask(
        egeDir: '5',
        slug: 'e-dup',
        yaml: taskYaml(slug: 'e-dup', egeNumber: 5),
      );
      createTask(
        egeDir: '17',
        slug: 'e-dup',
        yaml: taskYaml(slug: 'e-dup', egeNumber: 17),
      );
      final result = scanBank(bankDir);
      expect(result.errors.single, contains('Дубликаты slug'));
      expect(result.errors.single, contains('e-dup'));
    });

    test('ошибка: каталог банка не существует', () {
      final missing = Directory('${bankDir.path}/нет-такой-папки');
      final result = scanBank(missing);
      expect(result.tasks, isEmpty);
      expect(result.errors.single, contains('не найден'));
    });
  });
}
