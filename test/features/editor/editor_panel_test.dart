import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/editor/presentation/controllers/draft_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/code_editor.dart';
import 'package:yege_wars/features/reference/presentation/screens/reference_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_draft_repository.dart';
import '../../helpers/fake_python_runtime.dart';
import '../../helpers/fake_submissions_repository.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeTasksRepository tasks;
  late FakePythonRuntime runtime;
  late FakeDraftRepository drafts;
  late FakeSubmissionsRepository submissions;

  setUp(() {
    auth = FakeAuthRepository();
    tasks = FakeTasksRepository();
    runtime = FakePythonRuntime();
    drafts = FakeDraftRepository();
    submissions = FakeSubmissionsRepository();
  });

  tearDown(() {
    auth.dispose().ignore();
    runtime.dispose();
  });

  /// Переключает вкладку страницы задачи.
  Future<void> openTab(WidgetTester tester, String title) async {
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text(title)),
    );
    await tester.pumpAndSettle();
  }

  /// Открывает страницу задачи и вкладку «Код» на узком экране.
  Future<void> openEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
      runtime: runtime,
      drafts: drafts,
      submissions: submissions,
    );
    containerOf(tester).read(appRouterProvider).go('/task/${testTask24.slug}');
    await tester.pumpAndSettle();
    await openTab(tester, l10n.editorTitle);
  }

  /// Уходит со страницы задачи по адресу [location].
  void leaveTo(WidgetTester tester, String location) =>
      containerOf(tester).read(appRouterProvider).go(location);

  /// Ждёт, пока снятая страница задачи отпустит черновик.
  ///
  /// Страница снимается в конце кадра, и Riverpod откладывает снятие
  /// контроллера черновика на таймер с нулевой задержкой; `pumpAndSettle`
  /// заканчивается раньше, чем он сработает.
  Future<void> settleAfterLeave(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Код в поле кода.
  String codeText(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byType(CodeEditor),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  /// Кнопка «Запустить».
  Finder runButton() => find.widgetWithText(FilledButton, l10n.editorRun);

  /// Кнопка «Стоп».
  Finder stopButton() => find.widgetWithText(OutlinedButton, l10n.editorStop);

  /// Доступна ли кнопка [button].
  bool isEnabled(WidgetTester tester, Finder button) =>
      tester.widget<ButtonStyleButton>(button).onPressed != null;

  /// Отправляет ответ [answer] кнопкой «Отправить ответ».
  Future<void> submitAnswer(WidgetTester tester, String answer) async {
    await tester.enterText(
      find.widgetWithText(TextField, l10n.submitAnswerLabel),
      answer,
    );
    final submit = find.widgetWithText(FilledButton, l10n.submitButton);
    await tester.ensureVisible(submit);
    await tester.pump();
    await tester.tap(submit);
  }

  testWidgets('UC-32-P-01: запуск передаёт код и файлы задачи', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(446)');
    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    expect(runtime.runCalls, 1);
    expect(runtime.lastCode, 'print(446)');
    expect(runtime.lastFiles, {'24.txt': 'ABCABC\nBBB\n'});
    expect(find.text('446'), findsOneWidget);
  });

  testWidgets('UC-32-P-01, UC-32-P-03: во время выполнения «Стоп» доступен, а '
      '«Запустить» — нет', (
    tester,
  ) async {
    runtime.gate = Completer<void>();
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'while True: pass');
    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pump();

    expect(find.text(l10n.editorRunning), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, l10n.editorRun),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, l10n.editorStop));
    await tester.pumpAndSettle();

    expect(runtime.stopCalls, 1);
  });

  testWidgets('UC-32-P-02: ошибка программы показывается в консоли', (
    tester,
  ) async {
    runtime.runResult = const Ok(
      RunResult(
        outcome: RunOutcome.failed,
        stderr: 'NameError: name "x" is not defined',
      ),
    );
    await openEditor(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    expect(find.textContaining('NameError'), findsOneWidget);
    expect(find.text(l10n.editorFailed), findsOneWidget);
  });

  testWidgets('UC-32-P-01: пока грузится среда и пока выполняется программа, '
      '«Запустить» недоступна, а «Стоп» доступна', (
    tester,
  ) async {
    runtime.gate = Completer<void>();
    await openEditor(tester);

    await tester.tap(runButton());
    await tester.pump();
    runtime.emitState(PythonRuntimeState.loading);
    await tester.pump();

    expect(find.text(l10n.editorLoadingRuntime), findsOneWidget);
    expect(isEnabled(tester, runButton()), isFalse);
    expect(isEnabled(tester, stopButton()), isTrue);

    // Python загрузился, запуск продолжается — выполняется программа.
    runtime.emitState(PythonRuntimeState.running);
    await tester.pump();

    expect(find.text(l10n.editorRunning), findsOneWidget);
    expect(isEnabled(tester, runButton()), isFalse);
    expect(isEnabled(tester, stopButton()), isTrue);

    runtime.gate?.complete();
    await tester.pumpAndSettle();

    expect(find.text(l10n.editorFinished('0.0')), findsOneWidget);
    expect(isEnabled(tester, runButton()), isTrue);
    expect(isEnabled(tester, stopButton()), isFalse);
  });

  testWidgets('UC-32-P-03: «Стоп» во время загрузки среды прерывает её — '
      '«Остановлено»', (tester) async {
    runtime.gate = Completer<void>();
    await openEditor(tester);

    await tester.tap(runButton());
    await tester.pump();
    runtime.emitState(PythonRuntimeState.loading);
    await tester.pump();
    await tester.tap(stopButton());
    await tester.pumpAndSettle();

    expect(runtime.stopCalls, 1);
    expect(find.text(l10n.editorStopped), findsOneWidget);
    expect(find.text(l10n.editorLoadingRuntime), findsNothing);
    expect(isEnabled(tester, runButton()), isTrue);
  });

  testWidgets('UC-32-P-01: Ctrl+Enter во время запуска не запускает '
      'программу второй раз', (tester) async {
    await openEditor(tester);

    /// Ctrl+Enter в поле кода.
    Future<void> pressCtrlEnter() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    await tester.showKeyboard(find.byType(CodeEditor));
    await pressCtrlEnter();
    await tester.pumpAndSettle();
    expect(runtime.runCalls, 1);

    runtime.gate = Completer<void>();
    await pressCtrlEnter();
    expect(runtime.runCalls, 2);

    await pressCtrlEnter();
    expect(runtime.runCalls, 2);
    expect(find.text(l10n.editorRunning), findsOneWidget);

    runtime.gate?.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('UC-32-P-04: таймаут — сообщение в консоли и своя строка '
      'состояния', (
    tester,
  ) async {
    const timeoutMessage = 'Программа не уложилась в 60 с и была остановлена.';
    runtime.runResult = const Ok(
      RunResult(
        outcome: RunOutcome.timedOut,
        stderr: timeoutMessage,
        duration: defaultRunTimeout,
      ),
    );
    await openEditor(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    expect(find.text(l10n.editorTimedOut), findsOneWidget);
    expect(find.textContaining(timeoutMessage), findsOneWidget);
  });

  testWidgets('UC-31-P-01: черновик из базы стоит в поле, правка '
      'записывается через 1 с после последней', (tester) async {
    drafts.drafts[testTask24.id] = 'print("черновик")';
    await openEditor(tester);

    expect(codeText(tester), 'print("черновик")');
    expect(drafts.loadCalls, 1);

    await tester.enterText(find.byType(CodeEditor), 'print(2)');
    await tester.pump(const Duration(milliseconds: 999));
    expect(drafts.writes, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(drafts.writes, ['print(2)']);
    expect(drafts.drafts[testTask24.id], 'print(2)');

    // Пауза считается от последней правки, а не от первой.
    await tester.enterText(find.byType(CodeEditor), 'print(3)');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(CodeEditor), 'print(4)');
    await tester.pump(const Duration(milliseconds: 999));
    expect(drafts.writes, ['print(2)']);

    await tester.pump(const Duration(milliseconds: 1));
    expect(drafts.writes, ['print(2)', 'print(4)']);
  });

  testWidgets('UC-31-P-01, UC-32-P-01: «Запустить» сразу записывает '
      'черновик, а запуск записи не ждёт', (tester) async {
    drafts.writeGate = Completer<void>();
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(446)');
    await tester.tap(runButton());
    await tester.pump();

    expect(drafts.writes, ['print(446)']);
    expect(runtime.runCalls, 1);
    expect(runtime.lastCode, 'print(446)');

    drafts.writeGate!.complete();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(drafts.writes, ['print(446)']);
  });

  testWidgets('UC-31-P-01: «Отправить ответ» сразу записывает черновик, '
      'отправка записи не ждёт, после неё черновик остаётся', (tester) async {
    drafts.writeGate = Completer<void>();
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(446)');
    await submitAnswer(tester, '446');
    await tester.pump();

    expect(drafts.writes, ['print(446)']);
    expect(submissions.submitCalls, 1);
    expect(submissions.lastCode, 'print(446)');

    drafts.writeGate!.complete();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(l10n.submitCorrect), findsOneWidget);
    expect(drafts.writes, ['print(446)']);
    expect(drafts.drafts[testTask24.id], 'print(446)');
  });

  testWidgets('UC-31-P-01: уход со страницы назад в каталог записывает '
      'черновик сразу', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(1)');
    leaveTo(tester, AppRoutes.catalog);
    // Страница уходит переходом, до паузы записи в 1 с — 0,8 с.
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(CodeEditor), findsNothing);
    expect(drafts.writes, ['print(1)']);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(drafts.writes, ['print(1)']);
  });

  testWidgets('UC-31-P-01: переход в другой раздел записывает черновик '
      'сразу', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(1)');
    leaveTo(tester, AppRoutes.reference);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReferenceScreen), findsOneWidget);
    expect(drafts.writes, ['print(1)']);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(drafts.writes, ['print(1)']);
  });

  testWidgets('UC-31-P-01: правка переживает смену вкладки и '
      'раскладки', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(1)');
    // Поле в фокусе держит вкладку живой; без фокуса панель кода при смене
    // вкладки снимается и потом строится заново.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await openTab(tester, l10n.taskStatementTitle);
    expect(find.byType(CodeEditor, skipOffstage: false), findsNothing);
    await openTab(tester, l10n.editorTitle);

    expect(codeText(tester), 'print(1)');

    // Широкий экран — другая раскладка, панель кода строится заново.
    await tester.enterText(find.byType(CodeEditor), 'print(2)');
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    await tester.pump();

    expect(find.byType(TabBar), findsNothing);
    expect(codeText(tester), 'print(2)');
    expect(drafts.loadCalls, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(drafts.drafts[testTask24.id], 'print(2)');
  });

  testWidgets('UC-31-P-01: без правок ни кнопки, ни уход черновик не '
      'пишут', (tester) async {
    drafts.drafts[testTask24.id] = 'print(1)';
    await openEditor(tester);

    await tester.tap(runButton());
    await tester.pumpAndSettle();
    await submitAnswer(tester, '446');
    await tester.pumpAndSettle();
    leaveTo(tester, AppRoutes.catalog);
    await settleAfterLeave(tester);

    expect(
      containerOf(tester).exists(draftControllerProvider(testTask24.id)),
      isFalse,
    );
    expect(runtime.runCalls, 1);
    expect(submissions.submitCalls, 1);
    expect(drafts.writes, isEmpty);
  });

  testWidgets('UC-31-P-02: код из одних пробельных символов удаляет '
      'черновик — при следующем открытии поле пустое', (tester) async {
    drafts.drafts[testTask24.id] = 'print(1)';
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), '  \n\t');
    await tester.pump(const Duration(seconds: 1));

    expect(drafts.writes, [null]);
    expect(drafts.drafts, isEmpty);

    leaveTo(tester, AppRoutes.catalog);
    await tester.pumpAndSettle();
    leaveTo(tester, '/task/${testTask24.slug}');
    await tester.pumpAndSettle();
    await openTab(tester, l10n.editorTitle);

    expect(drafts.loadCalls, 2);
    expect(codeText(tester), isEmpty);
    expect(drafts.writes, [null]);
  });

  testWidgets('UC-31-P-03: сбой записи экран не показывает, следующая запись '
      '— по кнопке и при уходе — пишет код снова', (tester) async {
    const failure = NetworkFailure();
    drafts.writeResult = const Err(failure);
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(1)');
    await tester.pump(const Duration(seconds: 1));

    expect(drafts.writes, ['print(1)']);
    expect(find.text(failure.message), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    // Правок нет, но код не записан — «Запустить» пишет его снова.
    await tester.tap(runButton());
    await tester.pumpAndSettle();

    expect(drafts.writes, ['print(1)', 'print(1)']);
    expect(find.text(failure.message), findsNothing);

    // И уход со страницы — тоже; на этот раз база ответила.
    drafts.writeResult = const Ok<void>(null);
    leaveTo(tester, AppRoutes.catalog);
    await settleAfterLeave(tester);

    expect(drafts.writes, ['print(1)', 'print(1)', 'print(1)']);
    expect(drafts.drafts[testTask24.id], 'print(1)');
  });
}
