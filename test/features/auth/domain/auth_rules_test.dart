import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/auth/domain/auth_rules.dart';
import 'package:yege_wars/features/auth/domain/credentials_validation.dart';

void main() {
  group('AuthRules.isValidUsername', () {
    test('принимает латиницу, цифры и подчёркивание', () {
      expect(AuthRules.isValidUsername('pavel_76'), isTrue);
      expect(AuthRules.isValidUsername('abc'), isTrue);
      expect(AuthRules.isValidUsername('a' * 20), isTrue);
    });

    test('отклоняет короткий, длинный и недопустимый логин', () {
      expect(AuthRules.isValidUsername('ab'), isFalse);
      expect(AuthRules.isValidUsername('a' * 21), isFalse);
      expect(AuthRules.isValidUsername('павел'), isFalse);
      expect(AuthRules.isValidUsername('pavel 76'), isFalse);
      expect(AuthRules.isValidUsername('pavel-76'), isFalse);
      expect(AuthRules.isValidUsername(''), isFalse);
    });
  });

  group('AuthRules.isValidPassword', () {
    test('принимает пароль от 8 символов', () {
      expect(AuthRules.isValidPassword('12345678'), isTrue);
    });

    test('отклоняет короткий пароль', () {
      expect(AuthRules.isValidPassword('1234567'), isFalse);
    });
  });

  group('CredentialsValidation', () {
    test('сначала сообщает об ошибке логина', () {
      final failure = CredentialsValidation.validate(
        username: 'ab',
        password: 'short',
      );

      expect(failure?.message, contains('Логин'));
    });

    test('сообщает об ошибке пароля при верном логине', () {
      final failure = CredentialsValidation.validate(
        username: 'pavel',
        password: 'short',
      );

      expect(failure?.message, contains('Пароль'));
    });

    test('ничего не возвращает для корректных данных', () {
      expect(
        CredentialsValidation.validate(
          username: 'pavel',
          password: 'password1',
        ),
        isNull,
      );
    });
  });
}
