import 'package:flutter/material.dart';

/// Экран ожидания, пока восстанавливается сессия.
///
/// Показывается вместо целевого экрана, чтобы guard'ы не увели
/// пользователя на вход раньше, чем станет известен статус авторизации.
class SplashScreen extends StatelessWidget {
  /// Создаёт экран ожидания.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
