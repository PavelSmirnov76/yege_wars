import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';

/// Доступ к справочнику мини-уроков.
///
/// Неопубликованные статьи отсекает база (RLS), клиент о них не знает.
abstract interface class ReferenceRepository {
  /// Список статей по фильтру.
  FutureResult<List<ArticleBrief>> listArticles(ArticleFilter filter);

  /// Статья целиком по slug.
  FutureResult<ReferenceArticle> getArticle(String slug);

  /// Заголовки всех доступных статей: нужны для ссылок `[[slug]]`.
  FutureResult<Map<String, String>> articleTitles();
}
