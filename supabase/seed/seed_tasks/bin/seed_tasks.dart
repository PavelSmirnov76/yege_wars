import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:seed_tasks/seed_tasks.dart';

Future<void> main(List<String> args) async {
  final SeedOptions options;
  try {
    options = parseSeedOptions(args);
  } on FormatException catch (error) {
    stderr
      ..writeln('Ошибка в аргументах: ${error.message}')
      ..writeln()
      ..writeln(_usage());
    exitCode = 2;
    return;
  }
  if (options.help) {
    stdout.writeln(_usage());
    return;
  }

  // 1. Сканирование и валидация банка задач.
  final scan = scanBank(Directory(options.tasksDir));
  if (scan.errors.isNotEmpty) {
    stderr.writeln('Ошибки валидации банка задач:');
    for (final error in scan.errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }
  if (scan.tasks.isEmpty) {
    stderr.writeln(
      'В каталоге «${options.tasksDir}» не найдено ни одной задачи '
      '(ожидается структура tasks/<ege_number>/<slug>/task.yaml).',
    );
    exitCode = 1;
    return;
  }

  // 2. Файл ответов: для каждого slug банка должен быть ответ.
  final Map<String, String> answers;
  try {
    answers = loadAnswers(File(options.answersPath));
  } on SeedValidationException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
    return;
  }
  final check = checkAnswers(tasks: scan.tasks, answers: answers);
  if (check.missing.isNotEmpty) {
    stderr.writeln(
      'В файле ответов «${options.answersPath}» нет ответов для задач:',
    );
    for (final slug in check.missing) {
      stderr.writeln('  - $slug');
    }
    exitCode = 1;
    return;
  }
  if (check.extra.isNotEmpty) {
    stdout.writeln(
      'Предупреждение: в файле ответов есть slug, которых нет в банке: '
      '${check.extra.join(', ')}',
    );
  }

  // 3. План загрузки.
  final publish = !options.unpublished;
  _printPlan(scan.tasks, publish: publish);
  if (options.dryRun) {
    stdout.writeln('Режим --dry-run: подключение к БД не выполнялось.');
    return;
  }

  // 4. Строка подключения — только из окружения.
  final url = Platform.environment['SEED_DATABASE_URL'];
  if (url == null || url.trim().isEmpty) {
    stderr
      ..writeln('Не задана переменная окружения SEED_DATABASE_URL.')
      ..writeln(
        'Ожидается строка подключения вида '
        'postgres://user:pass@host:port/db.',
      );
    exitCode = 2;
    return;
  }
  final DatabaseConfig config;
  try {
    config = parseDatabaseUrl(url.trim());
  } on SeedValidationException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
    return;
  }

  // 5. Загрузка в одной транзакции.
  final Connection connection;
  try {
    connection = await Connection.open(
      config.endpoint,
      settings: ConnectionSettings(sslMode: config.sslMode),
    );
  } on Exception catch (error) {
    stderr.writeln('Не удалось подключиться к базе данных: $error');
    exitCode = 1;
    return;
  }
  try {
    final result = await seedBank(
      connection: connection,
      tasks: scan.tasks,
      answers: answers,
      publish: publish,
    );
    _printResult(result);
  } on Exception catch (error) {
    stderr.writeln('Ошибка при загрузке в базу данных: $error');
    exitCode = 1;
  } finally {
    await connection.close();
  }
}

void _printPlan(List<TaskSeed> tasks, {required bool publish}) {
  stdout.writeln(
    'План загрузки: задач ${tasks.length}, is_published = $publish.',
  );
  for (final task in tasks) {
    stdout.writeln(
      '  - [№${task.egeNumber}] ${task.slug} — '
      'сложность ${task.difficulty}, формат ${task.answerFormat}, '
      'файлов данных: ${task.files.length}',
    );
  }
}

void _printResult(SeedResult result) {
  stdout.writeln(
    'Готово. Вставлено задач: ${result.inserted.length}, '
    'обновлено: ${result.updated.length}.',
  );
  if (result.inserted.isNotEmpty) {
    stdout.writeln('Вставлены: ${result.inserted.join(', ')}');
  }
  if (result.updated.isNotEmpty) {
    stdout.writeln('Обновлены: ${result.updated.join(', ')}');
  }
}

String _usage() {
  return 'Сид банка задач ЕГЭ в Supabase/PostgreSQL.\n'
      '\n'
      'Использование: dart run bin/seed_tasks.dart [параметры]\n'
      '\n'
      '${buildArgParser().usage}\n'
      '\n'
      'Строка подключения берётся только из переменной окружения '
      'SEED_DATABASE_URL\n(postgres://user:pass@host:port/db); '
      'без неё скрипт завершается с кодом 2.';
}
