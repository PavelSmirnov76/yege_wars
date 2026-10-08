import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';

/// Статья справочника целиком.
///
/// Реализует UC-26.
final class GetArticleUseCase {
  /// Создаёт use case поверх [ReferenceRepository].
  const GetArticleUseCase(this._repository);

  final ReferenceRepository _repository;

  /// Загружает статью по slug.
  FutureResult<ReferenceArticle> call(String slug) =>
      _repository.getArticle(slug);
}
