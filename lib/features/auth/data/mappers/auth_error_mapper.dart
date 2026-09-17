import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/rpc_error.dart';
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

  /// Просроченный или недействительный JWT (PostgREST).
  static const String _codeJwtExpired = 'PGRST301';

  /// Переводит [error] в [Failure]; [operation] уточняет формулировку.
  static Failure map(
    Object error, {
    AuthOperation operation = AuthOperation.other,
  }) {
    // Ошибки функций и триггеров БД: `[код] Русский текст`.
    final rpcError = RpcError.tryParse(_messageOf(error));
    if (rpcError != null) {
      return _fromRpcError(rpcError, error);
    }

    return switch (error) {
      AuthRetryableFetchException() => NetworkFailure(cause: error),
      http.ClientException() => NetworkFailure(cause: error),
      AuthSessionMissingException() => AuthFailure(
        message: 'Сессия истекла. Войдите заново.',
        cause: error,
      ),
      AuthException() => _fromAuthException(error, operation),
      PostgrestException(code: _codeJwtExpired) => AuthFailure(
        message: 'Сессия истекла. Войдите заново.',
        cause: error,
      ),
      PostgrestException() => DatabaseFailure(cause: error),
      FormatException() => DatabaseFailure(
        message: 'Сервер вернул неожиданные данные профиля.',
        cause: error,
      ),
      _ => UnexpectedFailure(cause: error),
    };
  }

  /// Текст исключения, в котором может прятаться формат `[код] Текст`.
  static String? _messageOf(Object error) => switch (error) {
    AuthException(:final message) => message,
    PostgrestException(:final message) => message,
    _ => null,
  };

  /// Ошибка функции или триггера БД.
  static Failure _fromRpcError(RpcError rpcError, Object cause) =>
      switch (rpcError.code) {
        RpcErrorCodes.registrationClosed => AuthFailure(
          message: rpcError.message,
          cause: cause,
        ),
        RpcErrorCodes.invalidUsername ||
        RpcErrorCodes.usernameTaken => ValidationFailure(
          message: rpcError.message,
          cause: cause,
        ),
        // Текст БД уже на русском и готов к показу.
        _ => DatabaseFailure(message: rpcError.message, cause: cause),
      };

  /// Ошибка Supabase Auth по коду ответа.
  static Failure _fromAuthException(
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
    _ => UnexpectedFailure(cause: error),
  };
}
