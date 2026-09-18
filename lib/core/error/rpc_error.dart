/// Ошибка, пришедшая из RPC-функции или триггера Supabase.
///
/// Функции БД сообщают об ошибках сообщением вида `[код] Русский текст`
/// (см. `supabase/migrations`): код нужен клиенту для ветвления,
/// текст — готовое сообщение для пользователя.
final class RpcError {
  /// Создаёт ошибку с кодом [code] и сообщением [message].
  const RpcError({required this.code, required this.message});

  /// Сообщение: код в квадратных скобках, следом текст.
  static final RegExp _pattern = RegExp(r'^\s*\[(\w+)\]\s*(.*)$', dotAll: true);

  /// Разбирает сообщение [raw]; `null`, если формат не совпал.
  static RpcError? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = _pattern.firstMatch(raw);
    if (match == null) {
      return null;
    }
    final message = (match.group(2) ?? '').trim();
    if (message.isEmpty) {
      return null;
    }
    return RpcError(code: match.group(1)!, message: message);
  }

  /// Код ошибки, например `username_taken`.
  final String code;

  /// Готовый русский текст для показа пользователю.
  final String message;
}

/// Коды ошибок БД, на которые клиент реагирует особым образом.
///
/// Полный список кодов — в `docs/STATE.md`; здесь только те,
/// что встречаются в сценариях авторизации.
abstract final class RpcErrorCodes {
  /// Регистрация закрыта администратором.
  static const String registrationClosed = 'registration_closed';

  /// Логин не соответствует правилам.
  static const String invalidUsername = 'invalid_username';

  /// Логин уже занят.
  static const String usernameTaken = 'username_taken';

  /// Действие доступно только администратору.
  static const String forbidden = 'forbidden';
}
