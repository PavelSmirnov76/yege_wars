import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';

/// Статья справочника, которая полагается задаче по одной из её тем.
///
/// Реализует UC-27.
@immutable
final class ThemeArticle {
  /// Создаёт статью темы.
  const ThemeArticle({required this.article, required this.themeOrder});

  /// Порядок основной темы задачи.
  static const int mainThemeOrder = 0;

  /// Статья справочника.
  final ArticleBrief article;

  /// Порядок темы у задачи; [mainThemeOrder] — основная тема.
  final int themeOrder;

  /// Статья основной темы — главная, остальных тем — сопутствующая.
  ArticleRelevance get relevance => themeOrder == mainThemeOrder
      ? ArticleRelevance.primary
      : ArticleRelevance.related;
}
