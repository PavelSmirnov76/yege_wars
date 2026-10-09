/// Низкоуровневый доступ к черновикам кода текущего пользователя.
abstract interface class DraftRemoteDataSource {
  /// Строка черновика задачи [taskId]; `null`, если черновика нет.
  Future<Map<String, dynamic>?> fetchDraft(String taskId);

  /// Записывает черновик задачи [taskId] поверх прежнего.
  Future<void> upsertDraft({required String taskId, required String code});

  /// Удаляет черновик задачи [taskId].
  Future<void> deleteDraft(String taskId);
}
