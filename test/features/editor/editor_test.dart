import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/python_highlighter.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/python_runtime_provider.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/editor/data/datasources/draft_remote_data_source.dart';
import 'package:yege_wars/features/editor/data/datasources/supabase_draft_remote_data_source.dart';
import 'package:yege_wars/features/editor/data/repositories/draft_repository_impl.dart';
import 'package:yege_wars/features/editor/domain/use_cases/save_draft_use_case.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/console_view.dart';
import 'package:yege_wars/features/editor/presentation/widgets/python_editing_controller.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../helpers/fake_draft_repository.dart';
import '../../helpers/fake_python_runtime.dart';
import '../../helpers/recording_supabase_client.dart';

/// Пользователь сессии в тестах datasource черновиков.
const String _userId = '6f1c2d3e-4a5b-4c6d-8e7f-001122334455';

/// Datasource черновиков, который записывает вызовы и держит записи, пока
/// не завершены [gates] — по одному на запись, по порядку.
final class _GatedDraftDataSource implements DraftRemoteDataSource {
  /// Вызовы по порядку.
  final List<String> calls = [];

  /// Ответы на записи: запись ждёт первый незабранный.
  final List<Completer<void>> gates = [];

  /// Что вернёт чтение.
  Map<String, dynamic>? row;

  /// Если задано, ближайшая запись упадёт с ним.
  Exception? writeError;

  @override
  Future<Map<String, dynamic>?> fetchDraft(String taskId) async {
    calls.add('fetch $taskId');
    return row;
  }

  @override
  Future<void> upsertDraft({
    required String taskId,
    required String code,
  }) async {
    calls.add('upsert $code');
    await _answer();
  }

  @override
  Future<void> deleteDraft(String taskId) async {
    calls.add('delete $taskId');
    await _answer();
  }

