import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/widgets/python_editing_controller.dart';

/// Поле ввода кода с подсветкой Python.
///
/// Ctrl/Cmd+Enter запускает программу, не отпуская клавиатуру.
///
/// Воплощает COMP-8.
class CodeEditor extends StatelessWidget {
  /// Создаёт редактор.
  const CodeEditor({
    required this.controller,
    required this.onRun,
    this.minLines = 10,
    super.key,
  });

  /// Контроллер текста с подсветкой.
  final PythonEditingController controller;

  /// Запуск программы.
  final VoidCallback onRun;

  /// Минимальная высота поля в строках.
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onRun,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onRun,
      },
      child: TextField(
        controller: controller,
        style: AppTypography.code(),
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: l10n.editorCodePlaceholder,
          hintStyle: AppTypography.code().copyWith(
            color: AppColors.textDisabled,
          ),
          filled: true,
          fillColor: AppColors.codeBackground,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
