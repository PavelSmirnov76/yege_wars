import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';

/// Создаёт среду выполнения для браузера.
PythonRuntime createPythonRuntime() => PyodideRuntime();

/// Среда выполнения на Pyodide в Web Worker.
///
/// Код ученика выполняется в отдельном потоке, поэтому бесконечный цикл не
/// вешает интерфейс. Остановить выполнение изнутри невозможно (прерывание
/// Pyodide требует SharedArrayBuffer и особых заголовков, которых на
/// GitHub Pages нет), поэтому «Стоп» и таймаут убивают воркер и создают
/// новый. Загруженный Pyodide при этом теряется, но браузер берёт его из
/// своего кеша.
final class PyodideRuntime implements PythonRuntime {
  /// Создаёт среду; [workerUrl] переопределяется в тестах.
  PyodideRuntime({this.workerUrl = defaultWorkerUrl});

  /// Адрес воркера относительно корня приложения.
  static const String defaultWorkerUrl = 'pyodide_worker.js';

  /// Адрес воркера.
  final String workerUrl;

  final StreamController<PythonRuntimeState> _states =
      StreamController<PythonRuntimeState>.broadcast();

  web.Worker? _worker;
  Completer<RunResult>? _pending;
  Timer? _timer;
  Stopwatch? _stopwatch;
  int _lastRequestId = 0;
  PythonRuntimeState _state = PythonRuntimeState.idle;

  @override
  Stream<PythonRuntimeState> get states => _states.stream;

  @override
  PythonRuntimeState get state => _state;

  @override
  FutureResult<RunResult> run({
    required String code,
    String stdin = '',
    Map<String, String> files = const {},
    Duration timeout = defaultRunTimeout,
  }) async {
    if (_pending != null) {
      return const Err<RunResult>(
        ValidationFailure(message: 'Программа уже выполняется.'),
      );
    }

    final completer = Completer<RunResult>();
    _pending = completer;
    _stopwatch = Stopwatch()..start();
    _setState(PythonRuntimeState.running);

    try {
      _lastRequestId++;
      _ensureWorker().postMessage(
        <String, Object?>{
          'id': _lastRequestId,
          'type': 'run',
          'code': code,
          'stdin': stdin,
          'files': files,
        }.jsify(),
      );
    } on Object catch (error) {
      _pending = null;
      _setState(PythonRuntimeState.idle);
      return Err<RunResult>(
        UnexpectedFailure(
          message: 'Не удалось запустить среду Python. Обновите страницу.',
          cause: error,
        ),
      );
    }

    _timer = Timer(timeout, () {
      _restartWorker();
      _finish(
        RunResult(
          outcome: RunOutcome.timedOut,
          stderr:
              'Программа не уложилась в ${timeout.inSeconds} с '
              'и была остановлена.',
          duration: timeout,
        ),
      );
    });

    return Ok<RunResult>(await completer.future);
  }

  @override
  Future<void> stop() async {
    if (_pending == null) {
      return;
    }
    _restartWorker();
    _finish(const RunResult(outcome: RunOutcome.stopped));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _worker?.terminate();
    _worker = null;
    _states.close().ignore();
  }

  /// Создаёт воркер при первом обращении.
  web.Worker _ensureWorker() {
    final existing = _worker;
    if (existing != null) {
      return existing;
    }
    final worker = web.Worker(workerUrl.toJS)
      ..onmessage = _onMessage.toJS
      ..onerror = ((web.Event event) => _onWorkerError()).toJS;
    _worker = worker;
    return worker;
  }

  /// Убивает воркер: следующий запуск создаст новый.
  void _restartWorker() {
    _worker?.terminate();
    _worker = null;
  }

  /// Разбирает сообщение воркера.
  void _onMessage(web.MessageEvent event) {
    final data = event.data.dartify();
    if (data is! Map) {
      return;
    }
    switch (data['type']) {
      case 'loading':
        _setState(PythonRuntimeState.loading);
      case 'ready':
        if (_pending == null) {
          _setState(PythonRuntimeState.ready);
        }
      case 'result':
        _finish(
          RunResult(
            outcome: data['failed'] == true
                ? RunOutcome.failed
                : RunOutcome.finished,
            stdout: data['stdout'] as String? ?? '',
            stderr: data['stderr'] as String? ?? '',
            duration: _stopwatch?.elapsed ?? Duration.zero,
          ),
        );
    }
  }

  /// Ошибка самого воркера: не загрузился файл или упала среда.
  void _onWorkerError() {
    _restartWorker();
    _finish(
      const RunResult(
        outcome: RunOutcome.failed,
        stderr: 'Среда Python не запустилась. Проверьте соединение.',
      ),
    );
  }

  /// Завершает текущий запуск.
  void _finish(RunResult result) {
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    final pending = _pending;
    _pending = null;
    _setState(
      _worker == null ? PythonRuntimeState.idle : PythonRuntimeState.ready,
    );
    if (pending != null && !pending.isCompleted) {
      pending.complete(result);
    }
  }

  /// Меняет состояние и сообщает подписчикам.
  void _setState(PythonRuntimeState value) {
    _state = value;
    if (!_states.isClosed) {
      _states.add(value);
    }
  }
}
