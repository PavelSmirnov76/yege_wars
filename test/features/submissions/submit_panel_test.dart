import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/domain/entities/submit_result.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/verdict_banner.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_python_runtime.dart';
import '../../helpers/fake_submissions_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

/// Табличная задача номера 25: ответ — числа таблицы по строкам.
const TaskDetail _multiTask = TaskDetail(
  brief: testTask24,
  statementMd: 'Выведите найденные числа и частные, по строке на число.',
  answerFormat: AnswerFormat.multi,
);

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

  testWidgets('UC-19-P-01, UC-20-P-01: верный ответ показывает вердикт и '
      'предлагает публикацию', (
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

  testWidgets('UC-19-P-02: неверный ответ публиковать не предлагают', (
    tester,
  ) async {
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

  testWidgets('UC-19-P-04: ошибка отправки показывается текстом из базы', (
    tester,
  ) async {
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

  testWidgets('UC-18-P-01: ответ подставляется из вывода программы', (
    tester,
  ) async {
    await openSolve(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.submitTakeFromOutput));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '446'), findsOneWidget);
  });

  testWidgets('UC-18-P-01: для multi из вывода берётся вся таблица одной '
      'строкой', (
    tester,
  ) async {
    tasks.taskResult = const Ok(_multiTask);
    runtime.runResult = const Ok(
      RunResult(outcome: RunOutcome.finished, stdout: '108 54\n\n136 68\n'),
    );
    await openSolve(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.submitTakeFromOutput));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '108 54 136 68'), findsOneWidget);
    expect(submissions.lastAnswer, '108 54 136 68');
  });

  testWidgets('UC-18-P-01: для остальных форматов из вывода берётся последняя '
      'строка', (
    tester,
  ) async {
    runtime.runResult = const Ok(
      RunResult(outcome: RunOutcome.finished, stdout: 'отладка\n446\n'),
    );
    await openSolve(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.submitTakeFromOutput));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '446'), findsOneWidget);
  });

  testWidgets('подсказка под полем зависит от формата ответа', (tester) async {
    await openSolve(tester);

    expect(find.text(l10n.submitHintSingle), findsOneWidget);
    expect(find.text(l10n.submitHintMulti), findsNothing);
  });

  testWidgets('у табличной задачи подсказка про таблицу по строкам', (
    tester,
  ) async {
    tasks.taskResult = const Ok(_multiTask);
    await openSolve(tester);

    expect(find.text(l10n.submitHintMulti), findsOneWidget);
    expect(find.text(l10n.submitHintSingle), findsNothing);
  });

  testWidgets('UC-19-P-01: ответ уходит без пробельных краёв', (tester) async {
    await openSolve(tester);

    await tester.enterText(answerField(), '  446\t ');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(submissions.lastAnswer, '446');
  });

  testWidgets('UC-21-P-01: мои попытки показываются с вердиктом', (
    tester,
  ) async {
    submissions.attemptsResult = Ok([testCorrectAttempt]);
    await openSolve(tester);

    expect(find.text(testCorrectAttempt.answer), findsWidgets);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('UC-19-P-06: сбой связи при отправке — текст под кнопкой, '
      'вердикта нет', (
    tester,
  ) async {
    const failure = NetworkFailure();
    submissions.submitResult = const Err(failure);
    await openSolve(tester);

    await tester.enterText(answerField(), '446');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();

    expect(find.text(failure.message), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(failure.message)).dy,
      greaterThan(
        tester
            .getBottomLeft(find.widgetWithText(FilledButton, l10n.submitButton))
            .dy,
      ),
    );
    expect(find.byType(VerdictBanner), findsNothing);
  });

  testWidgets('UC-20-P-03: «Не сейчас» скрывает блок и не публикует', (
    tester,
  ) async {
    await openSolve(tester);

    await tester.enterText(answerField(), '446');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.submitSolvedTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, l10n.submitNotNow));
    await tester.pumpAndSettle();

    expect(find.text(l10n.submitSolvedTitle), findsNothing);
    expect(submissions.lastPublishedId, isNull);
  });

  testWidgets('UC-20-P-04: публикация не прошла — сообщения нет, блок скрыт, '
      'переключатель прежний', (
    tester,
  ) async {
    const failure = NetworkFailure();
    submissions
      ..attemptsResult = Ok([testCorrectAttempt])
      ..publishResult = const Err(failure);
    await openSolve(tester);

    await tester.enterText(answerField(), '446');
    await tester.tap(find.widgetWithText(FilledButton, l10n.submitButton));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, l10n.submitPublish));
    await tester.pumpAndSettle();

    expect(submissions.lastPublishedId, testCorrectAttempt.id);
    expect(find.text(failure.message), findsNothing);
    expect(find.text(l10n.submitSolvedTitle), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('UC-21-P-02: без попыток — «Попыток пока не было»', (
    tester,
  ) async {
    await openSolve(tester);

    expect(find.text(l10n.attemptsEmpty), findsOneWidget);
  });

  testWidgets('UC-21-P-03: сбой загрузки попыток — ни списка, ни сообщения', (
    tester,
  ) async {
    const failure = NetworkFailure();
    submissions.attemptsResult = const Err(failure);
    await openSolve(tester);

    // Экран пути: заголовок есть, списка и сообщения нет.
    void expectNoAttempts() {
      expect(find.text(l10n.attemptsTitle), findsOneWidget);
      expect(find.text(l10n.attemptsEmpty), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text(failure.message), findsNothing);
    }

    // Пока Riverpod повторяет загрузку — AsyncLoading с ошибкой внутри.
    final attempts = myAttemptsProvider(testTask24.id);
    final retrying = containerOf(tester).read(attempts);
    expect(retrying, isA<AsyncLoading<List<Submission>>>());
    expect(retrying.error, failure);
    expectNoAttempts();

    // После последнего повтора — AsyncError.
    await pumpUntilRetriesEnd(tester, attempts);
    expect(
      containerOf(tester).read(attempts),
      isA<AsyncError<List<Submission>>>(),
    );
    expectNoAttempts();
  });
}
