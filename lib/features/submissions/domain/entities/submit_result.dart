import 'package:meta/meta.dart';

/// Итог отправки ответа.
///
/// Проверяет ответ база: клиент только показывает вердикт.
@immutable
final class SubmitResult {
  /// Создаёт итог.
  const SubmitResult({required this.isCorrect, required this.submissionId});

  /// Верен ли ответ.
  final bool isCorrect;

  /// Идентификатор созданной попытки.
  final String submissionId;
}
