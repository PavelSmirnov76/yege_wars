import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Выделяет мышью текст от начала [from] до конца строки [to] и копирует
/// выделение сочетанием Ctrl+C; возвращает текст из буфера обмена.
///
/// Буфер обмена подменяется на время теста: скопированное приходит в канал
/// платформы, как в настоящем приложении. Ничего не выделилось — `null`.
Future<String?> selectAndCopy(
  WidgetTester tester, {
  required Finder from,
  required Finder to,
}) async {
  String? copied;
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  final gesture = await tester.startGesture(
    tester.getTopLeft(from) + const Offset(1, 1),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  // Правее конца последней строки — выделение идёт до её конца.
  await gesture.moveTo(tester.getBottomRight(to) + const Offset(20, -2));
  await tester.pump();
  await gesture.up();
  await gesture.removePointer();
  await tester.pumpAndSettle();

  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  return copied;
}