  Future<void> _answer() async {
    if (gates.isNotEmpty) {
      await gates.removeAt(0).future;
    }
    final error = writeError;
    if (error != null) {
      writeError = null;
      throw error;
    }
  }
}

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

  group('SaveDraftUseCase', () {
    late FakeDraftRepository repository;

    setUp(() => repository = FakeDraftRepository());

    test('UC-31-P-01: код записывается черновиком задачи', () async {
      final result = await SaveDraftUseCase(repository)(
        taskId: 'task-24',
        code: 'print(1)',
      );

      expect(result.isOk, isTrue);
      expect(repository.writes, ['print(1)']);
      expect(repository.drafts['task-24'], 'print(1)');
    });

    test('UC-31-P-02: код из одних пробельных символов удаляет '
        'черновик', () async {
      repository.drafts['task-24'] = 'print(1)';

      await SaveDraftUseCase(repository)(taskId: 'task-24', code: ' \n\t ');

      expect(repository.writes, [null]);
      expect(repository.drafts, isEmpty);
    });
  });

  group('DraftRepositoryImpl', () {
    late _GatedDraftDataSource dataSource;
    late DraftRepositoryImpl repository;

    setUp(() {
      dataSource = _GatedDraftDataSource();
      repository = DraftRepositoryImpl(dataSource);
    });

    test('UC-31-P-01: черновик читается из строки базы, нет строки — '
        'черновика нет', () async {
      dataSource.row = {'code': 'print(1)'};
      expect((await repository.load('task-24')).valueOrNull, 'print(1)');

      dataSource.row = null;
      final missing = await repository.load('task-24');
      expect(missing.isOk, isTrue);
      expect(missing.valueOrNull, isNull);
    });

    test('UC-31-P-01: записи задачи идут по очереди — следующая после '
        'ответа на предыдущую', () async {
      final firstAnswer = Completer<void>();
      dataSource.gates.add(firstAnswer);

      final first = repository.save('task-24', 'print(1)');
      final second = repository.save('task-24', 'print(2)');
      await pumpEventQueue();

      expect(dataSource.calls, ['upsert print(1)']);

      firstAnswer.complete();
      await Future.wait([first, second]);

      expect(dataSource.calls, ['upsert print(1)', 'upsert print(2)']);
    });

    test('UC-31-P-01: загрузка ждёт незаконченной записи той же '
        'задачи', () async {
      final answer = Completer<void>();
      dataSource.gates.add(answer);

      final save = repository.save('task-24', 'print(1)');
      final load = repository.load('task-24');
      await pumpEventQueue();

      expect(dataSource.calls, ['upsert print(1)']);

      answer.complete();
      await Future.wait([save, load]);

      expect(dataSource.calls, ['upsert print(1)', 'fetch task-24']);
    });

    test('UC-31-P-03: сбой записи — ошибка в результате, следующая запись '
        'уходит', () async {
      dataSource.writeError = const PostgrestException(message: 'нет связи');

      final failed = await repository.save('task-24', 'print(1)');
      final next = await repository.delete('task-24');

      expect(failed.failureOrNull, isA<DatabaseFailure>());
      expect(next.isOk, isTrue);
      expect(dataSource.calls, ['upsert print(1)', 'delete task-24']);
    });
  });

  group('SupabaseDraftRemoteDataSource', () {
    late RecordingSupabaseClient supabase;
    late SupabaseDraftRemoteDataSource dataSource;

    setUp(() {
      supabase = RecordingSupabaseClient();
      dataSource = SupabaseDraftRemoteDataSource(supabase.client);
    });

    tearDown(() => supabase.dispose());

    /// Вход пользователем [_userId] без сети.
    Future<void> signIn() => supabase.client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'test-access-token',
        'token_type': 'bearer',
        'user': {
          'id': _userId,
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-10-09T00:00:00Z',
        },
      }),
    );

    test('UC-31-P-01: черновик пишется upsert по ключу «пользователь, '
        'задача»', () async {
      await signIn();

      await dataSource.upsertDraft(taskId: 'task-24', code: 'print(1)');

      final request = supabase.requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/drafts');
      expect(request.url.queryParameters['on_conflict'], 'user_id,task_id');
      expect(
        request.headers['Prefer'],
        contains('resolution=merge-duplicates'),
      );
      expect(jsonDecode(request.body), {
        'user_id': _userId,
        'task_id': 'task-24',
        'code': 'print(1)',
      });
    });

    test('UC-31-P-01: черновик читается своей строкой задачи', () async {
      await signIn();

      expect(await dataSource.fetchDraft('task-24'), isNull);

      final url = supabase.onlyUrl;
      expect(url.path, '/rest/v1/drafts');
      expect(url.queryParameters['select'], 'code');
      expect(url.queryParameters['user_id'], 'eq.$_userId');
      expect(url.queryParameters['task_id'], 'eq.task-24');
    });

    test('UC-31-P-02: удаляется своя строка задачи', () async {
      await signIn();

      await dataSource.deleteDraft('task-24');

      final request = supabase.requests.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/rest/v1/drafts');
      expect(request.url.queryParameters['user_id'], 'eq.$_userId');
      expect(request.url.queryParameters['task_id'], 'eq.task-24');
    });

    test('без сессии черновик не читается и не пишется', () async {
      await expectLater(
        dataSource.fetchDraft('task-24'),
        throwsA(isA<AuthSessionMissingException>()),
      );
      await expectLater(
        dataSource.upsertDraft(taskId: 'task-24', code: 'print(1)'),
        throwsA(isA<AuthSessionMissingException>()),
      );
      expect(supabase.requests, isEmpty);
    });
  });

  group('runtimeStateOnReady', () {
    test('UC-32-P-01: Python загрузился во время запуска — программа '
        'выполняется', () {
      expect(
        runtimeStateOnReady(isRunPending: true),
        PythonRuntimeState.running,
      );
    });

    test('без запуска загруженная среда просто готова', () {
      expect(
        runtimeStateOnReady(isRunPending: false),
        PythonRuntimeState.ready,
      );
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

    test('UC-32-P-01: запуск передаёт код, ввод и файлы задачи', () async {
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

    test('UC-32-P-05: ошибка среды попадает в состояние', () async {
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

    test('UC-32-P-01: состояние среды приходит из потока', () async {
      container.read(runControllerProvider('e24'));
      runtime.emitState(PythonRuntimeState.loading);
      await pumpEventQueue();

      expect(read().isLoadingRuntime, isTrue);
    });

    test('UC-32-P-03: «Стоп» доходит до среды', () async {
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
