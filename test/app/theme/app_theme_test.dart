import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_theme.dart';

import '../../helpers/button_height.dart';

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

    testWidgets(
      'TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44',
      (tester) async {
        // Тема собирается в теле теста: плотность по умолчанию берётся
        // из платформы, которую подменяет вариант.
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                ],
              ),
            ),
          ),
        );

        for (final type in [FilledButton, OutlinedButton, TextButton]) {
          expect(
            visibleButtonHeight(tester, find.byType(type)),
            greaterThanOrEqualTo(minTapTarget),
            reason: '$type',
          );
        }
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  });
}
