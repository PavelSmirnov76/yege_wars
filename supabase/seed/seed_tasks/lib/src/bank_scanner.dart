import 'dart:io';

import 'package:seed_tasks/src/exceptions.dart';
import 'package:seed_tasks/src/models.dart';
import 'package:seed_tasks/src/task_files.dart';
import 'package:seed_tasks/src/task_yaml.dart';

/// Результат сканирования банка задач: валидные задачи и список ошибок.
class BankScanResult {
  const BankScanResult({required this.tasks, required this.errors});

  final List<TaskSeed> tasks;
  final List<String> errors;
}

/// Сканирует каталог банка задач вида `tasks/<ege_number>/<slug>/task.yaml`.
///
/// Каталоги верхнего уровня с нечисловыми именами пропускаются.
/// Все найденные проблемы собираются в [BankScanResult.errors]
/// (с путём до файла), валидные задачи сортируются по (ege_number, slug).
BankScanResult scanBank(Directory tasksDir) {
  if (!tasksDir.existsSync()) {
    return BankScanResult(
      tasks: const [],
      errors: ['Каталог банка задач не найден: ${tasksDir.path}'],
    );
  }
  final errors = <String>[];
  final tasks = <TaskSeed>[];
  final numberDirs = tasksDir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final numberDir in numberDirs) {
    final egeNumber = int.tryParse(_baseName(numberDir));
    if (egeNumber == null) {
      // Не номер задания (например, служебная папка) — пропускаем.
      continue;
    }
    final taskDirs = numberDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final taskDir in taskDirs) {
      _scanTaskDir(
        taskDir: taskDir,
        dirEgeNumber: egeNumber,
        tasks: tasks,
        errors: errors,
      );
    }
  }
  _checkDuplicateSlugs(tasks, errors);
  tasks.sort((a, b) {
    final byNumber = a.egeNumber.compareTo(b.egeNumber);
    return byNumber != 0 ? byNumber : a.slug.compareTo(b.slug);
  });
  return BankScanResult(tasks: tasks, errors: errors);
}

void _scanTaskDir({
  required Directory taskDir,
  required int dirEgeNumber,
  required List<TaskSeed> tasks,
  required List<String> errors,
}) {
  final slugDirName = _baseName(taskDir);
  final yamlFile = File('${taskDir.path}/task.yaml');
  if (!yamlFile.existsSync()) {
    errors.add('${taskDir.path}: отсутствует task.yaml');
    return;
  }
  final TaskYaml meta;
  try {
    meta = TaskYaml.parse(yamlFile.readAsStringSync());
  } on SeedValidationException catch (error) {
    errors.add('${yamlFile.path}: ${error.message}');
    return;
  }
  var valid = true;
  if (meta.slug != slugDirName) {
    errors.add(
      '${yamlFile.path}: slug «${meta.slug}» не совпадает '
      'с именем папки «$slugDirName»',
    );
    valid = false;
  }
  if (meta.egeNumber != dirEgeNumber) {
    errors.add(
      '${yamlFile.path}: ege_number ${meta.egeNumber} не совпадает '
      'с папкой номера «$dirEgeNumber»',
    );
    valid = false;
  }
  final statementFile = File('${taskDir.path}/statement.md');
  var statement = '';
  if (!statementFile.existsSync()) {
    errors.add('${taskDir.path}: отсутствует statement.md');
    valid = false;
  } else {
    statement = statementFile.readAsStringSync();
    if (statement.trim().isEmpty) {
      errors.add('${statementFile.path}: файл условия пуст');
      valid = false;
    }
  }
  if (!valid) {
    return;
  }
  final fileNames = taskDir.listSync().whereType<File>().map(_baseName);
  tasks.add(
    TaskSeed(
      slug: meta.slug,
      egeNumber: meta.egeNumber,
      title: meta.title,
      statementMd: statement,
      difficulty: meta.difficulty,
      answerFormat: meta.answerFormat,
      files: buildTaskFiles(
        egeNumber: meta.egeNumber,
        slug: meta.slug,
        fileNames: fileNames,
      ),
      tags: meta.tags,
      source: meta.source,
    ),
  );
}

void _checkDuplicateSlugs(List<TaskSeed> tasks, List<String> errors) {
  final byPresence = <String, int>{};
  for (final task in tasks) {
    byPresence[task.slug] = (byPresence[task.slug] ?? 0) + 1;
  }
  final duplicates = byPresence.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toList();
  if (duplicates.isNotEmpty) {
    errors.add(
      'Дубликаты slug в банке (slug должен быть уникален): '
      '${duplicates.join(', ')}',
    );
  }
}

/// Имя последнего сегмента пути без зависимости от package:path.
String _baseName(FileSystemEntity entity) =>
    entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
