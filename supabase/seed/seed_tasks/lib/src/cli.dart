import 'package:args/args.dart';

/// Каталог банка задач по умолчанию (относительно корня репозитория).
const String defaultTasksDir = 'tasks';

/// Файл ответов по умолчанию (не попадает в git).
const String defaultAnswersPath = 'supabase/seed/local/answers.local.json';

/// Разобранные параметры запуска сид-скрипта.
class SeedOptions {
  const SeedOptions({
    required this.tasksDir,
    required this.answersPath,
    required this.dryRun,
    required this.unpublished,
    required this.help,
  });

  final String tasksDir;
  final String answersPath;
  final bool dryRun;
  final bool unpublished;
  final bool help;
}

/// Описание аргументов командной строки.
ArgParser buildArgParser() {
  return ArgParser()
    ..addOption(
      'tasks-dir',
      defaultsTo: defaultTasksDir,
      help: 'Каталог банка задач (tasks/<ege_number>/<slug>/).',
    )
    ..addOption(
      'answers',
      defaultsTo: defaultAnswersPath,
      help: 'JSON-файл с ответами вида {"<slug>": "<ответ>", ...}.',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Только валидация и план, без подключения к БД.',
    )
    ..addFlag(
      'unpublished',
      negatable: false,
      help: 'Загрузить задачи с is_published = false.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Показать справку.',
    );
}

/// Разбирает аргументы командной строки.
///
/// Бросает [FormatException] при неизвестных аргументах.
SeedOptions parseSeedOptions(List<String> args) {
  final results = buildArgParser().parse(args);
  return SeedOptions(
    tasksDir: results['tasks-dir'] as String,
    answersPath: results['answers'] as String,
    dryRun: results['dry-run'] as bool,
    unpublished: results['unpublished'] as bool,
    help: results['help'] as bool,
  );
}
