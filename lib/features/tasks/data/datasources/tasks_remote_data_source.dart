import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';

/// Низкоуровневый доступ к задачам, их файлам, справке и статистике.
abstract interface class TasksRemoteDataSource {
  /// Строки опубликованных задач по фильтру (без условия).
  Future<List<Map<String, dynamic>>> fetchTasks(TaskFilter filter);

  /// Строка задачи целиком; `null`, если задача не найдена.
  Future<Map<String, dynamic>?> fetchTask(String slug);

  /// Файлы задачи.
  Future<List<Map<String, dynamic>>> fetchFiles(String taskId);

  /// Связи задачи со статьями справочника вместе со статьями.
  Future<List<Map<String, dynamic>>> fetchArticleLinks(String taskId);

  /// Мои попытки: задача и признак верного ответа.
  Future<List<Map<String, dynamic>>> fetchMyAttempts();

  /// Номера заданий, по которым есть опубликованные задачи.
  Future<List<Map<String, dynamic>>> fetchEgeNumbers();

  /// Статистика решений по всем опубликованным задачам.
  Future<List<Map<String, dynamic>>> fetchStats();
}
