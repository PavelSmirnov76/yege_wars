import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';

/// Список статей справочника по фильтру.
///
/// Реализует UC-39.
final class ListArticlesUseCase {
  /// Создаёт use case поверх [ReferenceRepository].
  const ListArticlesUseCase(this._repository);

  final ReferenceRepository _repository;

  /// Загружает список статей.
  FutureResult<List<ArticleBrief>> call(ArticleFilter filter) =>
      _repository.listArticles(filter);
}
