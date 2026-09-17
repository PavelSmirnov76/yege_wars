import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/config/env.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';

/// Подготовка зависимостей до запуска интерфейса.
///
/// Вынесена из `main`, чтобы тесты могли собирать приложение без
/// Supabase — им достаточно подменить провайдеры.
Future<Result<void>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
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
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
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
