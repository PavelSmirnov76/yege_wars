import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/data/dto/task_dto.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_stats.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';

/// Реализация [TasksRepository] поверх [TasksRemoteDataSource].
final class TasksRepositoryImpl implements TasksRepository {
  /// Создаёт репозиторий поверх [TasksRemoteDataSource].
  const TasksRepositoryImpl(this._dataSource);

  static const String _taskMissing = 'Задача не найдена или ещё не открыта.';

  final TasksRemoteDataSource _dataSource;

  @override
  FutureResult<List<CatalogItem>> listCatalog(TaskFilter filter) async {
    try {
      // Три запроса независимы, поэтому идут одновременно.
      final responses = await Future.wait([
        _dataSource.fetchTasks(filter),
        _dataSource.fetchStats(),
        _dataSource.fetchMyAttempts(),
      ]);
      final stats = _statsById(responses[1]);
      final progress = _progressByTaskId(responses[2]);

      final items = <CatalogItem>[];
      for (final row in responses[0]) {
        final task = TaskDto.toBrief(row);
        final item = CatalogItem(
          task: task,
          progress: progress[task.id] ?? TaskProgress.notStarted,
          stats: stats[task.id] ?? const TaskStats(),
        );
        // Прогресс считается по своим попыткам, поэтому отбор по нему —
        // на клиенте: в базе такого признака нет.
        if (filter.progress == null || filter.progress == item.progress) {
          items.add(item);
        }
      }
      return Ok<List<CatalogItem>>(items);
    } on Object catch (error) {
      return Err<List<CatalogItem>>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<TaskDetail> getTask(String slug) async {
    try {
      final row = await _dataSource.fetchTask(slug);
      if (row == null) {
        return const Err<TaskDetail>(DatabaseFailure(message: _taskMissing));
      }
      final taskId = row[TaskColumns.id]! as String;
      final responses = await Future.wait([
        _dataSource.fetchFiles(taskId),
        _dataSource.fetchArticleLinks(taskId),
      ]);

      return Ok<TaskDetail>(
        TaskDto.toDetail(
          row,
          files: [for (final file in responses[0]) TaskDto.toFile(file)],
          articles: _articleLinks(responses[1]),
        ),
      );
    } on Object catch (error) {
      return Err<TaskDetail>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<List<int>> availableEgeNumbers() async {
    try {
      final rows = await _dataSource.fetchEgeNumbers();
      final numbers = <int>{
        for (final row in rows)
          if (row[TaskColumns.egeNumber] case final num value) value.toInt(),
      }.toList()..sort();
      return Ok<List<int>>(numbers);
    } on Object catch (error) {
      return Err<List<int>>(SupabaseErrorMapper.map(error));
    }
  }

  /// Статистика по идентификатору задачи.
  static Map<String, TaskStats> _statsById(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (TaskDto.toStatsEntry(row) case final entry?) entry.key: entry.value,
  };

  /// Мой прогресс по каждой задаче, где были попытки.
  static Map<String, TaskProgress> _progressByTaskId(
    List<Map<String, dynamic>> rows,
  ) {
    final attempts = <String, int>{};
    final correct = <String>{};
    for (final row in rows) {
      final taskId = row[SubmissionColumns.taskId];
      if (taskId is! String) {
        continue;
      }
      attempts[taskId] = (attempts[taskId] ?? 0) + 1;
      if (row[SubmissionColumns.isCorrect] == true) {
        correct.add(taskId);
      }
    }
    return {
      for (final entry in attempts.entries)
        entry.key: TaskProgress.fromAttempts(
          attempts: entry.value,
          hasCorrect: correct.contains(entry.key),
        ),
    };
  }

  /// Связи со статьями: сначала главные по теме.
  static List<TaskArticleLink> _articleLinks(List<Map<String, dynamic>> rows) {
    return <TaskArticleLink>[
      for (final row in rows) ?TaskDto.toArticleLink(row),
    ]..sort((a, b) {
      if (a.isPrimary == b.isPrimary) {
        return 0;
      }
      return a.isPrimary ? -1 : 1;
    });
  }
}
