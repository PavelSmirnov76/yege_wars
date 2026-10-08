import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';

/// Правила ответа, которые клиент применяет до отправки.
///
/// Реализует UC-18.
abstract final class AnswerRules {
  /// Ответ, который кнопка «Взять из вывода» берёт из вывода [stdout].
  ///
  /// Для [AnswerFormat.multi] — все непустые строки через один пробел:
  /// таблица, напечатанная по строкам, превращается в ответ одной строкой,
  /// как его ждёт платформа. Для остальных форматов — последняя непустая
  /// строка: обычно программа печатает ответ последним. Пустой вывод —
  /// пустая строка.
  static String fromOutput(String stdout, AnswerFormat format) {
    final lines = [
      for (final line in stdout.split('\n'))
        if (line.trim() case final trimmed when trimmed.isNotEmpty) trimmed,
    ];
    if (lines.isEmpty) {
      return '';
    }
    return switch (format) {
      AnswerFormat.multi => lines.join(' '),
      AnswerFormat.single ||
      AnswerFormat.pair ||
      AnswerFormat.string => lines.last,
    };
  }
}
