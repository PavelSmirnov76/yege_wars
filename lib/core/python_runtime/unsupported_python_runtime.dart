import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';

/// Создаёт среду выполнения вне браузера — заглушку.
PythonRuntime createPythonRuntime() => const UnsupportedPythonRuntime();

/// Заглушка для платформ без браузера (тесты на виртуальной машине Dart).
///
/// Реальная среда работает на Pyodide и существует только в вебе; здесь
/// запуск сразу возвращает понятную ошибку вместо падения.
final class UnsupportedPythonRuntime implements PythonRuntime {
  /// Создаёт заглушку.
  const UnsupportedPythonRuntime();

  @override
  Stream<PythonRuntimeState> get states => const Stream.empty();

  @override
  PythonRuntimeState get state => PythonRuntimeState.idle;

  @override
  FutureResult<RunResult> run({
    required String code,
    String stdin = '',
    Map<String, String> files = const {},
    Duration timeout = defaultRunTimeout,
  }) async => const Err<RunResult>(
    UnexpectedFailure(message: 'Запуск Python доступен только в браузере.'),
  );

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
