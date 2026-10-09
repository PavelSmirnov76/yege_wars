import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/editor/data/datasources/draft_remote_data_source.dart';
import 'package:yege_wars/features/editor/domain/repositories/draft_repository.dart';

/// Реализация [DraftRepository] поверх [DraftRemoteDataSource].
///
/// Записи одной задачи идут по очереди: следующая уходит, когда пришёл ответ
/// на предыдущую, — иначе старый код мог бы лечь в базу поверх нового.
/// Загрузка ждёт незаконченной записи той же задачи: ушёл со страницы и
/// сразу вернулся — откроется то, что записано при уходе.
///
/// Реализует UC-31.
final class DraftRepositoryImpl implements DraftRepository {
  /// Создаёт репозиторий поверх [DraftRemoteDataSource].
  DraftRepositoryImpl(this._dataSource);

  final DraftRemoteDataSource _dataSource;

  /// Последняя запись в очереди каждой задачи: завершается, когда её ответ
  /// пришёл.
  final Map<String, Completer<void>> _writes = {};

  @override
  FutureResult<String?> load(String taskId) async {
    await _writes[taskId]?.future;
    try {
      final row = await _dataSource.fetchDraft(taskId);
      return Ok<String?>(row == null ? null : row[DraftColumns.code] as String);
    } on Object catch (error) {
      return Err<String?>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<void> save(String taskId, String code) => _enqueue(
    taskId,
    () => _dataSource.upsertDraft(taskId: taskId, code: code),
  );

  @override
  FutureResult<void> delete(String taskId) =>
      _enqueue(taskId, () => _dataSource.deleteDraft(taskId));

  /// Ставит запись [write] задачи [taskId] в очередь за предыдущей.
  FutureResult<void> _enqueue(
    String taskId,
    Future<void> Function() write,
  ) async {
    // До первого await — синхронно: очередь встаёт в порядке вызовов.
    final previous = _writes[taskId];
    final turn = Completer<void>();
    _writes[taskId] = turn;
    await previous?.future;
    try {
      return await _attempt(write);
    } finally {
      turn.complete();
      // Очередь задачи опустела — ключ больше не нужен.
      if (identical(_writes[taskId], turn)) {
        _writes.remove(taskId);
      }
    }
  }

  /// Выполняет запись и переводит её исход в [Result].
  static FutureResult<void> _attempt(Future<void> Function() write) async {
    try {
      await write();
      return const Ok<void>(null);
    } on Object catch (error) {
      return Err<void>(SupabaseErrorMapper.map(error));
    }
  }
}
