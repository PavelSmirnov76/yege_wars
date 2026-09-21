/// Конфигурация окружения приложения.
///
/// Значения по умолчанию — боевой проект Supabase. Адрес и публичный ключ
/// не являются секретом: ключ рассчитан на публикацию во фронтенде, доступ
/// к данным ограничивает RLS. Секретный ключ проекта (`sb_secret_…`)
/// в репозитории отсутствовать обязан.
///
/// Любое значение можно переопределить при сборке:
///
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_…
/// ```
abstract final class Env {
  /// Адрес проекта Supabase по умолчанию.
  static const String _defaultSupabaseUrl =
      'https://hzbfdupqouteerbrrikm.supabase.co';

  /// Публичный ключ проекта по умолчанию.
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_QWf8q8iT75oEoGoiqAxDQA_DeUDO_Zl';

  /// URL проекта Supabase.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );

  /// Публичный ключ Supabase (anon или publishable).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseAnonKey,
  );

  /// `true`, если заданы оба значения окружения.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Начало адреса публичного файла в Supabase Storage.
  ///
  /// К нему дописывается путь вида `task-assets/fipi/images/…`: именно так
  /// вложения записаны в условиях задач, чтобы разметка не зависела
  /// от конкретного проекта Supabase.
  static String get storagePublicBase =>
      '$supabaseUrl/storage/v1/object/public/';
}
