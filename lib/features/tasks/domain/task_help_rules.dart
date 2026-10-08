import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/theme_article.dart';

/// Правила справки задачи: статьи по темам и ручные связи в одном списке.
///
/// Реализует UC-27.
abstract final class TaskHelpRules {
  /// Сливает статьи по темам [byTheme] и ручные связи [manual].
  ///
  /// Каждая статья попадает в список один раз (по `slug`). Если статья
  /// пришла и по теме, и вручную, у неё более сильная значимость, а место —
  /// по теме. Порядок: главные первыми; внутри — статьи по темам в порядке
  /// тем, затем ручные в том порядке, в каком пришли.
  static List<TaskArticleLink> merge({
    required List<ThemeArticle> byTheme,
    required List<TaskArticleLink> manual,
  }) {
    final entries = <String, _Entry>{};
    for (final item in byTheme) {
      final known = entries[item.article.slug];
      entries[item.article.slug] = known == null
          ? _Entry(
              article: item.article,
              relevance: item.relevance,
              themeOrder: item.themeOrder,
              position: entries.length,
            )
          : known.merge(item.relevance, themeOrder: item.themeOrder);
    }
    for (final link in manual) {
      final known = entries[link.article.slug];
      entries[link.article.slug] = known == null
          ? _Entry(
              article: link.article,
              relevance: link.relevance,
              position: entries.length,
            )
          : known.merge(link.relevance);
    }

    final sorted = entries.values.toList()..sort(_Entry.compare);
    return [
      for (final entry in sorted)
        TaskArticleLink(article: entry.article, relevance: entry.relevance),
    ];
  }
}

/// Статья в процессе слияния: значимость, порядок темы и место прихода.
final class _Entry {
  const _Entry({
    required this.article,
    required this.relevance,
    required this.position,
    this.themeOrder,
  });

  final ArticleBrief article;
  final ArticleRelevance relevance;

  /// Порядок темы; `null` — статья пришла только ручной связью.
  final int? themeOrder;

  /// Каким по счёту статья пришла впервые.
  final int position;

  bool get isPrimary => relevance == ArticleRelevance.primary;

  /// Та же статья, пришедшая ещё раз: берётся более сильная значимость
  /// и ранняя тема, место прихода сохраняется.
  _Entry merge(ArticleRelevance other, {int? themeOrder}) => _Entry(
    article: article,
    relevance: isPrimary ? relevance : other,
    themeOrder: switch ((this.themeOrder, themeOrder)) {
      (final int a, final int b) => a < b ? a : b,
      (final int a, null) => a,
      (null, final b) => b,
    },
    position: position,
  );

  /// Главные первыми, затем по темам в порядке тем, затем ручные.
  static int compare(_Entry a, _Entry b) {
    if (a.isPrimary != b.isPrimary) {
      return a.isPrimary ? -1 : 1;
    }
    final aOrder = a.themeOrder;
    final bOrder = b.themeOrder;
    if (aOrder != null && bOrder != null && aOrder != bOrder) {
      return aOrder.compareTo(bOrder);
    }
    if ((aOrder == null) != (bOrder == null)) {
      return aOrder == null ? 1 : -1;
    }
    return a.position.compareTo(b.position);
  }
}
