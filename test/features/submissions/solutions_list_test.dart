import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/solutions_list.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_submissions_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeTasksRepository tasks;
  late FakeSubmissionsRepository submissions;

  setUp(() {
    auth = FakeAuthRepository();
    tasks = FakeTasksRepository();
    submissions = FakeSubmissionsRepository();
  });

  tearDown(() => auth.dispose().ignore());

  /// Открывает вкладку «Решения».
  ///
  /// Без [settle] вкладка открывается конечным числом кадров: так видно,
  /// что сбой загрузки показан сразу, а не после автоповторов, — пока шли
  /// бы повторы, крутился бы индикатор, и `pumpAndSettle` прокрутил бы их.
  Future<void> openSolutions(WidgetTester tester, {bool settle = true}) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
      submissions: submissions,
    );
    containerOf(tester).read(appRouterProvider).go('/task/${testTask24.slug}');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text(l10n.solutionsTitle),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('UC-35-P-02: без своего верного ответа решения закрыты', (
    tester,
  ) async {
    submissions.solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsLocked), findsOneWidget);
    expect(find.byType(CodeBlock), findsNothing);
  });

  testWidgets('UC-35-P-01: после верного ответа видны чужие решения', (
    tester,
  ) async {
    submissions
      ..attemptsResult = Ok([testCorrectAttempt])
      ..solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsLocked), findsNothing);
    expect(find.textContaining('masha'), findsOneWidget);
    expect(find.byType(CodeBlock), findsOneWidget);
  });

  testWidgets('UC-35-P-03: решивший видит пустое состояние, если решений нет', (
    tester,
  ) async {
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsEmpty), findsOneWidget);
  });

  testWidgets('UC-35-P-04: сбой загрузки решений — сразу сообщение и '
      '«Повторить» вместо списка', (
    tester,
  ) async {
    const failure = NetworkFailure();
    submissions
      ..attemptsResult = Ok([testCorrectAttempt])
      ..solutionsResult = const Err(failure);
    await openSolutions(tester, settle: false);

    // Автоповторов нет: провайдер сразу в AsyncError, запрос один.
    expect(
      containerOf(tester).read(publishedSolutionsProvider(testTask24.id)),
      isA<AsyncError<List<Submission>>>(),
    );
    expect(submissions.solutionsCalls, 1);

    final retry = find.widgetWithText(OutlinedButton, l10n.commonRetry);
    expect(
      find.descendant(
        of: find.byType(SolutionsList),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(SolutionsList),
        matching: find.text(failure.message),
      ),
      findsOneWidget,
    );
    expect(retry, findsOneWidget);
    expect(find.text(l10n.solutionsEmpty), findsNothing);

    // «Повторить» запрашивает решения заново.
    submissions.solutionsResult = Ok([testOtherSolution]);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(submissions.solutionsCalls, 2);
    expect(find.text(failure.message), findsNothing);
    expect(find.byType(CodeBlock), findsOneWidget);
  });

  testWidgets('UC-35-P-04: свои попытки не загрузились — в «Решениях» '
      'сообщение и «Повторить», а не «откроются после верного '
      'ответа»', (tester) async {
    const failure = NetworkFailure();
    submissions
      ..attemptsResult = const Err(failure)
      ..solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester, settle: false);

    // Автоповторов нет: попытки сразу в AsyncError, запрос один.
    expect(
      containerOf(tester).read(myAttemptsProvider(testTask24.id)),
      isA<AsyncError<List<Submission>>>(),
    );
    expect(submissions.attemptsCalls, 1);

    final retry = find.widgetWithText(OutlinedButton, l10n.commonRetry);
    expect(find.text(l10n.solutionsLocked), findsNothing);
    expect(find.text(failure.message), findsOneWidget);
    expect(retry, findsOneWidget);
    expect(find.byType(CodeBlock), findsNothing);

    // «Повторить» запрашивает попытки, задача решена — решения видны.
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text(failure.message), findsNothing);
    expect(find.byType(CodeBlock), findsOneWidget);
  });
}
