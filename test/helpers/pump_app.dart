import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/app/provider_retry.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/python_runtime/python_runtime_provider.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/editor/editor_providers.dart';
import 'package:yege_wars/features/reference/reference_providers.dart';
import 'package:yege_wars/features/submissions/submissions_providers.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:yege_wars/features/tasks/tasks_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_draft_repository.dart';
import 'fake_python_runtime.dart';
import 'fake_reference_repository.dart';
import 'fake_submissions_repository.dart';
import 'fake_tasks_repository.dart';

/// Собирает приложение с подменённым репозиторием авторизации.
///
/// [initialUserId] эмитится в поток сессии сразу после первого кадра:
/// `null` — пользователь не вошёл, иначе восстановленная сессия.
/// [reference], [tasks], [runtime] и [drafts] подменяют репозитории,
/// среду выполнения Python и черновики. Подменяются всегда: иначе экраны
/// полезли бы в настоящий Supabase и в браузерные API.
/// [tasks] — любой репозиторий задач: например, настоящий поверх
/// заглушки datasource, когда проверяется сборка данных.
///
/// Автоповтор упавших провайдеров выключен той же функцией, что в
/// `main.dart`: сбой загрузки сразу даёт `AsyncError`.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository repository,
  String? initialUserId,
  FakeReferenceRepository? reference,
  TasksRepository? tasks,
  FakePythonRuntime? runtime,
  FakeDraftRepository? drafts,
  FakeSubmissionsRepository? submissions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        referenceRepositoryProvider.overrideWithValue(
          reference ?? FakeReferenceRepository(),
        ),
        tasksRepositoryProvider.overrideWithValue(
          tasks ?? FakeTasksRepository(),
        ),
        pythonRuntimeProvider.overrideWithValue(
          runtime ?? FakePythonRuntime(),
        ),
        draftRepositoryProvider.overrideWithValue(
          drafts ?? FakeDraftRepository(),
        ),
        submissionsRepositoryProvider.overrideWithValue(
          submissions ?? FakeSubmissionsRepository(),
        ),
      ],
      child: const YegeWarsApp(),
    ),
  );
  // Первый кадр — заставка: статус авторизации ещё неизвестен.
  await tester.pump();
  repository.emitUserId(initialUserId);
  await tester.pumpAndSettle();
}

/// Контейнер провайдеров собранного приложения.
ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(YegeWarsApp)),
  listen: false,
);

/// Адрес открытой страницы приложения — с параметрами запроса.
String currentLocation(WidgetTester tester) => containerOf(
  tester,
).read(appRouterProvider).routerDelegate.currentConfiguration.uri.toString();
