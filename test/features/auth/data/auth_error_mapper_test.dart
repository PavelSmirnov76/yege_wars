import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/auth/data/mappers/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper: ошибки базы данных', () {
    test('текст «[код] Текст» из RPC показывается пользователю', () {
      final failure = AuthErrorMapper.map(
        const PostgrestException(
          message: '[registration_closed] Регистрация закрыта администратором.',
        ),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Регистрация закрыта администратором.');
    });

    test('ошибка занятого логина — ошибка валидации', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException('[username_taken] Логин «pavel» уже занят.'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Логин «pavel» уже занят.');
    });

    test('неизвестный код БД сохраняет русский текст', () {
      final failure = AuthErrorMapper.map(
        const PostgrestException(message: '[not_owner] Чужое решение.'),
      );

      expect(failure, isA<DatabaseFailure>());
      expect(failure.message, 'Чужое решение.');
    });
  });

  group('AuthErrorMapper: ошибки Supabase Auth', () {
    test('неверные учётные данные', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Неверный логин или пароль.');
    });

    test('занятая почта — ошибка валидации', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException('exists', code: 'user_already_exists'),
        operation: AuthOperation.signUp,
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Логин уже занят, выберите другой.');
    });

    test('слабый пароль', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException('weak', code: 'weak_password'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('8 символов'));
    });

    test('лимит запросов', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException('rate', code: 'over_request_rate_limit'),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Слишком много попыток'));
    });

    test('ошибка триггера при регистрации объясняет причины', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException(
          'Database error saving new user',
          code: 'unexpected_failure',
          statusCode: '500',
        ),
        operation: AuthOperation.signUp,
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('логин уже занят'));
    });

    test('та же ошибка при входе остаётся непредвиденной', () {
      final failure = AuthErrorMapper.map(
        const AuthApiException('boom', code: 'unexpected_failure'),
        operation: AuthOperation.signIn,
      );

      expect(failure, isA<UnexpectedFailure>());
    });

    test('потерянная сессия', () {
      final failure = AuthErrorMapper.map(AuthSessionMissingException());

      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Сессия истекла'));
    });
  });

  group('AuthErrorMapper: сеть и прочее', () {
    test('обрыв запроса Supabase Auth — сетевая ошибка', () {
      expect(
        AuthErrorMapper.map(AuthRetryableFetchException()),
        isA<NetworkFailure>(),
      );
    });

    test('обрыв запроса PostgREST — сетевая ошибка', () {
      expect(
        AuthErrorMapper.map(http.ClientException('Failed to fetch')),
        isA<NetworkFailure>(),
      );
    });

    test('просроченный токен — ошибка авторизации', () {
      final failure = AuthErrorMapper.map(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      );

      expect(failure, isA<AuthFailure>());
    });

    test('неожиданные данные профиля — ошибка базы данных', () {
      expect(
        AuthErrorMapper.map(const FormatException('bad row')),
        isA<DatabaseFailure>(),
      );
    });

    test('любое другое исключение — непредвиденная ошибка', () {
      final failure = AuthErrorMapper.map(StateError('boom'));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.cause, isA<StateError>());
    });
  });
}
