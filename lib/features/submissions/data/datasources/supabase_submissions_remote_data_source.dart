import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/submissions/data/datasources/submissions_remote_data_source.dart';

/// Реализация [SubmissionsRemoteDataSource] поверх [SupabaseClient].
///
/// Реализует UC-19.
final class SupabaseSubmissionsRemoteDataSource
    implements SubmissionsRemoteDataSource {
  /// Создаёт datasource поверх клиента [SupabaseClient].
  const SupabaseSubmissionsRemoteDataSource(this._client);

  /// Колонки своей попытки.
  static const String _mineColumns =
      '${SubmissionColumns.id}, ${SubmissionColumns.answer}, '
      '${SubmissionColumns.code}, ${SubmissionColumns.isCorrect}, '
      '${SubmissionColumns.isPublished}, ${SubmissionColumns.createdAt}';

  /// Колонки чужого решения: вместе с логином автора.
  static const String _publishedColumns =
      '${SubmissionColumns.id}, ${SubmissionColumns.answer}, '
      '${SubmissionColumns.code}, ${SubmissionColumns.isCorrect}, '
      '${SubmissionColumns.isPublished}, ${SubmissionColumns.createdAt}, '
      '${SupabaseTables.profiles}(${ProfileColumns.username})';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> submit({
    required String taskId,
    required String answer,
    required String code,
  }) => _client.rpc<Map<String, dynamic>>(
    SupabaseRpc.submitSolution,
    params: {
      'p_task_id': taskId,
      'p_code': code,
      'p_answer': answer,
    },
  );

  @override
  Future<List<Map<String, dynamic>>> fetchMyAttempts(String taskId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    return _client
        .from(SupabaseTables.submissions)
        .select(_mineColumns)
        .eq(SubmissionColumns.taskId, taskId)
        .eq(SubmissionColumns.userId, userId)
        .order(SubmissionColumns.createdAt, ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPublishedSolutions(
    String taskId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    // Свои решения в чужих не показываем; остальное отсекает политика
    // доступа: чужое видно только тому, кто сам решил задачу верно.
    var query = _client
        .from(SupabaseTables.submissions)
        .select(_publishedColumns)
        .eq(SubmissionColumns.taskId, taskId)
        .eq(SubmissionColumns.isPublished, true);
    if (userId != null) {
      query = query.neq(SubmissionColumns.userId, userId);
    }
    return query.order(SubmissionColumns.createdAt, ascending: false);
  }

  @override
  Future<void> setPublished({
    required String submissionId,
    required bool isPublished,
  }) => _client.rpc<void>(
    SupabaseRpc.setSolutionPublished,
    params: {
      'p_submission_id': submissionId,
      'p_published': isPublished,
    },
  );
}
