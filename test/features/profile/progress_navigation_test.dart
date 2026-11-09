import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_submissions_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'UC-41-P-01: возврат после отправки и повторный выбор '
    'профиля обновляют данные',
    (tester) async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final progress = FakeProgressRepository();
      final submissions = FakeSubmissionsRepository();
      await pumpApp(
        tester,
        repository: auth,
        initialUserId: testStudent.id,
        progress: progress,
        submissions: submissions,
      );
      containerOf(tester).read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.text('0 из 0'), findsOneWidget);
      containerOf(tester).read(appRouterProvider).go('/task/e24-longest-run');
      await tester.pumpAndSettle();
      await containerOf(tester)
          .read(submitControllerProvider('task-24').notifier)
          .submit(answer: '446');
      expect(submissions.submitCalls, 1);
      progress.result = const Ok(
        ProgressSummary(
          byNumber: [NumberProgress(number: 24, solved: 1, total: 2)],
          attempts: [],
        ),
      );
      await tester.tap(find.byIcon(Icons.person_outlined));
      await tester.pumpAndSettle();
      expect(find.text('1 из 2'), findsOneWidget);
      final calls = progress.calls.length;
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(progress.calls.length, greaterThan(calls));
    },
  );
  testWidgets(
    'UC-41-P-01: повторный вход через go обновляет сохранённую ветку',
    (tester) async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final progress = FakeProgressRepository();
      await pumpApp(
        tester,
        repository: auth,
        initialUserId: testStudent.id,
        progress: progress,
      );
      final router = containerOf(tester).read(appRouterProvider)
        ..go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.text('0 из 0'), findsOneWidget);
      final calls = progress.calls.length;
      router.go('/task/e24-longest-run');
      await tester.pumpAndSettle();
      progress.result = const Ok(
        ProgressSummary(
          byNumber: [NumberProgress(number: 24, solved: 1, total: 2)],
          attempts: [],
        ),
      );
      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(progress.calls.length, greaterThan(calls));
      expect(find.text('1 из 2'), findsOneWidget);
    },
  );

  testWidgets('UC-41-P-01: pop возвращает в профиль с обновлением', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final progress = FakeProgressRepository();
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      progress: progress,
    );
    final router = containerOf(tester).read(appRouterProvider)
      ..go(AppRoutes.profile);
    await tester.pumpAndSettle();
    final calls = progress.calls.length;
    unawaited(router.push<void>('/task/e24-longest-run'));
    await tester.pumpAndSettle();
    progress.result = const Ok(
      ProgressSummary(
        byNumber: [NumberProgress(number: 24, solved: 1, total: 2)],
        attempts: [],
      ),
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(progress.calls.length, greaterThan(calls));
    expect(find.text('1 из 2'), findsOneWidget);
  });

  testWidgets('UC-41-P-01: поздний ответ прежнего входа не заменяет новый', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final progress = FakeProgressRepository();
    final old = Completer<Result<ProgressSummary>>();
    progress.gates[testStudent.id] = old;
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      progress: progress,
    );
    final router = containerOf(tester).read(appRouterProvider)
      ..go(AppRoutes.profile);
    await tester.pump();
    router.go('/task/e24-longest-run');
    await tester.pump();
    progress.gates.remove(testStudent.id);
    progress.result = const Ok(
      ProgressSummary(
        byNumber: [NumberProgress(number: 24, solved: 1, total: 2)],
        attempts: [],
      ),
    );
    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('1 из 2'), findsOneWidget);
    old.complete(const Ok(ProgressSummary(byNumber: [], attempts: [])));
    await tester.pumpAndSettle();
    expect(find.text('1 из 2'), findsOneWidget);
    expect(find.text('0 из 0'), findsNothing);
  });
}
