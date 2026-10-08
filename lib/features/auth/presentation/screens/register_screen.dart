import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/auth/presentation/auth_field_validators.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_message.dart';
import 'package:yege_wars/features/auth/presentation/widgets/auth_submit_button.dart';

/// Экран регистрации по логину и паролю.
///
/// Пока не известно, открыта ли регистрация, форма заблокирована;
/// при закрытой регистрации показывается сообщение.
///
/// Реализует UC-1 и UC-10.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Создаёт экран регистрации с адресом [from], который откроется после
  /// регистрации.
  const RegisterScreen({this.from, super.key});

  /// Адрес, на который шёл посетитель ([AppRoutes.fromQueryParam]):
  /// ссылка на вход передаёт его дальше.
  final String? from;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
        .signUp(
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
    final registration = ref.watch(registrationOpenProvider);
    final isChecking = registration.isLoading;
    final isOpen = registration.value ?? false;
    final isEnabled = isOpen && !_isSubmitting;
    final checkError = registration.error;

    return AuthFormCard(
      title: l10n.authRegisterTitle,
      children: [
        if (_errorMessage != null) AuthMessage(_errorMessage!),
        if (checkError != null)
          AuthMessage(
            checkError is Failure
                ? checkError.message
                : l10n.authRegistrationCheckFailed,
          ),
        if (!isChecking && checkError == null && !isOpen)
          AuthMessage(l10n.authRegistrationClosed, isError: false),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                enabled: isEnabled,
                autofillHints: const [AutofillHints.newUsername],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.authUsernameLabel),
                validator: (value) => AuthFieldValidators.username(value, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                enabled: isEnabled,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
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
          label: l10n.authSignUpButton,
          isLoading: _isSubmitting || isChecking,
          onPressed: isEnabled ? () => unawaited(_submit()) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => context.goNamed(
                  AppRoutes.loginName,
                  queryParameters: {AppRoutes.fromQueryParam: ?widget.from},
                ),
          child: Text(l10n.authHaveAccountLink),
        ),
      ],
    );
  }
}
