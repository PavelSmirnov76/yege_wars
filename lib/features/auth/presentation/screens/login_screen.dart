import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/auth/domain/auth_state.dart';
import 'package:yege_wars/features/auth/presentation/auth_field_validators.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_message.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_submit_button.dart';

/// Экран входа по логину и паролю.
///
/// Реализует UC-10 и UC-1.
class LoginScreen extends ConsumerStatefulWidget {
  /// Создаёт экран входа с адресом [from], который откроется после входа.
  const LoginScreen({this.from, super.key});

  /// Адрес, на который шёл посетитель ([AppRoutes.fromQueryParam]):
  /// ссылка на регистрацию передаёт его дальше.
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Отправляет форму; при успехе переход выполняет guard роутера.
  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = result.failureOrNull?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Ошибка прошлой сессии (например, профиль не прочитался при
    // восстановлении) тоже показывается на экране входа.
    final sessionFailure = switch (ref.watch(authControllerProvider)) {
      AuthUnauthenticated(:final failure) => failure,
      _ => null,
    };
    final message = _errorMessage ?? sessionFailure?.message;

    return AuthFormCard(
      title: l10n.authLoginTitle,
      children: [
        if (message != null) AuthMessage(message),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                enabled: !_isSubmitting,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.authUsernameLabel),
                validator: (value) => AuthFieldValidators.username(value, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                enabled: !_isSubmitting,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.authPasswordLabel),
                validator: (value) => AuthFieldValidators.password(value, l10n),
                onFieldSubmitted: (_) => unawaited(_submit()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          label: l10n.authSignInButton,
          isLoading: _isSubmitting,
          onPressed: () => unawaited(_submit()),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => context.goNamed(
                  AppRoutes.registerName,
                  queryParameters: {AppRoutes.fromQueryParam: ?widget.from},
                ),
          child: Text(l10n.authNoAccountLink),
        ),
      ],
    );
  }
}
