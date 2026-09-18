import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/editor/presentation/widgets/code_editor.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_python_runtime.dart';
import '../../helpers/fake_tasks_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeTasksRepository tasks;
  late FakePythonRuntime runtime;
  late FakeDraftStorage drafts;

  setUp(() {
    auth = FakeAuthRepository();
    tasks = FakeTasksRepository();
    runtime = FakePythonRuntime();
    drafts = FakeDraftStorage();
  });

  tearDown(() {
    auth.dispose().ignore();
    runtime.dispose();
  });

  /// Открывает вкладку «Код» на узком экране.
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

  testWidgets('запуск передаёт код и файлы задачи', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.byType(CodeEditor), 'print(446)');
    await tester.tap(find.widgetWithText(FilledButton, l10n.editorRun));
    await tester.pumpAndSettle();

    expect(runtime.runCalls, 1);
    expect(runtime.lastCode, 'print(446)');
    expect(runtime.lastFiles, {'24.txt': 'ABCABC\nBBB\n'});
    expect(find.text('446'), findsOneWidget);
  });

  testWidgets('во время выполнения «Стоп» доступен, а «Запустить» — нет', (
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

  testWidgets('ошибка программы показывается в консоли', (tester) async {
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

  testWidgets('черновик подставляется и сохраняется', (tester) async {
    drafts.drafts[testTask24.slug] = 'print("черновик")';
    await openEditor(tester);

    expect(find.text('print("черновик")'), findsOneWidget);

    await tester.enterText(find.byType(CodeEditor), 'print(2)');
    // Сохранение отложено, ждём дольше задержки.
    await tester.pump(const Duration(milliseconds: 700));

    expect(drafts.drafts[testTask24.slug], 'print(2)');
  });
}
