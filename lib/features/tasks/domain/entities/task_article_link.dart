import 'package:meta/meta.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';

/// Насколько статья справочника относится к задаче.
enum ArticleRelevance {
  /// Главная тема задачи.
  primary('primary'),

  /// Пригодится, но не основная.
  related('related')
  ;

  const ArticleRelevance(this.value);

  /// Значение в базе данных (колонка `relevance`).
  final String value;

  /// Значимость по значению из базы; неизвестное — [related].
  static ArticleRelevance fromValue(String? value) =>
      ArticleRelevance.values.firstWhere(
        (relevance) => relevance.value == value,
        orElse: () => ArticleRelevance.related,
      );
}

/// Связь задачи со статьёй справочника.
@immutable
final class TaskArticleLink {
  /// Создаёт связь.
  const TaskArticleLink({required this.article, required this.relevance});

  /// Статья справочника.
  final ArticleBrief article;

  /// Насколько статья относится к задаче.
  final ArticleRelevance relevance;

  /// `true`, если это главная тема задачи.
  bool get isPrimary => relevance == ArticleRelevance.primary;
}
