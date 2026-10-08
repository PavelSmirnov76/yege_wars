import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/auth_providers.dart';
import 'package:yege_wars/features/auth/domain/auth_state.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';

part 'auth_controller.g.dart';

/// Состояние авторизации приложения.
///
/// Подписывается на сессию Supabase: при входе и восстановлении сессии
/// догружает профиль из `profiles`, при выходе сбрасывает состояние.
/// Живёт всё время работы приложения ([Riverpod.keepAlive]), иначе при
/// смене экранов сессия каждый раз определялась бы заново.
///
/// Реализует UC-1, UC-10 и UC-11.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final subscription = ref
        .watch(watchAuthUserUseCaseProvider)()
        .listen(_onUserIdChanged);
    ref.onDispose(subscription.cancel);
    return const AuthUnknown();
  }

  /// Вход по логину и паролю.
  Future<Result<UserProfile>> signIn({
    required String username,
    required String password,
  }) async {
    final result = await ref.read(signInUseCaseProvider)(
      username: username,
      password: password,
    );
    _applyProfile(result);
    return result;
  }

  /// Регистрация по логину и паролю.
  Future<Result<UserProfile>> signUp({
    required String username,
    required String password,
  }) async {
    final result = await ref.read(signUpUseCaseProvider)(
      username: username,
      password: password,
    );
    _applyProfile(result);
    return result;
  }

  /// Выход из аккаунта.
  Future<Result<void>> signOut() async {
    final result = await ref.read(signOutUseCaseProvider)();
    if (ref.mounted && result.isOk) {
      state = const AuthUnauthenticated();
    }
    return result;
  }

  /// Реакция на изменение сессии: `null` — выход, иначе загрузка профиля.
  Future<void> _onUserIdChanged(String? userId) async {
    if (userId == null) {
      state = const AuthUnauthenticated();
      return;
    }
    // Профиль этого пользователя уже загружен (например, сразу после
    // входа) — повторный запрос не нужен.
    if (state case AuthAuthenticated(
      :final profile,
    ) when profile.id == userId) {
      return;
    }
    final result = await ref.read(getCurrentProfileUseCaseProvider)();
    if (!ref.mounted) {
      return;
    }
    state = result.fold(
      onOk: AuthAuthenticated.new,
      onErr: (failure) => AuthUnauthenticated(failure: failure),
    );
  }

  /// Переводит состояние в «авторизован», если операция удалась.
  void _applyProfile(Result<UserProfile> result) {
    if (!ref.mounted) {
      return;
    }
    if (result case Ok(:final value)) {
      state = AuthAuthenticated(value);
    }
  }
}
