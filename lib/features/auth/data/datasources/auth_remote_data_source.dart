/// Низкоуровневый доступ к Supabase Auth и таблице `profiles`.
///
/// Методы бросают исключения SDK как есть; переводит их в `Failure`
/// репозиторий, чтобы маппинг ошибок был в одном месте.
abstract interface class AuthRemoteDataSource {
  /// Поток `id` вошедшего пользователя (`null` — сессии нет).
  Stream<String?> watchUserId();

  /// `id` пользователя текущей сессии или `null`.
  String? get currentUserId;

  /// Читает строку профиля по [userId]; `null`, если строки нет.
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// Вход по логину и паролю; возвращает `id` пользователя.
  Future<String?> signIn({
    required String username,
    required String password,
  });

  /// Регистрация по логину и паролю; возвращает `id` пользователя.
  Future<String?> signUp({
    required String username,
    required String password,
  });

  /// Выход из аккаунта.
  Future<void> signOut();

  /// Открыта ли регистрация (RPC доступна и до входа).
  Future<bool> isRegistrationOpen();
}
