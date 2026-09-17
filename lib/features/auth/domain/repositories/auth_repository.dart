import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';

/// Доступ к авторизации и профилю пользователя.
///
/// Реализация живёт в data-слое; ошибки наружу не выбрасываются,
/// вместо исключений возвращается [Result].
abstract interface class AuthRepository {
  /// Поток идентификатора вошедшего пользователя.
  ///
  /// Эмитит `id` при входе и восстановлении сессии и `null` при выходе;
  /// первое значение приходит после проверки сохранённой сессии.
  Stream<String?> watchUserId();

  /// Профиль текущего пользователя.
  FutureResult<UserProfile> currentProfile();

  /// Вход по логину и паролю.
  FutureResult<UserProfile> signIn({
    required String username,
    required String password,
  });

  /// Регистрация по логину и паролю.
  FutureResult<UserProfile> signUp({
    required String username,
    required String password,
  });

  /// Выход из аккаунта.
  FutureResult<void> signOut();

  /// Открыта ли сейчас регистрация.
  FutureResult<bool> isRegistrationOpen();
}
