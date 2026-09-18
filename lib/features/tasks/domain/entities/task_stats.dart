import 'package:meta/meta.dart';

/// Статистика решений задачи по ученикам.
///
/// Попытки администраторов в неё не входят — так считает функция базы
/// `get_task_stats`.
@immutable
final class TaskStats {
  /// Создаёт статистику.
  const TaskStats({
    this.attemptedStudents = 0,
    this.solvedStudents = 0,
    this.solvedPercent = 0,
  });

  /// Сколько учеников пробовали решить.
  final int attemptedStudents;

  /// Сколько решили верно.
  final int solvedStudents;

  /// Доля решивших среди пробовавших, в процентах.
  final double solvedPercent;

  /// `true`, если задачу ещё никто не пробовал.
  bool get isEmpty => attemptedStudents == 0;
}
