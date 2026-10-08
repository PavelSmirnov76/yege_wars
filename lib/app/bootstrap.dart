import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/config/env.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';

/// Подготовка зависимостей до запуска интерфейса.
///
/// Реализует запуск приложения (UC-12): без адреса или ключа возвращает
/// [ValidationFailure], если Supabase не поднялся — [NetworkFailure]; с
/// любой из них `main` показывает `NotConfiguredApp`.
///
/// Вынесена из `main`, чтобы тесты могли собирать приложение без
/// Supabase — им достаточно подменить провайдеры. Параметры [url] и
/// [anonKey] нужны тестам: по умолчанию берутся значения [Env].
Future<Result<void>> bootstrap({
  String url = Env.supabaseUrl,
  String anonKey = Env.supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (url.isEmpty || anonKey.isEmpty) {
    return const Err<void>(
      ValidationFailure(
        message:
            'Не заданы SUPABASE_URL и SUPABASE_ANON_KEY. '
            'Соберите приложение с параметрами --dart-define.',
      ),
    );
  }

  try {
    // anonKey в supabase_flutter объявлен устаревшим: тот же публичный
    // ключ передаётся как publishableKey.
    await Supabase.initialize(url: url, publishableKey: anonKey);
    return const Ok<void>(null);
  } on Object catch (error) {
    return Err<void>(
      NetworkFailure(
        message:
            'Не удалось подключиться к Supabase. '
            'Проверьте SUPABASE_URL и SUPABASE_ANON_KEY.',
        cause: error,
      ),
    );
  }
}
