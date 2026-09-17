import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Маркеры служебных сообщений google_fonts о невозможности загрузить
/// шрифт. В тестовом окружении шрифты недоступны (сетевая загрузка
/// выключена, в ассетах их нет): google_fonts корректно откатывается
/// на fallback-шрифт, но печатает эти сообщения через [debugPrint] —
/// для тестов это заведомый шум, а не ошибка.
const List<String> _googleFontsNoiseMarkers = [
  'google_fonts was unable to load font',
  'wrong with your test',
  "If troubleshooting doesn't solve the problem",
];

/// [debugPrint], отбрасывающий шум google_fonts об отсутствии шрифта;
/// остальные сообщения печатает стандартным [debugPrintThrottled].
void _quietDebugPrint(String? message, {int? wrapWidth}) {
  final isNoise =
      message != null && _googleFontsNoiseMarkers.any(message.contains);
  if (isNoise) {
    return;
  }
  debugPrintThrottled(message, wrapWidth: wrapWidth);
}

/// Тестовый биндинг с фильтрованным [debugPrint].
///
/// Глобально подменять [debugPrint] нельзя: flutter_test после каждого
/// теста сверяет его с [debugPrintOverride] и падает при расхождении,
/// поэтому фильтр задаётся через переопределение [debugPrintOverride].
class _QuietTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  DebugPrintCallback get debugPrintOverride => _quietDebugPrint;
}

/// Общая конфигурация тестового окружения.
///
/// Запрещает google_fonts загружать шрифты по сети (тесты не должны
/// зависеть от сети; вместо загрузки используется fallback-шрифт)
/// и глушит сообщения google_fonts об отсутствии шрифта, чтобы вывод
/// тестов оставался чистым.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Биндинг создаётся до testMain, чтобы стандартный
  // AutomatedTestWidgetsFlutterBinding не успел занять его место.
  _QuietTestBinding();

  GoogleFonts.config.allowRuntimeFetching = false;

  await testMain();
}
