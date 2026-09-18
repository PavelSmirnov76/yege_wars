import 'package:meta/meta.dart';

/// Попытка решения задачи.
@immutable
final class Submission {
  /// Создаёт попытку.
  const Submission({
    required this.id,
    required this.answer,
    required this.isCorrect,
    required this.createdAt,
    this.code = '',
    this.isPublished = false,
    this.authorUsername,
  });

  /// Идентификатор попытки.
  final String id;

  /// Отправленный ответ.
  final String answer;

  /// Верен ли ответ.
  final bool isCorrect;

  /// Когда отправлена.
  final DateTime createdAt;

  /// Код решения.
  final String code;

  /// Опубликовано ли решение для других.
  final bool isPublished;

  /// Логин автора: заполняется только для чужих решений.
  final String? authorUsername;

  /// Можно ли опубликовать: публикуют только верные решения.
  bool get canPublish => isCorrect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Submission && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
