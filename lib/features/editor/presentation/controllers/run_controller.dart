import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
import 'package:yege_wars/core/python_runtime/python_runtime_provider.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';

part 'run_controller.g.dart';

/// Состояние запуска программы для одной задачи.
final class RunState {
  /// Создаёт состояние.
  const RunState({
    this.runtimeState = PythonRuntimeState.idle,
    this.result,
    this.failure,
  });

  /// Состояние среды выполнения.
  final PythonRuntimeState runtimeState;

  /// Итог последнего запуска.
  final RunResult? result;

  /// Ошибка самой среды (не программы ученика).
  final Failure? failure;

  /// Идёт ли выполнение.
  bool get isRunning => runtimeState == PythonRuntimeState.running;

  /// Грузится ли среда.
  bool get isLoadingRuntime => runtimeState == PythonRuntimeState.loading;

  /// Идёт ли запуск: грузится среда или выполняется программа. Пока идёт,
  /// «Запустить» недоступна, а «Стоп» доступна.
  bool get isBusy => isLoadingRuntime || isRunning;
}

/// Запуск кода задачи: держит состояние среды и последний результат.
///
/// Реализует UC-32.
@riverpod
class RunController extends _$RunController {
  @override
  RunState build(String taskSlug) {
    final runtime = ref.watch(pythonRuntimeProvider);
    final subscription = runtime.states.listen((runtimeState) {
      state = RunState(
        runtimeState: runtimeState,
        result: state.result,
        failure: state.failure,
      );
    });
    ref.onDispose(subscription.cancel);
    return RunState(runtimeState: runtime.state);
  }

  /// Запускает [code] с файлами задачи и вводом [stdin].
  Future<void> run({
    required String code,
    String stdin = '',
    List<TaskFile> files = const [],
    Duration timeout = defaultRunTimeout,
  }) async {
    final runtime = ref.read(pythonRuntimeProvider);
    state = const RunState(runtimeState: PythonRuntimeState.running);

    final result = await runtime.run(
      code: code,
      stdin: stdin,
      files: {for (final file in files) file.filename: file.content},
      timeout: timeout,
    );
    if (!ref.mounted) {
      return;
    }

    state = result.fold(
      onOk: (value) => RunState(runtimeState: runtime.state, result: value),
      onErr: (failure) =>
          RunState(runtimeState: runtime.state, failure: failure),
    );
  }

  /// Останавливает выполнение.
  Future<void> stop() => ref.read(pythonRuntimeProvider).stop();

  /// Убирает вывод прошлого запуска.
  void clear() => state = RunState(runtimeState: state.runtimeState);
}
