import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/reference/reference_providers.dart';
import 'package:yege_wars/features/tasks/tasks_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_reference_repository.dart';
import 'fake_tasks_repository.dart';

/// Собирает приложение с подменённым репозиторием авторизации.
///
/// [initialUserId] эмитится в поток сессии сразу после первого кадра:
/// `null` — пользователь не вошёл, иначе восстановленная сессия.
/// [reference] и [tasks] подменяют репозитории справочника и каталога.
/// Подменяются всегда: иначе экраны полезли бы в настоящий Supabase.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository repository,
  String? initialUserId,
  FakeReferenceRepository? reference,
  FakeTasksRepository? tasks,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        referenceRepositoryProvider.overrideWithValue(
          reference ?? FakeReferenceRepository(),
        ),
        tasksRepositoryProvider.overrideWithValue(
          tasks ?? FakeTasksRepository(),
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
