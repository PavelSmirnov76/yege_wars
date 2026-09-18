import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';

/// Задача целиком по slug.
final class GetTaskUseCase {
  /// Создаёт use case поверх [TasksRepository].
  const GetTaskUseCase(this._repository);

  final TasksRepository _repository;

  /// Загружает задачу.
  FutureResult<TaskDetail> call(String slug) => _repository.getTask(slug);
}
