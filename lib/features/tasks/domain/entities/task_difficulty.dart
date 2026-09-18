/// Сложность задачи.
enum TaskDifficulty {
  /// Разминочная.
  easy(1),

  /// Обычная.
  medium(2),

  /// Трудная.
  hard(3)
  ;

  const TaskDifficulty(this.value);

  /// Значение в базе данных (колонка `difficulty`).
  final int value;

  /// Сложность по значению из базы; неизвестное значение — [medium].
  static TaskDifficulty fromValue(int? value) =>
      TaskDifficulty.values.firstWhere(
        (difficulty) => difficulty.value == value,
        orElse: () => TaskDifficulty.medium,
      );
}
