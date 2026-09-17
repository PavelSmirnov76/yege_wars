/// Имена таблиц Postgres, к которым обращается клиент.
abstract final class SupabaseTables {
  /// Профили пользователей (1:1 с `auth.users`).
  static const String profiles = 'profiles';
}

/// Колонки таблицы [SupabaseTables.profiles].
abstract final class ProfileColumns {
  /// Идентификатор пользователя.
  static const String id = 'id';

  /// Логин.
  static const String username = 'username';

  /// Роль: `student` или `admin`.
  static const String role = 'role';
}

/// Имена RPC-функций Supabase.
abstract final class SupabaseRpc {
  /// Открыта ли регистрация (доступна и до входа).
  static const String isRegistrationOpen = 'is_registration_open';
}
