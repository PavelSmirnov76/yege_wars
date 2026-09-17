import 'package:meta/meta.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';

/// Профиль пользователя из таблицы `profiles`.
@immutable
final class UserProfile {
  /// Создаёт профиль.
  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
  });

  /// Идентификатор пользователя (совпадает с `auth.users.id`).
  final String id;

  /// Логин пользователя.
  final String username;

  /// Роль пользователя.
  final UserRole role;

  /// `true`, если пользователь — администратор.
  bool get isAdmin => role.isAdmin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.id == id &&
          other.username == username &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, username, role);

  @override
  String toString() =>
      'UserProfile(id: $id, username: $username, '
      'role: ${role.value})';
}
