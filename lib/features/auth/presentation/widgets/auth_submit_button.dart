import 'package:flutter/material.dart';

/// Кнопка отправки формы с индикатором загрузки.
///
/// Воплощает COMP-3.
class AuthSubmitButton extends StatelessWidget {
  /// Создаёт кнопку с подписью [label].
  ///
  /// Пока [isLoading] истинно, вместо подписи показывается индикатор,
  /// а нажатие игнорируется.
  const AuthSubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  /// Размер индикатора загрузки.
  static const double _progressSize = 20;

  /// Толщина линии индикатора.
  static const double _progressStroke = 2;

  /// Подпись кнопки.
  final String label;

  /// Идёт ли отправка.
  final bool isLoading;

  /// Обработчик нажатия; `null` делает кнопку неактивной.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: _progressSize,
              width: _progressSize,
              child: CircularProgressIndicator(strokeWidth: _progressStroke),
            )
          : Text(label),
    );
  }
}
