import 'package:yege_wars/core/error/result.dart';

/// Прогресс по номеру КЕГЭ.
class NumberProgress {
  const NumberProgress({
    required this.number,
    required this.solved,
    required this.total,
  });
  final int? number;
  final int solved;
  final int total;
}

/// Краткая запись о попытке.
class RecentAttempt {
  const RecentAttempt({
    required this.id,
    required this.taskId,
    required this.slug,
    required this.title,
    required this.number,
    required this.correct,
    required this.createdAt,
  });
  final String id;
  final String taskId;
  final String slug;
  final String title;
  final int? number;
  final bool correct;
  final DateTime createdAt;
}

/// Сводка опубликованных задач и последних попыток.
class ProgressSummary {
  const ProgressSummary({required this.byNumber, required this.attempts});
  final List<NumberProgress> byNumber;
  final List<RecentAttempt> attempts;
  int get solved => byNumber.fold(0, (sum, row) => sum + row.solved);
  int get total => byNumber.fold(0, (sum, row) => sum + row.total);
}

/// Чтение прогресса текущего пользователя.
// Контракт репозитория отделяет domain от источника данных.
// ignore: one_member_abstracts
abstract interface class ProgressRepository {
  FutureResult<ProgressSummary> getProgress(String userId);
}

/// Сценарий чтения прогресса.
class GetProgress {
  const GetProgress(this.repository);
  final ProgressRepository repository;
  FutureResult<ProgressSummary> call(String userId) =>
      repository.getProgress(userId);
}
