import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/controllers/draft_controller.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/code_editor.dart';
import 'package:yege_wars/features/editor/presentation/widgets/console_view.dart';
import 'package:yege_wars/features/editor/presentation/widgets/python_editing_controller.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/submit_panel.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';

/// Панель решения задачи: редактор, ввод, запуск и консоль.
///
/// Под консолью — отправка ответа, [SubmitPanel]. Код поля — черновик
/// задачи из [DraftController]: его держит страница задачи, панель берёт код
/// при создании и отдаёт туда каждую правку.
///
/// Реализует UC-31 и UC-32.
class EditorPanel extends ConsumerStatefulWidget {
  /// Создаёт панель для задачи [task].
  const EditorPanel({required this.task, super.key});

  /// Задача, которую решает ученик.
  final TaskDetail task;

  @override
  ConsumerState<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends ConsumerState<EditorPanel> {
  late final PythonEditingController _codeController = PythonEditingController(
    text: _draft.currentCode(),
  );
  final TextEditingController _stdinController = TextEditingController();

  /// Черновик задачи; живёт, пока открыта страница задачи.
  DraftController get _draft =>
      ref.read(draftControllerProvider(widget.task.brief.id).notifier);

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    _stdinController.dispose();
    super.dispose();
  }

  /// Правка уходит в черновик, записывает его контроллер.
  void _onCodeChanged() => _draft.edit(_codeController.text);

  /// Запускает программу; черновик записывается сразу, запуск этого не ждёт.
  Future<void> _run() async {
    final slug = widget.task.brief.slug;
    // Ctrl/Cmd+Enter во время запуска — как недоступная «Запустить».
    if (ref.read(runControllerProvider(slug)).isBusy) {
      return;
    }
    _draft.flush();
    await ref
        .read(runControllerProvider(slug).notifier)
        .run(
          code: _codeController.text,
          stdin: _stdinController.text,
          files: widget.task.files,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final slug = widget.task.brief.slug;
    final runState = ref.watch(runControllerProvider(slug));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CodeEditor(controller: _codeController, onRun: () => unawaited(_run())),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.editorRunHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ExpansionTile(
          title: Text(l10n.editorStdinTitle, style: theme.textTheme.titleSmall),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            TextField(
              controller: _stdinController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: l10n.editorStdinHint),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // «Запустить» и «Стоп» делят строку поровну; подпись, которой не
        // хватило места, обрезается многоточием, а не рвётся по буквам.
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: runState.isBusy ? null : () => unawaited(_run()),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  l10n.editorRun,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: runState.isBusy
                    ? () => unawaited(
                        ref.read(runControllerProvider(slug).notifier).stop(),
                      )
                    : null,
                icon: const Icon(Icons.stop),
                label: Text(
                  l10n.editorStop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                runStatusLabel(runState, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (runState.isLoadingRuntime || runState.isRunning)
              const SizedBox(
                height: AppSpacing.lg,
                width: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ConsoleView(state: runState),
        const Divider(height: AppSpacing.xxl),
        SubmitPanel(
          task: widget.task,
          codeOf: () => _codeController.text,
        ),
      ],
    );
  }
}
