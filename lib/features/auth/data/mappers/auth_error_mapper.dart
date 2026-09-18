import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/rpc_error.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/features/auth/domain/auth_rules.dart';

/// Операция, в которой возникла ошибка.
///
/// Нужна там, где сервер отвечает одинаково на разные ситуации:
/// например, любая ошибка триггера при регистрации приходит как
/// `unexpected_failure` без исходного текста.
enum AuthOperation {
  /// Вход.
  signIn,

  /// Регистрация.
  signUp,

  /// Прочие обращения (профиль, выход, настройки).
  other,
}

/// Перевод исключений Supabase в [Failure] с русским сообщением.
abstract final class AuthErrorMapper {
  /// Неверные учётные данные (GoTrue).
  static const String _codeInvalidCredentials = 'invalid_credentials';

  /// Пользователь с такой почтой уже есть.
  static const String _codeUserAlreadyExists = 'user_already_exists';

  /// Слишком короткий или простой пароль.
  static const String _codeWeakPassword = 'weak_password';

  /// Превышен лимит запросов.
  static const String _codeOverRequestRateLimit = 'over_request_rate_limit';

  /// Регистрация отключена на стороне Supabase.
  static const String _codeSignupDisabled = 'signup_disabled';

  /// Внутренняя ошибка сервера: сюда же попадают ошибки триггеров БД.
  static const String _codeUnexpectedFailure = 'unexpected_failure';

  /// Переводит [error] в [Failure]; [operation] уточняет формулировку.
  static Failure map(
    Object error, {
    AuthOperation operation = AuthOperation.other,
  }) {
    // Ошибки функций и триггеров базы: `[код] Русский текст`.
    final rpcError = RpcError.tryParse(SupabaseErrorMapper.messageOf(error));
    if (rpcError != null) {
      return SupabaseErrorMapper.fromRpcError(rpcError, error);
    }
    // Сессия и сеть разбираются общим маппером, коды GoTrue — здесь.
    if (error is AuthException && error is! AuthSessionMissingException) {
      final failure = _fromAuthException(error, operation);
      if (failure != null) {
        return failure;
      }
    }
    return SupabaseErrorMapper.map(error);
  }

  /// Ошибка Supabase Auth по коду ответа; `null` — код неизвестен,
  /// разбирается общим маппером.
  static Failure? _fromAuthException(
    AuthException error,
    AuthOperation operation,
  ) => switch (error.code) {
    _codeInvalidCredentials => AuthFailure(
      message: 'Неверный логин или пароль.',
      cause: error,
    ),
    _codeUserAlreadyExists => ValidationFailure(
      message: 'Логин уже занят, выберите другой.',
      cause: error,
    ),
    _codeWeakPassword => ValidationFailure(
      message:
          'Пароль должен содержать не менее '
          '${AuthRules.passwordMinLength} символов.',
      cause: error,
    ),
    _codeOverRequestRateLimit => AuthFailure(
      message: 'Слишком много попыток. Подождите минуту и повторите.',
      cause: error,
    ),
    _codeSignupDisabled => AuthFailure(
      message: 'Регистрация закрыта администратором.',
      cause: error,
    ),
    // Ошибку триггера БД Supabase Auth отдаёт как внутреннюю ошибку
    // сервера без исходного текста, поэтому перечисляем причины.
    _codeUnexpectedFailure when operation == AuthOperation.signUp =>
      AuthFailure(
        message:
            'Не удалось зарегистрироваться. Возможно, логин уже занят '
            'или регистрация закрыта.',
        cause: error,
      ),
    _ => null,
  };
}
