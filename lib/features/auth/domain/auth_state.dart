import 'package:meta/meta.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';

/// Состояние авторизации приложения.
sealed class AuthState {
  /// Создаёт состояние.
  const AuthState();

  /// Профиль вошедшего пользователя, иначе `null`.
  UserProfile? get profileOrNull => switch (this) {
    AuthAuthenticated(:final profile) => profile,
    AuthUnknown() || AuthUnauthenticated() => null,
  };

  /// `true`, если пользователь вошёл.
  bool get isAuthenticated => this is AuthAuthenticated;

  /// `true`, если вошедший пользователь — администратор.
  bool get isAdmin => profileOrNull?.isAdmin ?? false;
}

/// Статус ещё не определён: идёт восстановление сессии.
@immutable
final class AuthUnknown extends AuthState {
  /// Создаёт неопределённое состояние.
  const AuthUnknown();

  @override
  bool operator ==(Object other) => other is AuthUnknown;

  @override
  int get hashCode => (AuthUnknown).hashCode;
}

/// Пользователь не авторизован.
@immutable
final class AuthUnauthenticated extends AuthState {
  /// Создаёт состояние «не авторизован».
  ///
  /// [failure] заполняется, когда выход произошёл из-за ошибки
  /// (например, сессия восстановилась, а профиль прочитать не удалось) —
  /// экран входа покажет её текст.
  const AuthUnauthenticated({this.failure});

  /// Ошибка, из-за которой пользователь оказался не авторизован.
  final Failure? failure;

  @override
  bool operator ==(Object other) =>
      other is AuthUnauthenticated && other.failure == failure;

  @override
  int get hashCode => Object.hash(AuthUnauthenticated, failure);
}

/// Пользователь авторизован, профиль загружен.
@immutable
final class AuthAuthenticated extends AuthState {
  /// Создаёт состояние «авторизован» с профилем [profile].
  const AuthAuthenticated(this.profile);

  /// Профиль вошедшего пользователя.
  final UserProfile profile;

  @override
  bool operator ==(Object other) =>
      other is AuthAuthenticated && other.profile == profile;

  @override
  int get hashCode => Object.hash(AuthAuthenticated, profile);
}
