/// Низкоуровневый доступ к попыткам решения.
abstract interface class SubmissionsRemoteDataSource {
  /// Отправляет ответ через RPC и возвращает её ответ.
  Future<Map<String, dynamic>> submit({
    required String taskId,
    required String answer,
    required String code,
  });

  /// Мои попытки по задаче.
  Future<List<Map<String, dynamic>>> fetchMyAttempts(String taskId);

  /// Чужие опубликованные решения задачи.
  Future<List<Map<String, dynamic>>> fetchPublishedSolutions(String taskId);

  /// Публикует или снимает с публикации попытку.
  Future<void> setPublished({
    required String submissionId,
    required bool isPublished,
  });
}
