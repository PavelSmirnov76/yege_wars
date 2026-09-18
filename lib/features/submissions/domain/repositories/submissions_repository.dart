import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';

/// Отправка ответов и работа с попытками.
///
/// Сравнение с эталоном выполняет база: ответ задачи клиенту недоступен.
abstract interface class SubmissionsRepository {
  /// Отправляет ответ на проверку.
  FutureResult<SubmitResult> submit({
    required String taskId,
    required String answer,
    String code,
  });

  /// Мои попытки по задаче, сначала свежие.
  FutureResult<List<Submission>> myAttempts(String taskId);

  /// Опубликованные решения других учеников.
  ///
  /// База отдаёт их только тому, кто сам верно решил задачу.
  FutureResult<List<Submission>> publishedSolutions(String taskId);

  /// Публикует или снимает с публикации свою верную попытку.
  FutureResult<void> setPublished({
    required String submissionId,
    required bool isPublished,
  });
}
