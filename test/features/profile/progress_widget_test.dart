import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

final populated = ProgressSummary(
  byNumber: const [
    NumberProgress(number: 24, solved: 1, total: 2),
    NumberProgress(number: null, solved: 0, total: 1),
  ],
  attempts: [
    RecentAttempt(
      id: 'attempt',
      taskId: 'task',
      slug: 'selected-task',
      title: 'Выбранная задача',
      number: 24,
      correct: true,
      createdAt: DateTime.utc(2026),
    ),
  ],
);

void main() {
  late FakeAuthRepository auth;
  late FakeProgressRepository progress;
  setUp(() {
    auth = FakeAuthRepository();
    progress = FakeProgressRepository();
  });
  tearDown(() => auth.dispose());

  Future<void> open(WidgetTester tester, {FakeTasksRepository? tasks}) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      progress: progress,
      tasks: tasks,
    );
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
  }

  testWidgets('UC-41-P-01: сводка и попытка с номером и вердиктом', (
    tester,
  ) async {
    progress.result = Ok(populated);
    await open(tester);
    expect(find.text('1 из 3'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Без номера КЕГЭ'), findsOneWidget);
    expect(find.text('Выбранная задача'), findsOneWidget);
    expect(find.text('Верно'), findsOneWidget);
  });

  testWidgets('UC-41-P-02: нулевой прогресс и отсутствие попыток', (
    tester,
  ) async {
    progress.result = const Ok(
      ProgressSummary(
        byNumber: [NumberProgress(number: 24, solved: 0, total: 2)],
        attempts: [],
      ),
    );
    await open(tester);
    expect(find.text('0 из 2'), findsOneWidget);
    expect(find.text('Попыток пока нет'), findsOneWidget);
  });

  testWidgets('UC-41-P-03: пустая база', (tester) async {
    await open(tester);
    expect(find.text('0 из 0'), findsOneWidget);
    expect(find.text('Пока нет опубликованных задач'), findsOneWidget);
    expect(find.text('Попыток пока нет'), findsOneWidget);
  });

  testWidgets('UC-41-P-04 UC-41-P-05: ошибка и повтор', (tester) async {
    progress.result = const Err(DatabaseFailure(message: 'Ошибка теста'));
    await open(tester);
    expect(find.text('Ошибка теста'), findsOneWidget);
    progress.result = Ok(populated);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('1 из 3'), findsOneWidget);
    expect(progress.calls.length, 2);
  });

  testWidgets('UC-42-P-01: выбранный slug и обновление сохранённой ветки', (
    tester,
  ) async {
    final tasks = FakeTasksRepository();
    progress.result = Ok(populated);
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      progress: progress,
      tasks: tasks,
    );
    containerOf(tester).read(appRouterProvider).go('/task/previous-task');
    await tester.pumpAndSettle();
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Выбранная задача'));
    await tester.tap(find.text('Выбранная задача'));
    await tester.pumpAndSettle();
    expect(currentLocation(tester), '/task/selected-task');
    expect(tasks.lastSlug, 'selected-task');
    final calls = progress.calls.length;
    await tester.tap(find.byIcon(Icons.person_outlined));
    await tester.pumpAndSettle();
    expect(progress.calls.length, greaterThan(calls));
  });

  testWidgets('UC-41-P-01: поздний ответ другого аккаунта не заменяет данные', (
    tester,
  ) async {
    final gate = Completer<Result<ProgressSummary>>();
    progress.gates[testStudent.id] = gate;
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      progress: progress,
    );
    containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    auth
      ..currentProfileResult = const Ok(testAdmin)
      ..emitUserId(testAdmin.id);
    await tester.pumpAndSettle();
    expect(find.text('0 из 0'), findsOneWidget);
    gate.complete(Ok(populated));
    await tester.pumpAndSettle();
    expect(find.text('0 из 0'), findsOneWidget);
    expect(find.text('1 из 3'), findsNothing);
  });
}
