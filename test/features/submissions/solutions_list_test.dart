import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
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
  /// Без [settle] вкладка открывается конечным числом кадров: индикатор
  /// загрузки крутится бесконечно, и `pumpAndSettle` его не дождётся.
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

  testWidgets('UC-22-P-02: без своего верного ответа решения закрыты', (
    tester,
  ) async {
    submissions.solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsLocked), findsOneWidget);
    expect(find.byType(CodeBlock), findsNothing);
  });

  testWidgets('UC-22-P-01: после верного ответа видны чужие решения', (
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

  testWidgets('UC-22-P-03: решивший видит пустое состояние, если решений нет', (
    tester,
  ) async {
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsEmpty), findsOneWidget);
  });

  testWidgets('UC-22-P-04: сбой загрузки решений — индикатор загрузки без '
      'сообщения', (
    tester,
  ) async {
    const failure = NetworkFailure();
    submissions
      ..attemptsResult = Ok([testCorrectAttempt])
      ..solutionsResult = const Err(failure);
    await openSolutions(tester, settle: false);

    expect(
      containerOf(
        tester,
      ).read(publishedSolutionsProvider(testTask24.id)).error,
      failure,
    );
    expect(
      find.descendant(
        of: find.byType(SolutionsList),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text(failure.message), findsNothing);
    expect(find.text(l10n.solutionsEmpty), findsNothing);
  });
}
