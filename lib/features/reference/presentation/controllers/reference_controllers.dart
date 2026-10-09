import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_facets.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/reference_providers.dart';

part 'reference_controllers.g.dart';

/// Текущие условия отбора статей в разделе «Справочник».
///
/// Реализует UC-36.
@riverpod
class ArticleFilterController extends _$ArticleFilterController {
  @override
  ArticleFilter build() => const ArticleFilter();

  /// Задаёт строку поиска.
  void setQuery(String query) => state = state.copyWith(query: query);

  /// Переключает номер задания ЕГЭ: повторный выбор снимает фильтр.
  void toggleEgeNumber(int egeNumber) => state = state.egeNumber == egeNumber
      ? state.copyWith(clearEgeNumber: true)
      : state.copyWith(egeNumber: egeNumber);

  /// Переключает тег.
  void toggleTag(String tag) => state = state.tag == tag
      ? state.copyWith(clearTag: true)
      : state.copyWith(tag: tag);

  /// Переключает уровень сложности.
  void toggleLevel(ArticleLevel level) => state = state.level == level
      ? state.copyWith(clearLevel: true)
      : state.copyWith(level: level);

  /// Сбрасывает все условия.
  void reset() => state = const ArticleFilter();
}

/// Список статей по текущему фильтру.
///
/// Реализует UC-36.
@riverpod
Future<List<ArticleBrief>> articles(Ref ref) async {
  final filter = ref.watch(articleFilterControllerProvider);
  final result = await ref.watch(listArticlesUseCaseProvider)(filter);
  return result.fold(
    onOk: (articles) => articles,
    onErr: (failure) => throw failure,
  );
}

/// Значения фильтров: какие номера заданий и теги вообще встречаются.
///
/// Считается по всему справочнику один раз за сессию — статей немного.
///
/// Реализует UC-36.
@Riverpod(keepAlive: true)
Future<ArticleFacets> articleFacets(Ref ref) async {
  final result = await ref.watch(listArticlesUseCaseProvider)(
    const ArticleFilter(),
  );
  return result.fold(
    onOk: (articles) => ArticleFacets(
      egeNumbers: {
        for (final article in articles) ...article.egeNumbers,
      }.toList()..sort(),
      tags: {for (final article in articles) ...article.tags}.toList()..sort(),
    ),
    // Без значений фильтров раздел остаётся рабочим: список статей грузится
    // отдельно и сам покажет свою ошибку.
    onErr: (_) => const ArticleFacets(),
  );
}

/// Статья справочника по slug.
///
/// Реализует UC-37.
@riverpod
Future<ReferenceArticle> article(Ref ref, String slug) async {
  final result = await ref.watch(getArticleUseCaseProvider)(slug);
  return result.fold(
    onOk: (article) => article,
    onErr: (failure) => throw failure,
  );
}

/// Заголовки статей для внутренних ссылок `[[slug]]`.
///
/// Словарь маленький (slug и заголовок), поэтому грузится целиком и живёт
/// до конца сессии.
///
/// Реализует UC-28.
@Riverpod(keepAlive: true)
Future<Map<String, String>> articleTitles(Ref ref) async {
  final result = await ref.watch(getArticleTitlesUseCaseProvider)();
  return result.fold(
    onOk: (titles) => titles,
    // Ссылки — украшение статьи: без словаря они станут текстом,
    // а сама статья должна открыться.
    onErr: (_) => const <String, String>{},
  );
}
