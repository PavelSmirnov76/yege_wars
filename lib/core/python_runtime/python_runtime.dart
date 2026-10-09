import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';

/// Состояние среды выполнения Python.
enum PythonRuntimeState {
  /// Среда ещё не понадобилась.
  idle,

  /// Идёт загрузка среды (первый запуск тянет Pyodide с CDN).
  loading,

  /// Среда загружена и свободна.
  ready,

  /// Выполняется программа.
  running,
}

/// Среда выполнения Python.
///
/// Интерфейс намеренно узкий: реализация на Pyodide в браузере может быть
/// заменена на серверную (например, Judge0) без изменения интерфейса.
///
/// Реализует UC-32.
abstract interface class PythonRuntime {
  /// Поток состояний: по нему UI показывает загрузку и выполнение.
  Stream<PythonRuntimeState> get states;

  /// Текущее состояние.
  PythonRuntimeState get state;

  /// Запускает [code].
  ///
  /// [files] пишутся в виртуальную файловую систему под своими именами,
  /// чтобы `open('24.txt')` работал как на экзамене. [stdin] подменяет
  /// стандартный ввод, [timeout] ограничивает время работы.
  FutureResult<RunResult> run({
    required String code,
    String stdin,
    Map<String, String> files,
    Duration timeout,
  });

  /// Останавливает выполнение.
  Future<void> stop();

  /// Освобождает ресурсы.
  void dispose();
}

/// Время выполнения по умолчанию.
const Duration defaultRunTimeout = Duration(seconds: 60);

/// Состояние среды, когда воркер сообщил, что Python загружен.
///
/// Если загрузку начал запуск ([isRunPending]), он продолжается: программа
/// выполняется, и «Стоп» по-прежнему доступна. Иначе среда просто готова.
///
/// Реализует UC-32.
PythonRuntimeState runtimeStateOnReady({required bool isRunPending}) =>
    isRunPending ? PythonRuntimeState.running : PythonRuntimeState.ready;
