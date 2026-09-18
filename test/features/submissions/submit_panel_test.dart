import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/verdict_banner.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_python_runtime.dart';
import '../../helpers/fake_submissions_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeTasksRepository tasks;
  late FakePythonRuntime runtime;
  late FakeSubmissionsRepository submissions;

  setUp(() {
    auth = FakeAuthRepository();
    tasks = FakeTasksRepository();
    runtime = FakePythonRuntime();
    submissions = FakeSubmissionsRepository();
  });

  tearDown(() {
    auth.dispose().ignore();
    runtime.dispose();
  });

  /// Открывает вкладку «Код» с полем ответа.
  Future<void> openSolve(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
      runtime: runtime,
      submissions: submissions,
    );
    containerOf(tester).read(appRouterProvider).go('/task/${testTask24.slug}');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text(l10n.editorTitle),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Поле ответа.
  Finder answerField() =>
      find.widgetWithText(TextField, l10n.submitAnswerLabel);

  testWidgets('верный ответ показывает вердикт и предлагает публикацию', (
    tester,
  ) async {
    await openSolve(tester);

    await tester.enterText(answerField(), '446');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(submissions.lastAnswer, '446');
    expect(find.byType(VerdictBanner), findsOneWidget);
    expect(find.text(l10n.submitCorrect), findsOneWidget);
    expect(find.text(l10n.submitSolvedTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.submitPublish));
    await tester.pumpAndSettle();

    expect(submissions.lastPublishedId, 'attempt-ok');
    expect(submissions.lastPublishedValue, isTrue);
    expect(find.text(l10n.submitSolvedTitle), findsNothing);
  });

  testWidgets('неверный ответ публиковать не предлагают', (tester) async {
    submissions.submitResult = const Ok(
      SubmitResult(isCorrect: false, submissionId: 'attempt-bad'),
    );
    await openSolve(tester);

    await tester.enterText(answerField(), '1');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.submitWrong), findsOneWidget);
    expect(find.text(l10n.submitSolvedTitle), findsNothing);
  });

  testWidgets('ошибка отправки показывается текстом из базы', (tester) async {
    submissions.submitResult = const Err(
      DatabaseFailure(message: 'Слишком много отправок, подождите минуту.'),
    );
    await openSolve(tester);

    await tester.enterText(answerField(), '446');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Слишком много отправок, подождите минуту.'),
      findsOneWidget,
    );
    expect(find.byType(VerdictBanner), findsNothing);
  });

  testWidgets('ответ подставляется из вывода программы', (tester) async {
    await openSolve(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.submitTakeFromOutput));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '446'), findsOneWidget);
  });

  testWidgets('мои попытки показываются с вердиктом', (tester) async {
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await openSolve(tester);

    expect(find.text(testCorrectAttempt.answer), findsWidgets);
    expect(find.byType(Switch), findsOneWidget);
  });
}
