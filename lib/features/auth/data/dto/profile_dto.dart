import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';

/// Строка таблицы `profiles` в том виде, в каком её отдаёт Supabase.
final class ProfileDto {
  /// Создаёт DTO.
  const ProfileDto({
    required this.id,
    required this.username,
    required this.role,
  });

  /// Разбирает ответ Supabase.
  ///
  /// Бросает [FormatException], если обязательные поля отсутствуют или
  /// имеют неожиданный тип: это ошибка контракта с БД, а не пользователя.
  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final id = json[ProfileColumns.id];
    final username = json[ProfileColumns.username];
    if (id is! String || username is! String) {
      throw FormatException('Некорректная строка профиля', json);
    }
    return ProfileDto(
      id: id,
      username: username,
      role: json[ProfileColumns.role] as String?,
    );
  }

  /// Идентификатор пользователя.
  final String id;

  /// Логин.
  final String username;

  /// Роль в виде строки из БД (может быть неизвестной клиенту).
  final String? role;

  /// Преобразует DTO в сущность domain-слоя.
  UserProfile toDomain() => UserProfile(
    id: id,
    username: username,
    role: UserRole.fromValue(role),
  );
}
