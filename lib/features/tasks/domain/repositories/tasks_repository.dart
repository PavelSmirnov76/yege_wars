import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';

/// Доступ к каталогу задач.
///
/// Черновики и эталоны отсекает база: клиент читает представление
/// опубликованных задач.
abstract interface class TasksRepository {
  /// Каталог: задачи по фильтру вместе с моим прогрессом и статистикой.
  FutureResult<List<CatalogItem>> listCatalog(TaskFilter filter);

  /// Задача целиком: условие, файлы и статьи справочника.
  FutureResult<TaskDetail> getTask(String slug);

  /// Номера заданий, по которым есть задачи: для чипов-фильтров.
  FutureResult<List<int>> availableEgeNumbers();
}
