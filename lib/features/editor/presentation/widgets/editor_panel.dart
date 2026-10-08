import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/editor_providers.dart';
import 'package:yege_wars/features/editor/presentation/controllers/run_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/code_editor.dart';
import 'package:yege_wars/features/editor/presentation/widgets/console_view.dart';
import 'package:yege_wars/features/editor/presentation/widgets/python_editing_controller.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/submit_panel.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';

/// Панель решения задачи: редактор, ввод, запуск и консоль.
///
/// Под консолью — отправка ответа, [SubmitPanel].
///
/// Реализует UC-16 и UC-17.
class EditorPanel extends ConsumerStatefulWidget {
  /// Создаёт панель для задачи [task].
  const EditorPanel({required this.task, super.key});

  /// Задача, которую решает ученик.
  final TaskDetail task;

  @override
  ConsumerState<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends ConsumerState<EditorPanel> {
  /// Пауза перед сохранением черновика.
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  final PythonEditingController _codeController = PythonEditingController();
  final TextEditingController _stdinController = TextEditingController();
  Timer? _saveDebounceTimer;
  bool _draftLoaded = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _codeController
      ..removeListener(_scheduleSave)
      ..dispose();
    _stdinController.dispose();
    super.dispose();
  }

  /// Откладывает сохранение черновика, чтобы не писать на каждую клавишу.
  void _scheduleSave() {
    if (!_draftLoaded) {
      return;
    }
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveDebounce, () {
      ref
          .read(draftStorageProvider)
          .write(widget.task.brief.slug, _codeController.text)
          .ignore();
    });
  }

  /// Запускает программу.
  Future<void> _run() async {
    await ref
        .read(runControllerProvider(widget.task.brief.slug).notifier)
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

    // Черновик подставляется один раз, чтобы не затирать набранное.
    final draft = ref.watch(taskDraftProvider(slug)).value;
    if (!_draftLoaded && draft != null) {
      _draftLoaded = true;
      if (draft.isNotEmpty) {
        // Менять контроллер во время построения нельзя — ждём кадр.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _codeController.text.isEmpty) {
            _codeController.text = draft;
          }
        });
      }
    }

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
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: runState.isRunning ? null : () => unawaited(_run()),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.editorRun),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: runState.isRunning
                  ? () => unawaited(
                      ref.read(runControllerProvider(slug).notifier).stop(),
                    )
                  : null,
              icon: const Icon(Icons.stop),
              label: Text(l10n.editorStop),
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
