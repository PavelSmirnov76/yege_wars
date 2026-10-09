import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';
import 'package:yege_wars/features/submissions/domain/entities/submission.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';

/// Дата и время попытки в коротком виде.
String attemptTimeLabel(DateTime moment) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(moment.day)}.${two(moment.month)} '
      '${two(moment.hour)}:${two(moment.minute)}';
}

/// Мои попытки по задаче: ответ, вердикт и переключатель публикации.
///
/// Не загрузились — вместо списка сообщение и «Повторить». Не удалось
/// переключить публикацию — переключатель прежний, а внизу экрана сообщение
/// с текстом ошибки.
///
/// Реализует UC-33 и UC-34.
class AttemptsList extends ConsumerWidget {
  /// Создаёт список попыток задачи [taskId].
  const AttemptsList({required this.taskId, super.key});

  /// Размер значка вердикта.
  static const double _iconSize = 18;

  /// Идентификатор задачи.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final attempts = ref.watch(myAttemptsProvider(taskId));

    return switch (attempts) {
      AsyncData(:final value) when value.isEmpty => Text(
        l10n.attemptsEmpty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final attempt in value)
            _AttemptTile(attempt: attempt, taskId: taskId),
        ],
      ),
      AsyncError(:final error) => ReferenceErrorView(
        error: error,
        onRetry: () => ref.invalidate(myAttemptsProvider(taskId)),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Одна попытка.
class _AttemptTile extends ConsumerWidget {
  const _AttemptTile({required this.attempt, required this.taskId});

  final Submission attempt;
  final String taskId;

  /// Переключает публикацию; сбой — сообщением внизу экрана.
  Future<void> _setPublished(
    BuildContext context,
    WidgetRef ref, {
    required bool isPublished,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(publishControllerProvider(taskId).notifier)
        .setPublished(submissionId: attempt.id, isPublished: isPublished);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = attempt.isCorrect ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            attempt.isCorrect ? Icons.check_circle : Icons.cancel,
            size: AttemptsList._iconSize,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(attempt.answer, style: AppTypography.code()),
          ),
          Text(
            attemptTimeLabel(attempt.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (attempt.canPublish) ...[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: l10n.attemptPublishedSwitch,
              child: Switch(
                value: attempt.isPublished,
                onChanged: (value) => unawaited(
                  _setPublished(context, ref, isPublished: value),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
