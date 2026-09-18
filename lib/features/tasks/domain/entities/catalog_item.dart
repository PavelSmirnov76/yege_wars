import 'package:meta/meta.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_stats.dart';

/// Строка каталога: задача, мой прогресс по ней и статистика класса.
@immutable
final class CatalogItem {
  /// Создаёт строку каталога.
  const CatalogItem({
    required this.task,
    this.progress = TaskProgress.notStarted,
    this.stats = const TaskStats(),
  });

  /// Задача.
  final TaskBrief task;

  /// Мой прогресс.
  final TaskProgress progress;

  /// Статистика по ученикам.
  final TaskStats stats;
}
