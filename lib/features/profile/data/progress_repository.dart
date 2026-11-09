import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';

/// Запросы сводки и попыток по контракту ENT-18.
class ProgressDataSource {
  const ProgressDataSource(this.client);
  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> progress(String userId) async => client
      .rpc<List<Map<String, dynamic>>>(
        'get_user_progress',
        params: {'p_user_id': userId},
      )
      .retry(enabled: false);

  Future<List<Map<String, dynamic>>> attempts(String userId) async => client
      .from('submissions')
      .select(
        'id,task_id,is_correct,created_at,'
        'task:tasks!inner(id,slug,title,ege_number)',
      )
      .eq('user_id', userId)
      .eq('task.status', 'published')
      .order('created_at', ascending: false)
      .order('id', ascending: false)
      .limit(10)
      .retry(enabled: false);
}

/// Репозиторий сводки; ошибка любого запроса отменяет результат.
class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this.source);
  final ProgressDataSource source;

  @override
  FutureResult<ProgressSummary> getProgress(String userId) async {
    try {
      final responses = await Future.wait([
        source.progress(userId),
        source.attempts(userId),
      ], eagerError: true);
      final numbers =
          [
            for (final row in responses[0])
              NumberProgress(
                number: (row['ege_number'] as num?)?.toInt(),
                solved: (row['solved'] as num).toInt(),
                total: (row['total'] as num).toInt(),
              ),
          ]..sort(
            (a, b) => a.number == null
                ? (b.number == null ? 0 : 1)
                : (b.number == null ? -1 : a.number!.compareTo(b.number!)),
          );
      final attempts = [for (final row in responses[1]) _attempt(row)];
      return Ok(ProgressSummary(byNumber: numbers, attempts: attempts));
    } on Object catch (error) {
      return Err(SupabaseErrorMapper.map(error));
    }
  }

  RecentAttempt _attempt(Map<String, dynamic> row) {
    final task = row['task'] as Map<String, dynamic>;
    return RecentAttempt(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      slug: task['slug'] as String,
      title: task['title'] as String,
      number: (task['ege_number'] as num?)?.toInt(),
      correct: row['is_correct'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
