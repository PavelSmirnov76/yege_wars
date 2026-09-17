import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Профиль ученика для тестов.
const UserProfile testStudent = UserProfile(
  id: 'student-id',
  username: 'student',
  role: UserRole.student,
);

/// Профиль администратора для тестов.
const UserProfile testAdmin = UserProfile(
  id: 'admin-id',
  username: 'admin',
  role: UserRole.admin,
);

/// Репозиторий авторизации для тестов: результаты задаются полями,
/// поток сессии управляется вручную через [emitUserId].
final class FakeAuthRepository implements AuthRepository {
  final StreamController<String?> _userIds =
      StreamController<String?>.broadcast();

  /// Результат [signIn].
  Result<UserProfile> signInResult = const Ok(testStudent);

  /// Результат [signUp].
  Result<UserProfile> signUpResult = const Ok(testStudent);

  /// Результат [currentProfile].
  Result<UserProfile> currentProfileResult = const Ok(testStudent);

  /// Результат [signOut].
  Result<void> signOutResult = const Ok<void>(null);

  /// Результат [isRegistrationOpen].
  Result<bool> registrationOpenResult = const Ok(true);

  /// Пока не завершён, ответы входа и регистрации не приходят:
  /// так тест проверяет индикатор загрузки.
  Completer<void>? gate;

  /// Логин последнего вызова [signIn] или [signUp].
  String? lastUsername;

  /// Пароль последнего вызова [signIn] или [signUp].
  String? lastPassword;

  /// Сколько раз запрашивался профиль.
  int currentProfileCalls = 0;

  /// Эмитит идентификатор пользователя (`null` — выход).
  void emitUserId(String? userId) => _userIds.add(userId);

  /// Закрывает поток сессии.
  Future<void> dispose() => _userIds.close();

  @override
  Stream<String?> watchUserId() => _userIds.stream;

  @override
  FutureResult<UserProfile> currentProfile() async {
    currentProfileCalls++;
    return currentProfileResult;
  }

  @override
  FutureResult<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    lastUsername = username;
    lastPassword = password;
    await gate?.future;
    return signInResult;
  }

  @override
  FutureResult<UserProfile> signUp({
    required String username,
    required String password,
  }) async {
    lastUsername = username;
    lastPassword = password;
    await gate?.future;
    return signUpResult;
  }

  @override
  FutureResult<void> signOut() async => signOutResult;

  @override
  FutureResult<bool> isRegistrationOpen() async => registrationOpenResult;
}
