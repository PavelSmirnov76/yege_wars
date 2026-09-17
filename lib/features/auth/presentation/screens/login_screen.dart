import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';

/// Экран входа.
///
/// Этап 1: форма без валидации, кнопка вызывает заглушку
/// [AuthController.signIn]; настоящая авторизация — на этапе 3.
class LoginScreen extends ConsumerWidget {
  /// Создаёт экран входа.
  const LoginScreen({super.key});

  /// Максимальная ширина карточки формы.
  static const double _maxCardWidth = 400;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxCardWidth),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authLoginTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.authUsernameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.authPasswordLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).signIn(),
                      child: Text(l10n.authSignInButton),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.goNamed(AppRoutes.registerName),
                      child: Text(l10n.authNoAccountLink),
                    ),
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
