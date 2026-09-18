import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/reference/data/datasources/reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';

/// Реализация [ReferenceRemoteDataSource] поверх [SupabaseClient].
///
/// Отбор и сортировку выполняет база: тащить весь справочник на клиент,
/// чтобы фильтровать его в памяти, незачем.
final class SupabaseReferenceRemoteDataSource
    implements ReferenceRemoteDataSource {
  /// Создаёт datasource поверх клиента [SupabaseClient].
  const SupabaseReferenceRemoteDataSource(this._client);

  /// Колонки карточки статьи (без текста).
  static const String _briefColumns =
      '${ArticleColumns.slug}, ${ArticleColumns.title}, '
      '${ArticleColumns.summary}, ${ArticleColumns.level}, '
      '${ArticleColumns.readingMinutes}, ${ArticleColumns.egeNumbers}, '
      '${ArticleColumns.tags}';

  /// Колонки статьи целиком.
  static const String _fullColumns =
      '$_briefColumns, ${ArticleColumns.contentMd}';

  /// Символы, ломающие синтаксис фильтра PostgREST.
  static final RegExp _unsafeSearchChars = RegExp(r'[,()*%\\"\x27]');

  final SupabaseClient _client;

  /// Готовит строку поиска к подстановке в фильтр.
  static String escapeSearch(String query) =>
      query.trim().replaceAll(_unsafeSearchChars, ' ').trim();

  @override
  Future<List<Map<String, dynamic>>> fetchArticles(
    ArticleFilter filter,
  ) async {
    var query = _client
        .from(SupabaseTables.referenceArticles)
        .select(_briefColumns);

    final egeNumber = filter.egeNumber;
    if (egeNumber != null) {
      query = query.contains(ArticleColumns.egeNumbers, [egeNumber]);
    }
    final tag = filter.tag;
    if (tag != null) {
      query = query.contains(ArticleColumns.tags, [tag]);
    }
    final level = filter.level;
    if (level != null) {
      query = query.eq(ArticleColumns.level, level.value);
    }
    final search = escapeSearch(filter.query);
    if (search.isNotEmpty) {
      query = query.or(
        '${ArticleColumns.title}.ilike.%$search%,'
        '${ArticleColumns.summary}.ilike.%$search%',
      );
    }

    return query.order(ArticleColumns.level).order(ArticleColumns.title);
  }

  @override
  Future<Map<String, dynamic>?> fetchArticle(String slug) => _client
      .from(SupabaseTables.referenceArticles)
      .select(_fullColumns)
      .eq(ArticleColumns.slug, slug)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchTitles() => _client
      .from(SupabaseTables.referenceArticles)
      .select('${ArticleColumns.slug}, ${ArticleColumns.title}');
}
