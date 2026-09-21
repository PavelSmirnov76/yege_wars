import 'package:meta/meta.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';

/// Карточка задачи в каталоге: без условия и файлов.
@immutable
final class TaskBrief {
  /// Создаёт карточку задачи.
  const TaskBrief({
    required this.id,
    required this.slug,
    required this.egeNumber,
    required this.title,
    required this.difficulty,
    this.tags = const [],
  });

  /// Идентификатор задачи.
  final String id;

  /// Человекочитаемый идентификатор.
  final String slug;

  /// Номер задания ЕГЭ; `null`, если задание к структуре КИМ не отнесено.
  final int? egeNumber;

  /// Название задачи.
  final String title;

  /// Сложность.
  final TaskDifficulty difficulty;

  /// Теги.
  final List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskBrief && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
