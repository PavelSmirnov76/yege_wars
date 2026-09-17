/// Правила учётных данных, общие для UI, domain-слоя и базы данных.
///
/// Те же ограничения продублированы в триггере `handle_new_user`
/// и в Supabase Auth: клиент проверяет их заранее, чтобы не гонять
/// заведомо неверный ввод по сети.
abstract final class AuthRules {
  /// Минимальная длина логина.
  static const int usernameMinLength = 3;

  /// Максимальная длина логина.
  static const int usernameMaxLength = 20;

  /// Минимальная длина пароля.
  static const int passwordMinLength = 8;

  /// Допустимый логин: латиница, цифры и подчёркивание.
  static final RegExp usernamePattern = RegExp(
    '^[A-Za-z0-9_]{$usernameMinLength,$usernameMaxLength}\$',
  );

  /// Проверяет логин.
  static bool isValidUsername(String username) =>
      usernamePattern.hasMatch(username);

  /// Проверяет пароль.
  static bool isValidPassword(String password) =>
      password.length >= passwordMinLength;
}
