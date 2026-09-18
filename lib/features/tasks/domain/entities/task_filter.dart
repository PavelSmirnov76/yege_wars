import 'package:meta/meta.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';

/// Условия отбора задач в каталоге.
@immutable
final class TaskFilter {
  /// Создаёт фильтр.
  const TaskFilter({
    this.egeNumber,
    this.difficulty,
    this.progress,
    this.query = '',
  });

  /// Номер задания ЕГЭ.
  final int? egeNumber;

  /// Сложность.
  final TaskDifficulty? difficulty;

  /// Мой прогресс по задаче.
  final TaskProgress? progress;

  /// Строка поиска по названию.
  final String query;

  /// `true`, если не задано ни одного условия.
  bool get isEmpty =>
      egeNumber == null &&
      difficulty == null &&
      progress == null &&
      query.isEmpty;

  /// Копия фильтра; признаки `clear…` отличают «не меняем» от «сбрасываем».
  TaskFilter copyWith({
    int? egeNumber,
    TaskDifficulty? difficulty,
    TaskProgress? progress,
    String? query,
    bool clearEgeNumber = false,
    bool clearDifficulty = false,
    bool clearProgress = false,
  }) => TaskFilter(
    egeNumber: clearEgeNumber ? null : egeNumber ?? this.egeNumber,
    difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
    progress: clearProgress ? null : progress ?? this.progress,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilter &&
          other.egeNumber == egeNumber &&
          other.difficulty == difficulty &&
          other.progress == progress &&
          other.query == query;

  @override
  int get hashCode => Object.hash(egeNumber, difficulty, progress, query);
}
