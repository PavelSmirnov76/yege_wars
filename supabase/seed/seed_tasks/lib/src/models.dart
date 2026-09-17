/// Полностью проверенная задача банка, готовая к загрузке в БД.
class TaskSeed {
  const TaskSeed({
    required this.slug,
    required this.egeNumber,
    required this.title,
    required this.statementMd,
    required this.difficulty,
    required this.answerFormat,
    required this.files,
    required this.tags,
    this.source,
  });

  final String slug;
  final int egeNumber;
  final String title;
  final String statementMd;
  final int difficulty;
  final String answerFormat;

  /// Пути файлов данных задачи вида `task_files/<ege_number>/<slug>/<имя>`.
  final List<String> files;
  final List<String> tags;
  final String? source;
}
