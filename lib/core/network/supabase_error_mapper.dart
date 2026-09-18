import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/rpc_error.dart';

/// Перевод исключений Supabase в [Failure] с русским сообщением.
///
/// Общая часть для всех фич: сеть, ошибки PostgREST и сообщения функций
/// базы формата `[код] Русский текст`. Специфику авторизации добавляет
/// `AuthErrorMapper` поверх этого разбора.
abstract final class SupabaseErrorMapper {
  /// Просроченный или недействительный JWT (PostgREST).
  static const String codeJwtExpired = 'PGRST301';

  /// Текст об истёкшей сессии — общий для всех фич.
  static const String sessionExpiredMessage = 'Сессия истекла. Войдите заново.';

  /// Переводит [error] в [Failure].
  static Failure map(Object error) {
    // Ошибки функций и триггеров базы: `[код] Русский текст`.
    final rpcError = RpcError.tryParse(messageOf(error));
    if (rpcError != null) {
      return fromRpcError(rpcError, error);
    }

    return switch (error) {
      AuthRetryableFetchException() => NetworkFailure(cause: error),
      http.ClientException() => NetworkFailure(cause: error),
      AuthSessionMissingException() => AuthFailure(
        message: sessionExpiredMessage,
        cause: error,
      ),
      PostgrestException(code: codeJwtExpired) => AuthFailure(
        message: sessionExpiredMessage,
        cause: error,
      ),
      PostgrestException() => DatabaseFailure(cause: error),
      FormatException() => DatabaseFailure(
        message: 'Сервер вернул неожиданные данные.',
        cause: error,
      ),
      _ => UnexpectedFailure(cause: error),
    };
  }

  /// Текст исключения, в котором может прятаться формат `[код] Текст`.
  static String? messageOf(Object error) => switch (error) {
    AuthException(:final message) => message,
    PostgrestException(:final message) => message,
    _ => null,
  };

  /// Ошибка функции или триггера базы.
  static Failure fromRpcError(RpcError rpcError, Object cause) =>
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
        RpcErrorCodes.forbidden => AuthFailure(
          message: rpcError.message,
          cause: cause,
        ),
        // Текст базы уже на русском и готов к показу.
        _ => DatabaseFailure(message: rpcError.message, cause: cause),
      };
}
