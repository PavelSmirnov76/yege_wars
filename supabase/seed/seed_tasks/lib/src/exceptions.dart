/// Ошибка валидации банка задач, файла ответов или конфигурации сида.
///
/// Сообщение — готовый русский текст для вывода пользователю.
class SeedValidationException implements Exception {
  SeedValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
