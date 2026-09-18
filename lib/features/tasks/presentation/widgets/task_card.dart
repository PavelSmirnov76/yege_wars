import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/difficulty_badge.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/progress_badge.dart';

/// Карточка задачи в каталоге.
class TaskCard extends StatelessWidget {
  /// Создаёт карточку для строки каталога [item].
  const TaskCard({required this.item, required this.onTap, super.key});

  /// Строка каталога.
  final CatalogItem item;

  /// Переход к задаче.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stats = item.stats;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.task.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ProgressBadge(item.progress),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DifficultyBadge(item.task.difficulty),
                  Text(
                    stats.isEmpty
                        ? l10n.catalogNoAttempts
                        : l10n.catalogSolvedPercent(
                            stats.solvedPercent.round(),
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
