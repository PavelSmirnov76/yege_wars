import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';

/// Чужие опубликованные решения задачи.
///
/// Доступ решает база: пока у ученика нет своей верной попытки, список
/// приходит пустым — поэтому до первого верного ответа показываем
/// объяснение, а не «пусто».
class SolutionsList extends ConsumerWidget {
  /// Создаёт список решений задачи [taskId].
  const SolutionsList({
    required this.taskId,
    required this.isUnlocked,
    super.key,
  });

  /// Идентификатор задачи.
  final String taskId;

  /// Решил ли ученик задачу верно.
  final bool isUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    if (!isUnlocked) {
      return Text(l10n.solutionsLocked, style: hintStyle);
    }

    final solutions = ref.watch(publishedSolutionsProvider(taskId));
    return switch (solutions) {
      AsyncData(:final value) when value.isEmpty => Text(
        l10n.solutionsEmpty,
        style: hintStyle,
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final solution in value) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                l10n.solutionAuthor(
                  solution.authorUsername ?? '',
                  attemptTimeLabel(solution.createdAt),
                ),
                style: theme.textTheme.labelLarge,
              ),
            ),
            CodeBlock(code: solution.code),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
