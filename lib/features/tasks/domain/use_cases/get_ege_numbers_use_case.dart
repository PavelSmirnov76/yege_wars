import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';

/// Номера заданий ЕГЭ, по которым есть задачи.
final class GetEgeNumbersUseCase {
  /// Создаёт use case поверх [TasksRepository].
  const GetEgeNumbersUseCase(this._repository);

  final TasksRepository _repository;

  /// Загружает список номеров.
  FutureResult<List<int>> call() => _repository.availableEgeNumbers();
}
