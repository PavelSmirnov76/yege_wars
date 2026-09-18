import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';

/// Статья справочника целиком: карточка и текст.
@immutable
final class ReferenceArticle {
  /// Создаёт статью.
  const ReferenceArticle({required this.brief, required this.contentMd});

  /// Карточка статьи (заголовок, теги, уровень и прочее).
  final ArticleBrief brief;

  /// Текст статьи в markdown.
  final String contentMd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceArticle &&
          other.brief == brief &&
          other.contentMd == contentMd;

  @override
  int get hashCode => Object.hash(brief, contentMd);
}
