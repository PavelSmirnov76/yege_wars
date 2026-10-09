import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';

/// Тема приложения (Material 3, тёмная) на основе дизайн-токенов.
///
/// Воплощает TOKEN-6.
abstract final class AppTheme {
  /// Минимальный размер тап-цели (доступность).
  static const double _minTapTarget = 44;

  /// Толщина рамки поля ввода в фокусе.
  static const double _focusedBorderWidth = 2;

  /// Скругление контролов (кнопки, поля ввода, снэкбары).
  static const BorderRadius _controlRadius = BorderRadius.all(
    Radius.circular(AppRadius.md),
  );

  /// Скругление контейнеров (карточки).
  static const BorderRadius _containerRadius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  /// Цветовая схема тёмной темы из токенов [AppColors].
  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accentHover,
    onSecondary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceElevated,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.danger,
    onError: AppColors.onAccent,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  /// Тёмная тема приложения.
  static ThemeData dark() {
    final textTheme = AppTypography.textTheme();

    return ThemeData(
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        iconTheme: WidgetStateProperty.resolveWith(_navigationIconTheme),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _navigationLabelStyle(textTheme, states),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        selectedIconTheme: const IconThemeData(color: AppColors.onAccent),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      // Обрезка по форме держит подсветку и всплеск нажатия внутри
      // скругления: без неё отклик InkWell рисуется прямоугольником.
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: _containerRadius,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(
            color: AppColors.accent,
            width: _focusedBorderWidth,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(
            color: AppColors.danger,
            width: _focusedBorderWidth,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            _filledButtonBackground,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(_buttonForeground),
          minimumSize: const WidgetStatePropertyAll(
            Size(_minTapTarget, _minTapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _controlRadius),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      // Кнопка-контур — того же размера и формы, что FilledButton; цвета —
      // из цветовой схемы: текст акцентом, контур — AppColors.border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(_minTapTarget, _minTapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _controlRadius),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            _textButtonForeground,
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(_minTapTarget, _minTapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _controlRadius),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Иконки нижней навигации: акцентная подложка у выбранного пункта.
  static IconThemeData _navigationIconTheme(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(color: AppColors.onAccent);
    }
    return const IconThemeData(color: AppColors.textSecondary);
  }

  /// Подписи нижней навигации.
  static TextStyle? _navigationLabelStyle(
    TextTheme textTheme,
    Set<WidgetState> states,
  ) {
    final selected = states.contains(WidgetState.selected);
    return textTheme.labelMedium?.copyWith(
      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
    );
  }

  /// Фон FilledButton по состояниям.
  static Color _filledButtonBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.surfaceElevated;
    }
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return AppColors.accentHover;
    }
    return AppColors.accent;
  }

  /// Цвет контента FilledButton по состояниям.
  static Color _buttonForeground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.textDisabled;
    }
    return AppColors.onAccent;
  }

  /// Цвет текста TextButton по состояниям.
  static Color _textButtonForeground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.textDisabled;
    }
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return AppColors.accentHover;
    }
    return AppColors.accent;
  }
}
