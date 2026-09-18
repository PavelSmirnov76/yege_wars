import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';

/// Строка таблицы `reference_articles` в том виде, в каком её отдаёт
/// Supabase.
final class ArticleDto {
  /// Создаёт DTO.
  const ArticleDto({
    required this.slug,
    required this.title,
    required this.summary,
    required this.level,
    required this.readingMinutes,
    required this.egeNumbers,
    required this.tags,
    this.contentMd,
  });

  /// Разбирает ответ Supabase.
  ///
  /// Бросает [FormatException] при неожиданном ответе: это расхождение
  /// контракта с базой, а не ошибка пользователя.
  factory ArticleDto.fromJson(Map<String, dynamic> json) {
    final slug = json[ArticleColumns.slug];
    final title = json[ArticleColumns.title];
    if (slug is! String || title is! String) {
      throw FormatException('Некорректная строка статьи', json);
    }
    return ArticleDto(
      slug: slug,
      title: title,
      summary: json[ArticleColumns.summary] as String? ?? '',
      level: json[ArticleColumns.level] as int?,
      readingMinutes: json[ArticleColumns.readingMinutes] as int? ?? 0,
      egeNumbers: _intList(json[ArticleColumns.egeNumbers]),
      tags: _stringList(json[ArticleColumns.tags]),
      contentMd: json[ArticleColumns.contentMd] as String?,
    );
  }

  /// Человекочитаемый идентификатор.
  final String slug;

  /// Заголовок.
  final String title;

  /// Одно предложение для карточки.
  final String summary;

  /// Уровень из базы (может отсутствовать в выборке).
  final int? level;

  /// Оценка времени чтения.
  final int readingMinutes;

  /// Номера заданий ЕГЭ.
  final List<int> egeNumbers;

  /// Теги.
  final List<String> tags;

  /// Текст статьи; `null`, если колонку не запрашивали.
  final String? contentMd;

  /// Числа из массива jsonb; чужеродные значения отбрасываются.
  static List<int> _intList(Object? value) => value is List
      ? value.whereType<num>().map((item) => item.toInt()).toList()
      : const [];

  /// Строки из массива jsonb.
  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  /// Карточка статьи для списка.
  ArticleBrief toBrief() => ArticleBrief(
    slug: slug,
    title: title,
    summary: summary,
    level: ArticleLevel.fromValue(level),
    readingMinutes: readingMinutes,
    egeNumbers: egeNumbers,
    tags: tags,
  );

  /// Статья целиком; текст обязателен.
  ReferenceArticle toArticle() {
    final content = contentMd;
    if (content == null) {
      throw const FormatException('В ответе нет текста статьи');
    }
    return ReferenceArticle(brief: toBrief(), contentMd: content);
  }
}
