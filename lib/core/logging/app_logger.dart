import 'dart:developer' as developer;

/// Журнал приложения.
///
/// Пишет через `dart:developer`: в вебе сообщения видно в консоли браузера,
/// при `flutter run` — в терминале. `print` в проекте запрещён, а следить
/// за загрузкой среды Python и обращениями к сети надо.
abstract final class AppLogger {
  /// Имя источника сообщений.
  static const String _name = 'yege_wars';

  /// Уровень обычного сообщения.
  static const int _infoLevel = 800;

  /// Уровень ошибки.
  static const int _errorLevel = 1000;

  /// Обычное сообщение о ходе работы.
  static void info(String message) =>
      developer.log(message, name: _name, level: _infoLevel);

  /// Сообщение об ошибке с причиной.
  static void error(String message, {Object? cause, StackTrace? stackTrace}) =>
      developer.log(
        message,
        name: _name,
        level: _errorLevel,
        error: cause,
        stackTrace: stackTrace,
      );
}
