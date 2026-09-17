import 'package:seed_tasks/src/exceptions.dart';
import 'package:yaml/yaml.dart';

/// Допустимые форматы ответа — совпадают с check-ограничением
/// колонки tasks.answer_format в БД.
const Set<String> answerFormats = {'single', 'pair', 'multi', 'string'};

/// Минимальный и максимальный номер задания ЕГЭ (как в check в БД).
const int minEgeNumber = 2;
const int maxEgeNumber = 27;

/// Распарсенное содержимое task.yaml (без привязки к файловой системе).
class TaskYaml {
  const TaskYaml({
    required this.slug,
    required this.egeNumber,
    required this.title,
    required this.difficulty,
    required this.answerFormat,
    required this.tags,
    this.source,
  });

  /// Разбирает task.yaml из строки и проверяет обязательные поля
  /// и допустимые значения. При ошибке — [SeedValidationException]
  /// с русским сообщением.
  factory TaskYaml.parse(String content) {
    final Object? doc;
    try {
      doc = loadYaml(content);
    } on YamlException catch (error) {
      throw SeedValidationException('некорректный YAML: ${error.message}');
    }
    if (doc is! YamlMap) {
      throw SeedValidationException(
        'task.yaml должен быть YAML-объектом с полями задачи',
      );
    }
    final egeNumber = _requireInt(doc, 'ege_number');
    if (egeNumber < minEgeNumber || egeNumber > maxEgeNumber) {
      throw SeedValidationException(
        'поле «ege_number» должно быть в диапазоне '
        '$minEgeNumber..$maxEgeNumber, получено: $egeNumber',
      );
    }
    final difficulty = _requireInt(doc, 'difficulty');
    if (difficulty < 1 || difficulty > 3) {
      throw SeedValidationException(
        'поле «difficulty» должно быть от 1 до 3, получено: $difficulty',
      );
    }
    final answerFormat = _requireString(doc, 'answer_format');
    if (!answerFormats.contains(answerFormat)) {
      throw SeedValidationException(
        'поле «answer_format» должно быть одним из: '
        '${answerFormats.join(', ')}; получено: «$answerFormat»',
      );
    }
    return TaskYaml(
      slug: _requireString(doc, 'slug'),
      egeNumber: egeNumber,
      title: _requireString(doc, 'title'),
      difficulty: difficulty,
      answerFormat: answerFormat,
      tags: _readTags(doc),
      source: _readSource(doc),
    );
  }

  final String slug;
  final int egeNumber;
  final String title;
  final int difficulty;
  final String answerFormat;
  final List<String> tags;
  final String? source;

  static String _requireString(YamlMap doc, String key) {
    final value = doc[key];
    if (value is! String || value.trim().isEmpty) {
      throw SeedValidationException(
        'поле «$key» обязательно и должно быть непустой строкой',
      );
    }
    return value.trim();
  }

  static int _requireInt(YamlMap doc, String key) {
    final value = doc[key];
    if (value is! int) {
      throw SeedValidationException(
        'поле «$key» обязательно и должно быть целым числом',
      );
    }
    return value;
  }

  static List<String> _readTags(YamlMap doc) {
    final value = doc['tags'];
    if (value == null) {
      return const [];
    }
    if (value is! YamlList) {
      throw SeedValidationException(
        'поле «tags» должно быть списком строк',
      );
    }
    final tags = <String>[];
    for (final item in value) {
      if (item is! String || item.trim().isEmpty) {
        throw SeedValidationException(
          'поле «tags» должно содержать только непустые строки',
        );
      }
      tags.add(item.trim());
    }
    return tags;
  }

  static String? _readSource(YamlMap doc) {
    final value = doc['source'];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw SeedValidationException(
        'поле «source» должно быть непустой строкой или отсутствовать',
      );
    }
    return value.trim();
  }
}
