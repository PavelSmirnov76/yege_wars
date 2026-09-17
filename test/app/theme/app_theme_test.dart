import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme.dark', () {
    test('возвращает тёмную тему', () {
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('фон Scaffold — AppColors.background', () {
      expect(
        AppTheme.dark().scaffoldBackgroundColor,
        AppColors.background,
      );
    });

    test('primary цветовой схемы — AppColors.accent', () {
      expect(AppTheme.dark().colorScheme.primary, AppColors.accent);
    });

    test('использует Material 3', () {
      expect(AppTheme.dark().useMaterial3, isTrue);
    });
  });
}
