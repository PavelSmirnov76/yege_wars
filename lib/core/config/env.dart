/// Конфигурация окружения приложения.
///
/// Адрес проекта Supabase и его публичный ключ приходят только из
/// параметров сборки `--dart-define`; значений по умолчанию в коде нет.
/// Локально их берут из `supabase/.env.local`, который в git не попадает, —
/// команда запуска в README, раздел «Локальный запуск».
///
/// Без них [isConfigured] — `false`, и приложение показывает экран
/// «Приложение не сконфигурировано». Секретный ключ проекта (`sb_secret_…`)
/// во фронтенд не передаётся никогда.
abstract final class Env {
  /// URL проекта Supabase; пустой, если не передан при сборке.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Публичный ключ Supabase (anon или publishable); пустой, если не
  /// передан при сборке.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true`, если заданы оба значения окружения.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Логин тестовой учётной записи; пустой, если не передан при сборке.
  ///
  /// Необязателен: без него и [testLoginPassword] кнопки «Тестовый вход»
  /// нет.
  static const String testLoginUsername = String.fromEnvironment(
    'TEST_LOGIN_USERNAME',
  );

  /// Пароль тестовой учётной записи; пустой, если не передан при сборке.
  static const String testLoginPassword = String.fromEnvironment(
    'TEST_LOGIN_PASSWORD',
  );

  /// Начало адреса публичного файла в Supabase Storage.
  ///
  /// К нему дописывается путь вида `task-assets/fipi/images/…`: именно так
  /// вложения записаны в условиях задач, чтобы разметка не зависела
  /// от конкретного проекта Supabase.
  static String get storagePublicBase =>
      '$supabaseUrl/storage/v1/object/public/';
}
