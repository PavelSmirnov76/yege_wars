import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';

/// Сообщение под заголовком формы: ошибка или предупреждение.
///
/// Воплощает COMP-2.
class AuthMessage extends StatelessWidget {
  /// Создаёт сообщение [text].
  ///
  /// [isError] окрашивает текст в цвет ошибки, иначе — предупреждения.
  const AuthMessage(this.text, {this.isError = true, super.key});

  /// Текст сообщения.
  final String text;

  /// Ошибка (`true`) или предупреждение (`false`).
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isError ? AppColors.danger : AppColors.warning,
        ),
      ),
    );
  }
}
