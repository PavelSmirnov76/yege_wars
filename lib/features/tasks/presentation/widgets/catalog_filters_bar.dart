import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/difficulty_badge.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/progress_badge.dart';

/// Фильтры каталога: номер задания, сложность и состояние решения.
class CatalogFiltersBar extends ConsumerWidget {
  /// Создаёт панель фильтров.
  const CatalogFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(taskFilterControllerProvider);
    final controller = ref.read(taskFilterControllerProvider.notifier);
    final egeNumbers = ref.watch(catalogEgeNumbersProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (egeNumbers.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final number in egeNumbers)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(l10n.referenceEgeNumber(number)),
                      selected: filter.egeNumber == number,
                      onSelected: (_) => controller.toggleEgeNumber(number),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final difficulty in TaskDifficulty.values)
              FilterChip(
                label: Text(difficultyLabel(difficulty, l10n)),
                selected: filter.difficulty == difficulty,
                onSelected: (_) => controller.toggleDifficulty(difficulty),
              ),
            for (final progress in TaskProgress.values)
              FilterChip(
                label: Text(progressLabel(progress, l10n)),
                selected: filter.progress == progress,
                onSelected: (_) => controller.toggleProgress(progress),
              ),
            if (!filter.isEmpty)
              TextButton(
                onPressed: controller.reset,
                child: Text(l10n.catalogResetFilters),
              ),
          ],
        ),
      ],
    );
  }
}
