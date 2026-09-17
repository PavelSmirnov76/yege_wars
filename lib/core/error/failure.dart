/// Базовая иерархия ошибок приложения.
///
/// Каждая ошибка несёт готовое русское сообщение для показа в UI
/// и необязательную исходную причину ([Failure.cause]) для логирования.
sealed class Failure {
  /// Создаёт ошибку с сообщением [message] и причиной [cause].
  const Failure({required this.message, this.cause});

  /// Готовое русское сообщение для показа пользователю.
  final String message;

  /// Исходная причина ошибки (исключение, ответ сервера и т. п.).
  final Object? cause;
}

/// Ошибка сети: нет соединения, таймаут, недоступный сервер.
final class NetworkFailure extends Failure {
  /// Создаёт сетевую ошибку.
  const NetworkFailure({
    super.message = 'Нет соединения с сервером. Проверьте интернет.',
    super.cause,
  });
}

/// Ошибка аутентификации или авторизации.
final class AuthFailure extends Failure {
  /// Создаёт ошибку авторизации.
  const AuthFailure({
    super.message = 'Ошибка авторизации. Проверьте логин и пароль.',
    super.cause,
  });
}

/// Ошибка при работе с базой данных.
final class DatabaseFailure extends Failure {
  /// Создаёт ошибку базы данных.
  const DatabaseFailure({
    super.message = 'Ошибка при работе с данными. Попробуйте позже.',
    super.cause,
  });
}

/// Ошибка валидации пользовательского ввода.
final class ValidationFailure extends Failure {
  /// Создаёт ошибку валидации.
  const ValidationFailure({
    super.message = 'Проверьте правильность введённых данных.',
    super.cause,
  });
}

/// Непредвиденная ошибка, не попавшая в остальные категории.
final class UnexpectedFailure extends Failure {
  /// Создаёт непредвиденную ошибку.
  const UnexpectedFailure({
    super.message = 'Что-то пошло не так. Попробуйте ещё раз.',
    super.cause,
  });
}
