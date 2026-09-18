import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/tasks_providers.dart';

part 'catalog_controllers.g.dart';

/// Текущие условия отбора задач в каталоге.
@riverpod
class TaskFilterController extends _$TaskFilterController {
  @override
  TaskFilter build() => const TaskFilter();

  /// Задаёт строку поиска.
  void setQuery(String query) => state = state.copyWith(query: query);

  /// Переключает номер задания: повторный выбор снимает условие.
  void toggleEgeNumber(int egeNumber) => state = state.egeNumber == egeNumber
      ? state.copyWith(clearEgeNumber: true)
      : state.copyWith(egeNumber: egeNumber);

  /// Переключает сложность.
  void toggleDifficulty(TaskDifficulty difficulty) =>
      state = state.difficulty == difficulty
      ? state.copyWith(clearDifficulty: true)
      : state.copyWith(difficulty: difficulty);

  /// Переключает состояние решения.
  void toggleProgress(TaskProgress progress) =>
      state = state.progress == progress
      ? state.copyWith(clearProgress: true)
      : state.copyWith(progress: progress);

  /// Сбрасывает все условия.
  void reset() => state = const TaskFilter();
}

/// Каталог задач по текущему фильтру.
@riverpod
Future<List<CatalogItem>> catalog(Ref ref) async {
  final filter = ref.watch(taskFilterControllerProvider);
  final result = await ref.watch(listCatalogUseCaseProvider)(filter);
  return result.fold(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}

/// Номера заданий, по которым есть задачи.
///
/// Считается один раз за сессию: список номеров меняется только когда
/// администратор публикует задачу нового номера.
@Riverpod(keepAlive: true)
Future<List<int>> catalogEgeNumbers(Ref ref) async {
  final result = await ref.watch(getEgeNumbersUseCaseProvider)();
  // Без списка номеров каталог остаётся рабочим, просто без чипов.
  return result.fold(onOk: (numbers) => numbers, onErr: (_) => const []);
}

/// Задача целиком по slug.
@riverpod
Future<TaskDetail> task(Ref ref, String slug) async {
  final result = await ref.watch(getTaskUseCaseProvider)(slug);
  return result.fold(
    onOk: (task) => task,
    onErr: (failure) => throw failure,
  );
}
