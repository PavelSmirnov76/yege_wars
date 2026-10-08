import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';

/// Карточка формы авторизации по центру экрана.
///
/// Воплощает COMP-1.
class AuthFormCard extends StatelessWidget {
  /// Создаёт карточку с заголовком [title] и содержимым [children].
  const AuthFormCard({
    required this.title,
    required this.children,
    super.key,
  });

  /// Максимальная ширина карточки.
  static const double _maxWidth = 400;

  /// Заголовок формы.
  final String title;

  /// Содержимое формы.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
