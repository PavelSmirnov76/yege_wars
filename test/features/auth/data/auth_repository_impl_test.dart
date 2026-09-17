import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:yege_wars/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

/// Строка профиля, какой её отдаёт Supabase.
const Map<String, dynamic> _profileRow = {
  'id': 'user-id',
  'username': 'pavel',
  'role': 'student',
};

void main() {
  late _MockAuthRemoteDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  group('signIn', () {
    test('возвращает профиль после успешного входа', () async {
      when(
        () => dataSource.signIn(username: 'pavel', password: 'password1'),
      ).thenAnswer((_) async => 'user-id');
      when(
        () => dataSource.fetchProfile('user-id'),
      ).thenAnswer((_) async => _profileRow);

      final result = await repository.signIn(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.valueOrNull?.username, 'pavel');
      expect(result.valueOrNull?.role, UserRole.student);
    });

    test('неверные учётные данные превращаются в AuthFailure', () async {
      when(
        () => dataSource.signIn(username: 'pavel', password: 'password1'),
      ).thenThrow(
        const AuthApiException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );

      final result = await repository.signIn(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.message, 'Неверный логин или пароль.');
    });

    test('вход без пользователя в ответе — ошибка', () async {
      when(
        () => dataSource.signIn(username: 'pavel', password: 'password1'),
      ).thenAnswer((_) async => null);

      final result = await repository.signIn(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      verifyNever(() => dataSource.fetchProfile(any()));
    });

    test('отсутствие строки профиля — ошибка базы данных', () async {
      when(
        () => dataSource.signIn(username: 'pavel', password: 'password1'),
      ).thenAnswer((_) async => 'user-id');
      when(
        () => dataSource.fetchProfile('user-id'),
      ).thenAnswer((_) async => null);

      final result = await repository.signIn(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.failureOrNull, isA<DatabaseFailure>());
      expect(result.failureOrNull?.message, contains('Профиль'));
    });
  });

  group('signUp', () {
    test('возвращает профиль, созданный триггером', () async {
      when(
        () => dataSource.signUp(username: 'pavel', password: 'password1'),
      ).thenAnswer((_) async => 'user-id');
      when(
        () => dataSource.fetchProfile('user-id'),
      ).thenAnswer((_) async => _profileRow);

      final result = await repository.signUp(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.valueOrNull?.username, 'pavel');
    });

    test('ошибка триггера объясняет причины', () async {
      when(
        () => dataSource.signUp(username: 'pavel', password: 'password1'),
      ).thenThrow(
        const AuthApiException(
          'Database error saving new user',
          code: 'unexpected_failure',
        ),
      );

      final result = await repository.signUp(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.failureOrNull?.message, contains('логин уже занят'));
    });

    test('сообщение триггера «[код] Текст» доходит как есть', () async {
      when(
        () => dataSource.signUp(username: 'pavel', password: 'password1'),
      ).thenThrow(
        const AuthApiException(
          '[registration_closed] Регистрация закрыта администратором.',
        ),
      );

      final result = await repository.signUp(
        username: 'pavel',
        password: 'password1',
      );

      expect(
        result.failureOrNull?.message,
        'Регистрация закрыта администратором.',
      );
    });
  });

  group('currentProfile', () {
    test('без сессии возвращает ошибку авторизации', () async {
      when(() => dataSource.currentUserId).thenReturn(null);

      final result = await repository.currentProfile();

      expect(result.failureOrNull, isA<AuthFailure>());
      verifyNever(() => dataSource.fetchProfile(any()));
    });

    test('с сессией читает профиль', () async {
      when(() => dataSource.currentUserId).thenReturn('user-id');
      when(
        () => dataSource.fetchProfile('user-id'),
      ).thenAnswer((_) async => _profileRow);

      final result = await repository.currentProfile();

      expect(result.valueOrNull?.id, 'user-id');
    });

    test('битая строка профиля — ошибка базы данных', () async {
      when(() => dataSource.currentUserId).thenReturn('user-id');
      when(
        () => dataSource.fetchProfile('user-id'),
      ).thenAnswer((_) async => const {'id': 'user-id'});

      final result = await repository.currentProfile();

      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });

  group('signOut и isRegistrationOpen', () {
    test('успешный выход', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      expect((await repository.signOut()).isOk, isTrue);
    });

    test('ошибка выхода превращается в Failure', () async {
      when(() => dataSource.signOut()).thenThrow(StateError('boom'));

      expect(
        (await repository.signOut()).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    });

    test('состояние регистрации', () async {
      when(
        () => dataSource.isRegistrationOpen(),
      ).thenAnswer((_) async => false);

      expect((await repository.isRegistrationOpen()).valueOrNull, isFalse);
    });

    test('ошибка RPC состояния регистрации', () async {
      when(() => dataSource.isRegistrationOpen()).thenThrow(
        const PostgrestException(message: 'boom', code: '42501'),
      );

      expect(
        (await repository.isRegistrationOpen()).failureOrNull,
        isA<DatabaseFailure>(),
      );
    });
  });

  test('поток сессии проксируется из datasource', () {
    when(() => dataSource.watchUserId()).thenAnswer(
      (_) => Stream<String?>.fromIterable(['user-id', null]),
    );

    expect(
      repository.watchUserId(),
      emitsInOrder(['user-id', null, emitsDone]),
    );
  });
}
