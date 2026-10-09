import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/markdown/python_highlighter.dart';

/// Блок кода с подсветкой Python и горизонтальной прокруткой.
///
/// Прокрутка обязательна: длинная строка кода не должна ломать вёрстку
/// на экране шириной 360 px и не должна переноситься — в коде перенос
/// меняет смысл отступов.
///
/// Внутри области выделения экрана (`SelectionArea`) код — обычный текст и
/// выделяется вместе с текстом вокруг; вне её, как в решениях других, —
/// выделяемый сам по себе. Так же решает и `Text`.
///
/// Воплощает COMP-11.
class CodeBlock extends StatelessWidget {
  /// Создаёт блок кода.
  const CodeBlock({required this.code, this.language, super.key});

  /// Языки, для которых включается подсветка.
  static const Set<String> _pythonAliases = {'python', 'py', 'python3'};

  /// Текст кода.
  final String code;

  /// Язык из ограды блока (` ```python `), если указан.
  final String? language;

  /// Цвет фрагмента кода.
  static Color _colorOf(CodeTokenKind kind) => switch (kind) {
    CodeTokenKind.keyword => AppColors.codeKeyword,
    CodeTokenKind.builtin => AppColors.codeBuiltin,
    CodeTokenKind.string => AppColors.codeString,
    CodeTokenKind.number => AppColors.codeNumber,
    CodeTokenKind.comment => AppColors.codeComment,
    CodeTokenKind.plain => AppColors.textPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.code();
    // Язык не указан — считаем, что это Python: других языков в задачах нет.
    final isPython =
        language == null || _pythonAliases.contains(language!.toLowerCase());
    final spans = isPython
        ? [
            for (final token in PythonHighlighter.highlight(code))
              TextSpan(
                text: token.text,
                style: style.copyWith(color: _colorOf(token.kind)),
              ),
          ]
        : [TextSpan(text: code, style: style)];
    final text = TextSpan(children: spans);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectionContainer.maybeOf(context) == null
            ? SelectableText.rich(text)
            : Text.rich(text),
      ),
    );
  }
}
