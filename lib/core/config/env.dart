/// Конфигурация окружения приложения.
///
/// Значения передаются на этапе сборки через `--dart-define`:
///
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=someKey
/// ```
abstract final class Env {
  /// URL проекта Supabase.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Публичный anon-ключ Supabase.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true`, если заданы оба значения окружения.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
