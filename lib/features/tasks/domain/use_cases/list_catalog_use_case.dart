import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';

/// Каталог задач по фильтру.
final class ListCatalogUseCase {
  /// Создаёт use case поверх [TasksRepository].
  const ListCatalogUseCase(this._repository);

  final TasksRepository _repository;

  /// Загружает каталог.
  FutureResult<List<CatalogItem>> call(TaskFilter filter) =>
      _repository.listCatalog(filter);
}
