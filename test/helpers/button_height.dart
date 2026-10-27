import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Минимальная тап-цель кнопок по TOKEN-6, в логических пикселях.
const double minTapTarget = 44;

/// Видимая высота кнопки [button] — высота её подложки [Material], без
/// прозрачных полей области нажатия (`MaterialTapTargetSize.padded`).
double visibleButtonHeight(WidgetTester tester, Finder button) => tester
    .getSize(find.descendant(of: button, matching: find.byType(Material)).first)
    .height;
