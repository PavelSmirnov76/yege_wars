import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';

/// Карточка статьи справочника: всё, кроме текста.
///
/// Списку статей текст не нужен, а весит он много, поэтому из базы он
/// приходит только на странице самой статьи.
@immutable
final class ArticleBrief {
  /// Создаёт карточку статьи.
  const ArticleBrief({
    required this.slug,
    required this.title,
    required this.summary,
    required this.level,
    required this.readingMinutes,
    this.egeNumbers = const [],
    this.tags = const [],
  });

  /// Человекочитаемый идентификатор, например `regex-basics`.
  final String slug;

  /// Заголовок статьи.
  final String title;

  /// Одно предложение для карточки в списке.
  final String summary;

  /// Уровень сложности.
  final ArticleLevel level;

  /// Оценка времени чтения в минутах.
  final int readingMinutes;

  /// Номера заданий ЕГЭ, где приём пригодится.
  final List<int> egeNumbers;

  /// Теги статьи.
  final List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ArticleBrief && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'ArticleBrief($slug)';
}
