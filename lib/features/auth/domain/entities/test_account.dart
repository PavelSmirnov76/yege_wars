import 'package:meta/meta.dart';

/// Тестовая учётная запись (ENT-17): логин и пароль, которые кнопка
/// «Тестовый вход» подставляет в форму входа.
///
/// Реализует UC-38: тестовый вход есть, только когда при сборке заданы оба
/// значения.
@immutable
final class TestAccount {
  /// Создаёт тестовую учётную запись.
  const TestAccount({required this.username, required this.password});

  /// Логин.
  final String username;

  /// Пароль.
  final String password;

  /// Тестовая учётная запись из параметров сборки или `null`, если хотя бы
  /// один из них пуст: тогда тестового входа нет.
  static TestAccount? fromBuild({
    required String username,
    required String password,
  }) => username.isEmpty || password.isEmpty
      ? null
      : TestAccount(username: username, password: password);
}
