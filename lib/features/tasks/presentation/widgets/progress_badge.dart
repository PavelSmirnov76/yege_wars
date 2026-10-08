import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Русское название состояния решения.
String progressLabel(TaskProgress progress, AppLocalizations l10n) =>
    switch (progress) {
      TaskProgress.solved => l10n.progressSolved,
      TaskProgress.attempted => l10n.progressAttempted,
      TaskProgress.notStarted => l10n.progressNotStarted,
    };

/// Метка состояния решения задачи.
///
/// Нерешённые задачи метки не получают: в каталоге их большинство, и
/// подпись «не начата» у каждой карточки была бы шумом.
///
/// Воплощает COMP-7.
class ProgressBadge extends StatelessWidget {
  /// Создаёт метку для состояния [progress].
  const ProgressBadge(this.progress, {super.key});

  /// Размер иконки.
  static const double _iconSize = 16;

  /// Состояние решения.
  final TaskProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress == TaskProgress.notStarted) {
      return const SizedBox.shrink();
    }
    final isSolved = progress == TaskProgress.solved;
    final color = isSolved ? AppColors.success : AppColors.warning;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSolved ? Icons.check_circle : Icons.more_horiz,
          size: _iconSize,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          progressLabel(progress, context.l10n),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
