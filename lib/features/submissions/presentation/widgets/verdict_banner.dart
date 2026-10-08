import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';

/// Крупная понятная индикация «Верно / Неверно».
///
/// Воплощает COMP-10.
class VerdictBanner extends StatelessWidget {
  /// Создаёт индикацию для результата [isCorrect].
  const VerdictBanner({required this.isCorrect, super.key});

  /// Прозрачность подложки.
  static const double _backgroundOpacity = 0.15;

  /// Размер значка.
  static const double _iconSize = 28;

  /// Верен ли ответ.
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = isCorrect ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundOpacity),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: color,
            size: _iconSize,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isCorrect ? l10n.submitCorrect : l10n.submitWrong,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
