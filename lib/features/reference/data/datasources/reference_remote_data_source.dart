import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';

/// Низкоуровневый доступ к таблице статей справочника.
///
/// Исключения SDK пробрасываются как есть: в `Failure` их переводит
/// репозиторий, чтобы разбор ошибок жил в одном месте.
abstract interface class ReferenceRemoteDataSource {
  /// Строки статей по фильтру, без текста.
  Future<List<Map<String, dynamic>>> fetchArticles(ArticleFilter filter);

  /// Строка статьи целиком; `null`, если статьи нет или она не видна.
  Future<Map<String, dynamic>?> fetchArticle(String slug);

  /// Пары «slug — заголовок» всех доступных статей.
  Future<List<Map<String, dynamic>>> fetchTitles();
}
