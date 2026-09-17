/// Служебные файлы задачи — не являются файлами данных.
const Set<String> _serviceFiles = {'task.yaml', 'statement.md'};

/// Строит отсортированный список путей файлов данных задачи в формате
/// `task_files/<ege_number>/<slug>/<имя файла>`.
///
/// Служебные файлы (task.yaml, statement.md) и скрытые файлы
/// (начинающиеся с точки, например .DS_Store) пропускаются.
List<String> buildTaskFiles({
  required int egeNumber,
  required String slug,
  required Iterable<String> fileNames,
}) {
  final names =
      fileNames
          .where(
            (name) => !_serviceFiles.contains(name) && !name.startsWith('.'),
          )
          .toList()
        ..sort();
  return [for (final name in names) 'task_files/$egeNumber/$slug/$name'];
}
