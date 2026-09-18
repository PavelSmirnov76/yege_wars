import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/domain/repositories/submissions_repository.dart';

/// Отправка ответа с проверкой ввода.
final class SubmitAnswerUseCase {
  /// Создаёт use case поверх [SubmissionsRepository].
  const SubmitAnswerUseCase(this._repository);

  final SubmissionsRepository _repository;

  /// Отправляет ответ; пустой ответ до сервера не доходит.
  FutureResult<SubmitResult> call({
    required String taskId,
    required String answer,
    String code = '',
  }) async {
    if (answer.trim().isEmpty) {
      return const Err<SubmitResult>(
        ValidationFailure(message: 'Введите ответ перед отправкой.'),
      );
    }
    return _repository.submit(taskId: taskId, answer: answer, code: code);
  }
}
