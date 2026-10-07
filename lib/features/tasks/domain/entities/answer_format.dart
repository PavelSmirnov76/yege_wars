/// Формат ответа задачи: от него зависят подсказка под полем ответа
/// и то, что подставляет кнопка «Взять из вывода».
///
/// Сравнивает ответ база (`normalize_answer`): числовые форматы — по
/// числам, [string] — строкой.
enum AnswerFormat {
  /// Одно число.
  single('single'),

  /// Два числа через пробел.
  pair('pair'),

  /// Несколько чисел через пробел (например, таблица по строкам).
  multi('multi'),

  /// Строка, сравнивается как есть.
  string('string')
  ;

  const AnswerFormat(this.value);

  /// Значение в базе данных (колонка `answer_format`).
  final String value;

  /// Формат по значению из базы; неизвестное значение — [string].
  ///
  /// Подсказка для [string] («точно как требует условие») верна для любого
  /// ответа, а кнопка «Взять из вывода» берёт последнюю строку, как и было.
  static AnswerFormat fromValue(String? value) =>
      AnswerFormat.values.firstWhere(
        (format) => format.value == value,
        orElse: () => AnswerFormat.string,
      );
}
