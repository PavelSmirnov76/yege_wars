import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';

/// Низкоуровневый доступ к задачам, их файлам, справке и статистике.
abstract interface class TasksRemoteDataSource {
  /// Строки опубликованных задач по фильтру (без условия).
  Future<List<Map<String, dynamic>>> fetchTasks(TaskFilter filter);

  /// Строка задачи целиком; `null`, если задача не найдена.
  Future<Map<String, dynamic>?> fetchTask(String slug);

  /// Файлы задачи.
  Future<List<Map<String, dynamic>>> fetchFiles(String taskId);

  /// Ручные связи задачи со статьями справочника вместе со статьями.
  Future<List<Map<String, dynamic>>> fetchArticleLinks(String taskId);

  /// Статьи, которые полагаются задаче по её темам: идентификатор статьи
  /// и порядок темы.
  Future<List<Map<String, dynamic>>> fetchThemeArticles(String taskId);

  /// Карточки статей справочника по идентификаторам [articleIds].
  Future<List<Map<String, dynamic>>> fetchArticles(List<String> articleIds);

  /// Мои попытки: задача и признак верного ответа.
  Future<List<Map<String, dynamic>>> fetchMyAttempts();

  /// Номера заданий, по которым есть опубликованные задачи.
  Future<List<Map<String, dynamic>>> fetchEgeNumbers();

  /// Статистика решений по всем опубликованным задачам.
  Future<List<Map<String, dynamic>>> fetchStats();
}
