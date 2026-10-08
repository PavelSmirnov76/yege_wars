import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/core/markdown/python_highlighter.dart';

/// Контроллер поля ввода с подсветкой Python.
///
/// Свой контроллер вместо пакета-редактора: разбор кода на токены уже есть
/// (им же подсвечиваются примеры в справочнике), а обычное поле ввода
/// работает в любом мобильном браузере.
///
/// Воплощает COMP-8.
class PythonEditingController extends TextEditingController {
  /// Создаёт контроллер с начальным текстом.
  PythonEditingController({super.text});

  /// Цвет фрагмента кода.
  static Color colorOf(CodeTokenKind kind) => switch (kind) {
    CodeTokenKind.keyword => AppColors.codeKeyword,
    CodeTokenKind.builtin => AppColors.codeBuiltin,
    CodeTokenKind.string => AppColors.codeString,
    CodeTokenKind.number => AppColors.codeNumber,
    CodeTokenKind.comment => AppColors.codeComment,
    CodeTokenKind.plain => AppColors.textPrimary,
  };

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    return TextSpan(
      style: style,
      children: [
        for (final token in PythonHighlighter.highlight(text))
          TextSpan(
            text: token.text,
            style: (style ?? const TextStyle()).copyWith(
              color: colorOf(token.kind),
            ),
          ),
      ],
    );
  }
}
