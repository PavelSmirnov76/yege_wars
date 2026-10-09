import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/editor/data/datasources/draft_remote_data_source.dart';

/// Реализация [DraftRemoteDataSource] поверх [SupabaseClient].
///
/// Пишет upsert по ключу (пользователь, задача) и удаляет строку напрямую,
/// без RPC: только автора и только по видимой задаче пускает RLS.
///
/// Реализует UC-31.
final class SupabaseDraftRemoteDataSource implements DraftRemoteDataSource {
  /// Создаёт datasource поверх клиента [SupabaseClient].
  const SupabaseDraftRemoteDataSource(this._client);

  /// Ключ строки: по нему upsert находит, что перезаписать.
  static const String _conflictKey =
      '${DraftColumns.userId},${DraftColumns.taskId}';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchDraft(String taskId) async => _client
      .from(SupabaseTables.drafts)
      .select(DraftColumns.code)
      .eq(DraftColumns.userId, _userId)
      .eq(DraftColumns.taskId, taskId)
      .maybeSingle();

  @override
  Future<void> upsertDraft({
    required String taskId,
    required String code,
  }) async {
    await _client.from(SupabaseTables.drafts).upsert({
      DraftColumns.userId: _userId,
      DraftColumns.taskId: taskId,
      DraftColumns.code: code,
    }, onConflict: _conflictKey);
  }

  @override
  Future<void> deleteDraft(String taskId) async {
    await _client
        .from(SupabaseTables.drafts)
        .delete()
        .eq(DraftColumns.userId, _userId)
        .eq(DraftColumns.taskId, taskId);
  }

  /// Текущий пользователь: без сессии черновика нет.
  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthSessionMissingException();
    }
    return userId;
  }
}
