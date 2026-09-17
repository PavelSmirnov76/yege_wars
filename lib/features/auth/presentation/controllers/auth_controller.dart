import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/features/auth/domain/auth_status.dart';

part 'auth_controller.g.dart';

/// Контроллер состояния авторизации.
///
/// ВРЕМЕННАЯ заглушка этапа 1: состояние переключается в памяти
/// без обращения к серверу. Настоящая авторизация через Supabase
/// появится на этапе 3.
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  /// Помечает пользователя вошедшим (заглушка).
  void signIn() => state = AuthStatus.authenticated;

  /// Помечает пользователя вышедшим (заглушка).
  void signOut() => state = AuthStatus.unauthenticated;
}
