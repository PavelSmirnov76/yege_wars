/// Роль пользователя (колонка `profiles.role`).
enum UserRole {
  /// Ученик: решает задачи и видит только свой прогресс.
  student('student'),

  /// Администратор: доступна панель управления.
  admin('admin')
  ;

  const UserRole(this.value);

  /// Значение роли в базе данных.
  final String value;

  /// Роль по значению из БД.
  ///
  /// Неизвестное значение трактуется как [student]: клиент не должен
  /// повышать права из-за неожиданных данных (защиту всё равно
  /// обеспечивает RLS).
  static UserRole fromValue(String? value) => UserRole.values.firstWhere(
    (role) => role.value == value,
    orElse: () => UserRole.student,
  );

  /// `true`, если это роль администратора.
  bool get isAdmin => this == UserRole.admin;
}
