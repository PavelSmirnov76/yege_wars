import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/python_runtime/python_runtime.dart';
// Реализация выбирается на этапе сборки: в браузере — Pyodide,
// в тестах на виртуальной машине Dart — заглушка.
import 'package:yege_wars/core/python_runtime/unsupported_python_runtime.dart'
    if (dart.library.js_interop) 'package:yege_wars/core/python_runtime/pyodide_runtime.dart';

part 'python_runtime_provider.g.dart';

/// Среда выполнения Python: одна на всё приложение.
///
/// Pyodide весит десятки мегабайт, поэтому среда создаётся лениво и живёт
/// до конца сессии.
@Riverpod(keepAlive: true)
PythonRuntime pythonRuntime(Ref ref) {
  final runtime = createPythonRuntime();
  ref.onDispose(runtime.dispose);
  return runtime;
}
