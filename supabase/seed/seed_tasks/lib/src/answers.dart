import 'dart:convert';
import 'dart:io';

import 'package:seed_tasks/src/exceptions.dart';
import 'package:seed_tasks/src/models.dart';

/// Загружает файл ответов — JSON-объект вида `{"<slug>": "<ответ>", ...}`.
///
/// Числовые значения приводятся к строке; всё остальное — ошибка.
Map<String, String> loadAnswers(File file) {
  if (!file.existsSync()) {
    throw SeedValidationException(
      'Файл ответов не найден: ${file.path}. '
      'Создайте JSON вида {"<slug>": "<ответ>", ...}.',
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw SeedValidationException(
      'Файл ответов ${file.path}: некорректный JSON (${error.message})',
    );
  }
  if (decoded is! Map<String, dynamic>) {
    throw SeedValidationException(
      'Файл ответов ${file.path}: ожидается JSON-объект '
      '{"<slug>": "<ответ>", ...}',
    );
  }
  final answers = <String, String>{};
  for (final entry in decoded.entries) {
    final value = entry.value;
    final String answer;
    if (value is String) {
      answer = value;
    } else if (value is num) {
      answer = value.toString();
    } else {
      throw SeedValidationException(
        'Файл ответов ${file.path}: ответ для «${entry.key}» '
        'должен быть строкой',
      );
    }
    if (answer.trim().isEmpty) {
      throw SeedValidationException(
        'Файл ответов ${file.path}: пустой ответ для «${entry.key}»',
      );
    }
    answers[entry.key] = answer;
  }
  return answers;
}

/// Итог сверки банка задач с файлом ответов.
class AnswersCheck {
  const AnswersCheck({required this.missing, required this.extra});

  /// Slug задач банка, для которых нет ответа (ошибка).
  final List<String> missing;

  /// Slug из файла ответов, которых нет в банке (предупреждение).
  final List<String> extra;
}

/// Сверяет банк задач с файлом ответов.
AnswersCheck checkAnswers({
  required List<TaskSeed> tasks,
  required Map<String, String> answers,
}) {
  final slugs = tasks.map((task) => task.slug).toSet();
  final missing = [
    for (final task in tasks)
      if (!answers.containsKey(task.slug)) task.slug,
  ]..sort();
  final extra = [
    for (final slug in answers.keys)
      if (!slugs.contains(slug)) slug,
  ]..sort();
  return AnswersCheck(missing: missing, extra: extra);
}
