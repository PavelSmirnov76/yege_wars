import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';

/// Статья про чтение файлов для тестов.
const ArticleBrief testFileReading = ArticleBrief(
  slug: 'file-reading',
  title: 'Чтение файлов в Python',
  summary: 'Как открыть файл задания и пройти его построчно.',
  level: ArticleLevel.basic,
  readingMinutes: 6,
  egeNumbers: [17, 24],
  tags: ['files'],
);

/// Статья про регулярные выражения для тестов.
const ArticleBrief testRegexBasics = ArticleBrief(
  slug: 'regex-basics',
  title: 'Регулярные выражения',
  summary: 'Как описать шаблон текста и найти его модулем re.',
  level: ArticleLevel.medium,
  readingMinutes: 8,
  egeNumbers: [24],
  tags: ['regex', 'strings'],
);

/// Репозиторий справочника для тестов: результаты задаются полями,
/// фильтр запоминается для проверок.
final class FakeReferenceRepository implements ReferenceRepository {
  /// Что вернёт [listArticles].
  Result<List<ArticleBrief>> articlesResult = const Ok([
    testFileReading,
    testRegexBasics,
  ]);

  /// Что вернёт [getArticle].
  Result<ReferenceArticle> articleResult = const Ok(
    ReferenceArticle(
      brief: testFileReading,
      contentMd: '## Когда это нужно\n\nПочти в каждом задании.',
    ),
  );

  /// Что вернёт [articleTitles].
  Result<Map<String, String>> titlesResult = const Ok({
    'regex-basics': 'Регулярные выражения',
  });

  /// Фильтр последнего вызова [listArticles].
  ArticleFilter? lastFilter;

  /// Сколько раз запрашивался список.
  int listCalls = 0;

  /// slug последнего запрошенной статьи.
  String? lastSlug;

  @override
  FutureResult<List<ArticleBrief>> listArticles(ArticleFilter filter) async {
    listCalls++;
    lastFilter = filter;
    return articlesResult;
  }

  @override
  FutureResult<ReferenceArticle> getArticle(String slug) async {
    lastSlug = slug;
    return articleResult;
  }

  @override
  FutureResult<Map<String, String>> articleTitles() async => titlesResult;
}

/// Ошибка сети для проверок сообщений.
const Failure testNetworkFailure = NetworkFailure();
