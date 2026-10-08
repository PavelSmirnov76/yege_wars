import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/python_runtime/run_result.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Строка состояния запуска.
String runStatusLabel(RunState state, AppLocalizations l10n) {
  if (state.isLoadingRuntime) {
    return l10n.editorLoadingRuntime;
  }
  if (state.isRunning) {
    return l10n.editorRunning;
  }
  final result = state.result;
  return switch (result?.outcome) {
    RunOutcome.finished => l10n.editorFinished(
      (result!.duration.inMilliseconds / 1000).toStringAsFixed(1),
    ),
    RunOutcome.failed => l10n.editorFailed,
    RunOutcome.timedOut => l10n.editorTimedOut,
    RunOutcome.stopped => l10n.editorStopped,
    null => '',
  };
}

/// Консоль: вывод программы и сообщения об ошибках.
///
/// Воплощает COMP-9.
class ConsoleView extends StatelessWidget {
  /// Создаёт консоль для состояния [state].
  const ConsoleView({required this.state, super.key});

  /// Минимальная высота области вывода.
  static const double _minHeight = 120;

  /// Состояние запуска.
  final RunState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final result = state.result;
    final failure = state.failure;
    final hasOutput =
        (result?.stdout.isNotEmpty ?? false) ||
        (result?.stderr.isNotEmpty ?? false) ||
        failure != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: !hasOutput
          ? Text(
              l10n.editorConsoleEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            )
          : SingleChildScrollView(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    if (result != null && result.stdout.isNotEmpty)
                      TextSpan(
                        text: result.stdout,
                        style: AppTypography.code(),
                      ),
                    if (result != null && result.stderr.isNotEmpty)
                      TextSpan(
                        text: '\n${result.stderr}',
                        style: AppTypography.code().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    if (failure != null)
                      TextSpan(
                        text: failure.message,
                        style: AppTypography.code().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
