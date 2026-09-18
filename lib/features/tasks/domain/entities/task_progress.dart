/// Что ученик уже сделал с задачей.
enum TaskProgress {
  /// Ни одной попытки.
  notStarted,

  /// Были попытки, но верной нет.
  attempted,

  /// Есть верная попытка.
  solved
  ;

  /// Статус по собственным попыткам: [attempts] всего, [hasCorrect] — есть ли
  /// среди них верная.
  static TaskProgress fromAttempts({
    required int attempts,
    required bool hasCorrect,
  }) {
    if (hasCorrect) {
      return TaskProgress.solved;
    }
    return attempts > 0 ? TaskProgress.attempted : TaskProgress.notStarted;
  }
}
