import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yege_wars/app/theme/app_colors.dart';

/// Типографика приложения: Inter для интерфейса,
/// JetBrains Mono для кода.
///
/// Воплощает TOKEN-2.
abstract final class AppTypography {
  /// Размер шрифта кода по умолчанию.
  static const double _defaultCodeFontSize = 14;

  /// Межстрочный интервал для кода.
  static const double _codeLineHeight = 1.5;

  /// Текстовая тема на базе Inter поверх тёмной типографики
  /// Material 2021, с цветами из [AppColors].
  static TextTheme textTheme() {
    final base = GoogleFonts.interTextTheme(Typography.material2021().white);
    return base.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      decorationColor: AppColors.textPrimary,
    );
  }

  /// Моноширинный стиль для кода — JetBrains Mono.
  static TextStyle code({double fontSize = _defaultCodeFontSize}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      height: _codeLineHeight,
      color: AppColors.textPrimary,
    );
  }
}
