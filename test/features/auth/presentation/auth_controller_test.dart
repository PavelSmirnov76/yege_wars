import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/auth/domain/auth_state.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  /// Читает состояние, инициализируя контроллер и его подписку.
  AuthState readState() => container.read(authControllerProvider);

  group('подписка на сессию', () {
    test('до первого события статус неизвестен', () {
      expect(readState(), isA<AuthUnknown>());
    });

    test('пустая сессия — пользователь не авторизован', () async {
      readState();
      repository.emitUserId(null);
      await pumpEventQueue();

      expect(readState(), isA<AuthUnauthenticated>());
      expect(repository.currentProfileCalls, 0);
    });

    test('UC-10-P-05: восстановленная сессия загружает профиль', () async {
      readState();
      repository.emitUserId(testStudent.id);
      await pumpEventQueue();

      expect(readState(), const AuthAuthenticated(testStudent));
      expect(repository.currentProfileCalls, 1);
    });

    test(
      'повторное событие того же пользователя не грузит профиль заново',
      () async {
        readState();
        repository.emitUserId(testStudent.id);
        await pumpEventQueue();
        repository.emitUserId(testStudent.id);
        await pumpEventQueue();

        expect(repository.currentProfileCalls, 1);
      },
    );

    test('UC-10-P-06: ошибка чтения профиля оставляет '
        'пользователя снаружи', () async {
      repository.currentProfileResult = const Err(
        DatabaseFailure(message: 'Профиль пользователя не найден.'),
      );
      readState();
      repository.emitUserId(testStudent.id);
      await pumpEventQueue();

      final state = readState();
      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).failure?.message,
        'Профиль пользователя не найден.',
      );
    });

    test('UC-11-P-03: выход из аккаунта в другой вкладке '
        'сбрасывает состояние', () async {
      readState();
      repository.emitUserId(testStudent.id);
      await pumpEventQueue();
      repository.emitUserId(null);
      await pumpEventQueue();

      expect(readState(), isA<AuthUnauthenticated>());
    });
  });

  group('действия пользователя', () {
    test('успешный вход переводит в authenticated', () async {
      readState();
      final result = await container
          .read(authControllerProvider.notifier)
          .signIn(username: 'student', password: 'password1');

      expect(result.valueOrNull, testStudent);
      expect(readState(), const AuthAuthenticated(testStudent));
    });

    test('UC-10-P-02: неуспешный вход не меняет состояние', () async {
      repository.signInResult = const Err(
        AuthFailure(message: 'Неверный логин или пароль.'),
      );
      readState();
      repository.emitUserId(null);
      await pumpEventQueue();

      final result = await container
          .read(authControllerProvider.notifier)
          .signIn(username: 'student', password: 'wrongpassword');

      expect(result.failureOrNull?.message, 'Неверный логин или пароль.');
      expect(readState(), isA<AuthUnauthenticated>());
    });

    test('успешная регистрация переводит в authenticated', () async {
      readState();
      final result = await container
          .read(authControllerProvider.notifier)
          .signUp(username: 'student', password: 'password1');

      expect(result.valueOrNull, testStudent);
      expect(readState(), const AuthAuthenticated(testStudent));
    });

    test('UC-11-P-01: выход возвращает в unauthenticated', () async {
      readState();
      repository.emitUserId(testStudent.id);
      await pumpEventQueue();

      final result = await container
          .read(authControllerProvider.notifier)
          .signOut();

      expect(result.isOk, isTrue);
      expect(readState(), isA<AuthUnauthenticated>());
    });

    test('UC-11-P-02: ошибка выхода сохраняет вход', () async {
      repository.signOutResult = const Err<void>(
        NetworkFailure(),
      );
      readState();
      repository.emitUserId(testStudent.id);
      await pumpEventQueue();

      final result = await container
          .read(authControllerProvider.notifier)
          .signOut();

      expect(result.isErr, isTrue);
      expect(readState(), const AuthAuthenticated(testStudent));
    });
  });
}
