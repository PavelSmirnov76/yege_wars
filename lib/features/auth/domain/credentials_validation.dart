import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/auth/domain/auth_rules.dart';

/// Проверка учётных данных до обращения к серверу.
///
/// Тексты ошибок здесь — запасной вариант (например, при вызове use case
/// в обход формы); в формах сообщения берутся из l10n.
abstract final class CredentialsValidation {
  /// Ошибка логина или `null`, если логин допустим.
  static ValidationFailure? validateUsername(String username) =>
      AuthRules.isValidUsername(username)
      ? null
      : const ValidationFailure(
          message:
              'Логин: от ${AuthRules.usernameMinLength} до '
              '${AuthRules.usernameMaxLength} символов — латинские буквы, '
              'цифры и подчёркивание.',
        );

  /// Ошибка пароля или `null`, если пароль допустим.
  static ValidationFailure? validatePassword(String password) =>
      AuthRules.isValidPassword(password)
      ? null
      : const ValidationFailure(
          message:
              'Пароль должен содержать не менее '
              '${AuthRules.passwordMinLength} символов.',
        );

  /// Первая ошибка пары «логин и пароль» или `null`.
  static ValidationFailure? validate({
    required String username,
    required String password,
  }) => validateUsername(username) ?? validatePassword(password);
}
