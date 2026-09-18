import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/verdict_banner.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';

/// Отправка ответа: поле, вердикт и публикация верного решения.
class SubmitPanel extends ConsumerStatefulWidget {
  /// Создаёт панель для задачи [task]; [codeOf] отдаёт текущий код.
  const SubmitPanel({required this.task, required this.codeOf, super.key});

  /// Задача.
  final TaskDetail task;

  /// Текущий код из редактора: он сохраняется вместе с попыткой.
  final String Function() codeOf;

  @override
  ConsumerState<SubmitPanel> createState() => _SubmitPanelState();
}

class _SubmitPanelState extends ConsumerState<SubmitPanel> {
  final TextEditingController _answerController = TextEditingController();
  bool _publishOffered = true;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  /// Отправляет ответ на проверку.
  Future<void> _submit() async {
    setState(() => _publishOffered = true);
    await ref
        .read(submitControllerProvider(widget.task.brief.id).notifier)
        .submit(
          answer: _answerController.text,
          code: widget.codeOf(),
        );
  }

  /// Публикует только что принятое решение.
  Future<void> _publish(String submissionId) async {
    await ref
        .read(publishControllerProvider(widget.task.brief.id).notifier)
        .setPublished(submissionId: submissionId, isPublished: true);
    if (mounted) {
      setState(() => _publishOffered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final taskId = widget.task.brief.id;
    final submit = ref.watch(submitControllerProvider(taskId));
    // Ответ обычно печатает сама программа — предлагаем последнюю строку.
    final output = ref
        .watch(runControllerProvider(widget.task.brief.slug))
        .result
        ?.lastLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _answerController,
                style: AppTypography.code(),
                decoration: InputDecoration(
                  labelText: l10n.submitAnswerLabel,
                  hintText: l10n.submitAnswerHint,
                ),
                onSubmitted: (_) => unawaited(_submit()),
              ),
            ),
            if (output != null && output.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () => _answerController.text = output,
                child: Text(l10n.submitTakeFromOutput),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: submit.isSubmitting ? null : () => unawaited(_submit()),
          icon: const Icon(Icons.send),
          label: Text(
            submit.isSubmitting ? l10n.submitSending : l10n.submitButton,
          ),
        ),
        if (submit.failure case final failure?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            failure.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
        if (submit.result case final result?) ...[
          const SizedBox(height: AppSpacing.md),
          VerdictBanner(isCorrect: result.isCorrect),
          if (result.isCorrect && _publishOffered) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.submitSolvedTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.submitPublishedHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton.tonal(
                  onPressed: () => unawaited(_publish(result.submissionId)),
                  child: Text(l10n.submitPublish),
                ),
                TextButton(
                  onPressed: () => setState(() => _publishOffered = false),
                  child: Text(l10n.submitNotNow),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.attemptsTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AttemptsList(taskId: taskId),
      ],
    );
  }
}
