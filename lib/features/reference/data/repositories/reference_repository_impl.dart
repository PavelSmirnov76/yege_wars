import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/network/supabase_error_mapper.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/reference/data/datasources/reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/data/dto/article_dto.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';

/// Реализация [ReferenceRepository] поверх [ReferenceRemoteDataSource].
///
/// Реализует UC-36, UC-37 и UC-28.
final class ReferenceRepositoryImpl implements ReferenceRepository {
  /// Создаёт репозиторий поверх [ReferenceRemoteDataSource].
  const ReferenceRepositoryImpl(this._dataSource);

  static const String _articleMissing = 'Статья справочника не найдена.';

  final ReferenceRemoteDataSource _dataSource;

  @override
  FutureResult<List<ArticleBrief>> listArticles(ArticleFilter filter) async {
    try {
      final rows = await _dataSource.fetchArticles(filter);
      return Ok<List<ArticleBrief>>([
        for (final row in rows) ArticleDto.fromJson(row).toBrief(),
      ]);
    } on Object catch (error) {
      return Err<List<ArticleBrief>>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<ReferenceArticle> getArticle(String slug) async {
    try {
      final row = await _dataSource.fetchArticle(slug);
      if (row == null) {
        return const Err<ReferenceArticle>(
          DatabaseFailure(message: _articleMissing),
        );
      }
      return Ok<ReferenceArticle>(ArticleDto.fromJson(row).toArticle());
    } on Object catch (error) {
      return Err<ReferenceArticle>(SupabaseErrorMapper.map(error));
    }
  }

  @override
  FutureResult<Map<String, String>> articleTitles() async {
    try {
      final rows = await _dataSource.fetchTitles();
      return Ok<Map<String, String>>({
        for (final row in rows)
          if (row[ArticleColumns.slug] is String &&
              row[ArticleColumns.title] is String)
            row[ArticleColumns.slug]! as String:
                row[ArticleColumns.title]! as String,
      });
    } on Object catch (error) {
      return Err<Map<String, String>>(SupabaseErrorMapper.map(error));
    }
  }
}
