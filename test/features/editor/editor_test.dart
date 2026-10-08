import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/python_highlighter.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/python_runtime_provider.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/editor/data/preferences_draft_storage.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/console_view.dart';
import 'package:yege_wars/features/editor/presentation/widgets/python_editing_controller.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_python_runtime.dart';

void main() {
  final l10n = AppLocalizationsRu();

  // Какой ответ брать из вывода, решает формат ответа — тесты правила
  // в test/features/submissions/answer_rules_test.dart.
  group('RunResult', () {
    test('успешен только запуск, завершившийся сам', () {
      expect(const RunResult(outcome: RunOutcome.finished).isSuccess, isTrue);
      expect(const RunResult(outcome: RunOutcome.failed).isSuccess, isFalse);
    });
  });

  group('PythonEditingController', () {
    testWidgets('подсвечивает ключевые слова, не теряя текста', (tester) async {
      final controller = PythonEditingController(text: 'for x in range(3):');
      addTearDown(controller.dispose);

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(span.toPlainText(), 'for x in range(3):');
      final keyword = span.children!.cast<TextSpan>().firstWhere(
        (child) => child.text == 'for',
      );
      expect(keyword.style?.color, AppColors.codeKeyword);
    });

    test('цвет подбирается по роли фрагмента', () {
      expect(
        PythonEditingController.colorOf(CodeTokenKind.string),
        AppColors.codeString,
      );
      expect(
        PythonEditingController.colorOf(CodeTokenKind.plain),
        AppColors.textPrimary,
      );
    });
  });

  group('PreferencesDraftStorage', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('UC-16-P-01: сохраняет и читает черновик задачи', () async {
      const storage = PreferencesDraftStorage();

      await storage.write('e24-longest-run', 'print(1)');

      expect(await storage.read('e24-longest-run'), 'print(1)');
      expect(await storage.read('другая-задача'), isNull);
    });

    test('UC-16-P-01: пустой черновик удаляется', () async {
      const storage = PreferencesDraftStorage();
      await storage.write('e24-longest-run', 'print(1)');

      await storage.write('e24-longest-run', '   ');

      expect(await storage.read('e24-longest-run'), isNull);
    });
  });

  group('RunController', () {
    late FakePythonRuntime runtime;
    late ProviderContainer container;

    setUp(() {
      runtime = FakePythonRuntime();
      container = ProviderContainer(
        overrides: [pythonRuntimeProvider.overrideWithValue(runtime)],
      );
    });

    tearDown(() {
      container.dispose();
      runtime.dispose();
    });

    RunState read() => container.read(runControllerProvider('e24'));

    test('UC-17-P-01: запуск передаёт код, ввод и файлы задачи', () async {
      await container
          .read(runControllerProvider('e24').notifier)
          .run(
            code: 'print(1)',
            stdin: '5\n7',
            files: const [
              TaskFile(filename: '24.txt', content: 'ABC', sizeBytes: 3),
            ],
          );

      expect(runtime.runCalls, 1);
      expect(runtime.lastCode, 'print(1)');
      expect(runtime.lastStdin, '5\n7');
      expect(runtime.lastFiles, {'24.txt': 'ABC'});
      expect(read().result?.stdout, '446');
    });

    test('UC-17-P-05: ошибка среды попадает в состояние', () async {
      runtime.runResult = const Err(
        UnexpectedFailure(message: 'Среда Python не запустилась.'),
      );

      await container
          .read(runControllerProvider('e24').notifier)
          .run(
            code: 'print(1)',
          );

      expect(read().failure?.message, 'Среда Python не запустилась.');
      expect(read().result, isNull);
    });

    test('UC-17-P-01: состояние среды приходит из потока', () async {
      container.read(runControllerProvider('e24'));
      runtime.emitState(PythonRuntimeState.loading);
      await pumpEventQueue();

      expect(read().isLoadingRuntime, isTrue);
    });

    test('UC-17-P-03: «Стоп» доходит до среды', () async {
      await container.read(runControllerProvider('e24').notifier).stop();

      expect(runtime.stopCalls, 1);
    });

    test('очистка убирает прошлый вывод', () async {
      final notifier = container.read(runControllerProvider('e24').notifier);
      await notifier.run(code: 'print(1)');
      expect(read().result, isNotNull);

      notifier.clear();

      expect(read().result, isNull);
    });
  });

  group('runStatusLabel', () {
    test('состояния среды важнее прошлого результата', () {
      expect(
        runStatusLabel(
          const RunState(runtimeState: PythonRuntimeState.loading),
          l10n,
        ),
        l10n.editorLoadingRuntime,
      );
      expect(
        runStatusLabel(
          const RunState(runtimeState: PythonRuntimeState.running),
          l10n,
        ),
        l10n.editorRunning,
      );
    });

    test('итог запуска называется своими словами', () {
      String labelFor(RunOutcome outcome) => runStatusLabel(
        RunState(
          runtimeState: PythonRuntimeState.ready,
          result: RunResult(
            outcome: outcome,
            duration: const Duration(milliseconds: 1500),
          ),
        ),
        l10n,
      );

      expect(labelFor(RunOutcome.finished), l10n.editorFinished('1.5'));
      expect(labelFor(RunOutcome.failed), l10n.editorFailed);
      expect(labelFor(RunOutcome.timedOut), l10n.editorTimedOut);
      expect(labelFor(RunOutcome.stopped), l10n.editorStopped);
    });

    test('до первого запуска строка пустая', () {
      expect(runStatusLabel(const RunState(), l10n), isEmpty);
    });
  });
}
