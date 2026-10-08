import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Русское название сложности.
String difficultyLabel(TaskDifficulty difficulty, AppLocalizations l10n) =>
    switch (difficulty) {
      TaskDifficulty.easy => l10n.difficultyEasy,
      TaskDifficulty.medium => l10n.difficultyMedium,
      TaskDifficulty.hard => l10n.difficultyHard,
    };

/// Цветная метка сложности задачи.
///
/// Воплощает COMP-6.
class DifficultyBadge extends StatelessWidget {
  /// Создаёт метку для сложности [difficulty].
  const DifficultyBadge(this.difficulty, {super.key});

  /// Прозрачность подложки метки.
  static const double _backgroundOpacity = 0.15;

  /// Сложность задачи.
  final TaskDifficulty difficulty;

  /// Цвет метки.
  static Color colorOf(TaskDifficulty difficulty) => switch (difficulty) {
    TaskDifficulty.easy => AppColors.difficultyEasy,
    TaskDifficulty.medium => AppColors.difficultyMedium,
    TaskDifficulty.hard => AppColors.difficultyHard,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundOpacity),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        difficultyLabel(difficulty, context.l10n),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
