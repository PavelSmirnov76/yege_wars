import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/editor/domain/draft_storage.dart';

/// Среда выполнения Python для тестов.
final class FakePythonRuntime implements PythonRuntime {
  final StreamController<PythonRuntimeState> _states =
      StreamController<PythonRuntimeState>.broadcast();

  /// Что вернёт [run].
  Result<RunResult> runResult = const Ok(
    RunResult(outcome: RunOutcome.finished, stdout: '446'),
  );

  /// Пока не завершён, [run] не отвечает: так проверяется «Выполняется».
  Completer<void>? gate;

  /// Сколько раз запускали программу.
  int runCalls = 0;

  /// Сколько раз нажимали «Стоп».
  int stopCalls = 0;

  /// Аргументы последнего запуска.
  String? lastCode;

  /// Введённые данные последнего запуска.
  String? lastStdin;

  /// Файлы последнего запуска.
  Map<String, String>? lastFiles;

  PythonRuntimeState _state = PythonRuntimeState.idle;

  @override
  Stream<PythonRuntimeState> get states => _states.stream;

  @override
  PythonRuntimeState get state => _state;

  /// Сообщает новое состояние подписчикам.
  void emitState(PythonRuntimeState value) {
    _state = value;
    _states.add(value);
  }

  @override
  FutureResult<RunResult> run({
    required String code,
    String stdin = '',
    Map<String, String> files = const {},
    Duration timeout = defaultRunTimeout,
  }) async {
    runCalls++;
    lastCode = code;
    lastStdin = stdin;
    lastFiles = files;
    _state = PythonRuntimeState.running;
    await gate?.future;
    _state = PythonRuntimeState.ready;
    return runResult;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    gate?.complete();
    gate = null;
  }

  @override
  void dispose() => _states.close().ignore();
}

/// Хранилище черновиков в памяти.
final class FakeDraftStorage implements DraftStorage {
  /// Черновики по slug задачи.
  final Map<String, String> drafts = {};

  @override
  Future<String?> read(String taskSlug) async => drafts[taskSlug];

  @override
  Future<void> write(String taskSlug, String code) async {
    if (code.trim().isEmpty) {
      drafts.remove(taskSlug);
      return;
    }
    drafts[taskSlug] = code;
  }
}
