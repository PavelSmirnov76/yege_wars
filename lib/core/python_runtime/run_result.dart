import 'package:meta/meta.dart';

/// Чем закончился запуск программы.
enum RunOutcome {
  /// Программа завершилась сама.
  finished,

  /// Программа не уложилась в отведённое время.
  timedOut,

  /// Ученик нажал «Стоп».
  stopped,

  /// Программа завершилась ошибкой.
  failed,
}

/// Результат запуска программы.
@immutable
final class RunResult {
  /// Создаёт результат.
  const RunResult({
    required this.outcome,
    this.stdout = '',
    this.stderr = '',
    this.duration = Duration.zero,
  });

  /// Вывод программы.
  final String stdout;

  /// Сообщения об ошибках и трассировка.
  final String stderr;

  /// Чем закончился запуск.
  final RunOutcome outcome;

  /// Сколько выполнялся запуск.
  final Duration duration;

  /// `true`, если программа отработала без ошибок.
  bool get isSuccess => outcome == RunOutcome.finished;
}
