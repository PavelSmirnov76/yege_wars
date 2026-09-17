import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/use_cases/get_current_profile_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/is_registration_open_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/watch_auth_user_use_case.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  group('SignInUseCase', () {
    test('не идёт в репозиторий при неверном логине', () async {
      final result = await SignInUseCase(repository)(
        username: 'ab',
        password: 'password1',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.lastUsername, isNull);
    });

    test('не идёт в репозиторий при коротком пароле', () async {
      final result = await SignInUseCase(repository)(
        username: 'pavel',
        password: 'short',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.lastUsername, isNull);
    });

    test('передаёт корректные данные в репозиторий', () async {
      final result = await SignInUseCase(repository)(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.valueOrNull, testStudent);
      expect(repository.lastUsername, 'pavel');
      expect(repository.lastPassword, 'password1');
    });
  });

  group('SignUpUseCase', () {
    test('проверяет ввод до обращения к репозиторию', () async {
      final result = await SignUpUseCase(repository)(
        username: 'павел',
        password: 'password1',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.lastUsername, isNull);
    });

    test('регистрирует при корректных данных', () async {
      final result = await SignUpUseCase(repository)(
        username: 'pavel',
        password: 'password1',
      );

      expect(result.valueOrNull, testStudent);
      expect(repository.lastUsername, 'pavel');
    });
  });

  group('остальные use case делегируют репозиторию', () {
    test('SignOutUseCase', () async {
      expect((await SignOutUseCase(repository)()).isOk, isTrue);
    });

    test('GetCurrentProfileUseCase', () async {
      final result = await GetCurrentProfileUseCase(repository)();

      expect(result.valueOrNull, testStudent);
      expect(repository.currentProfileCalls, 1);
    });

    test('IsRegistrationOpenUseCase', () async {
      repository.registrationOpenResult = const Ok(false);

      expect(
        (await IsRegistrationOpenUseCase(repository)()).valueOrNull,
        isFalse,
      );
    });

    test('WatchAuthUserUseCase', () async {
      final stream = WatchAuthUserUseCase(repository)();
      final emitted = stream.take(2).toList();
      repository
        ..emitUserId('user-id')
        ..emitUserId(null);

      expect(await emitted, ['user-id', null]);
    });
  });
}
