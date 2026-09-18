import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:yege_wars/features/tasks/domain/use_cases/get_ege_numbers_use_case.dart';
import 'package:yege_wars/features/tasks/domain/use_cases/get_task_use_case.dart';
import 'package:yege_wars/features/tasks/domain/use_cases/list_catalog_use_case.dart';

part 'tasks_providers.g.dart';

/// Сборка зависимостей каталога задач.
///
/// В тестах достаточно подменить [tasksRepositoryProvider].
@Riverpod(keepAlive: true)
TasksRepository tasksRepository(Ref ref) => TasksRepositoryImpl(
  SupabaseTasksRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Use case каталога.
@Riverpod(keepAlive: true)
ListCatalogUseCase listCatalogUseCase(Ref ref) =>
    ListCatalogUseCase(ref.watch(tasksRepositoryProvider));

/// Use case загрузки задачи.
@Riverpod(keepAlive: true)
GetTaskUseCase getTaskUseCase(Ref ref) =>
    GetTaskUseCase(ref.watch(tasksRepositoryProvider));

/// Use case списка номеров заданий.
@Riverpod(keepAlive: true)
GetEgeNumbersUseCase getEgeNumbersUseCase(Ref ref) =>
    GetEgeNumbersUseCase(ref.watch(tasksRepositoryProvider));
