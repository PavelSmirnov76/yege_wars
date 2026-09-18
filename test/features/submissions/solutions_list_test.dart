import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
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
  Future<void> openSolutions(WidgetTester tester) async {
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
    await tester.pumpAndSettle();
  }

  testWidgets('без своего верного ответа решения закрыты', (tester) async {
    submissions.solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsLocked), findsOneWidget);
    expect(find.byType(CodeBlock), findsNothing);
  });

  testWidgets('после верного ответа видны чужие решения', (tester) async {
    submissions
      ..attemptsResult = Ok([testCorrectAttempt])
      ..solutionsResult = Ok([testOtherSolution]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsLocked), findsNothing);
    expect(find.textContaining('masha'), findsOneWidget);
    expect(find.byType(CodeBlock), findsOneWidget);
  });

  testWidgets('решивший видит пустое состояние, если решений нет', (
    tester,
  ) async {
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await openSolutions(tester);

    expect(find.text(l10n.solutionsEmpty), findsOneWidget);
  });
}
