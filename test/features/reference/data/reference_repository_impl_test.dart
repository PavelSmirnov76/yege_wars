import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/reference/data/datasources/reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';

class _MockDataSource extends Mock implements ReferenceRemoteDataSource {}

const Map<String, dynamic> _row = {
  'slug': 'file-reading',
  'title': 'Чтение файлов',
  'summary': 'Как открыть файл.',
  'level': 1,
  'reading_minutes': 6,
  'ege_numbers': [17, 24],
  'tags': ['files'],
};

void main() {
  late _MockDataSource dataSource;
  late ReferenceRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const ArticleFilter()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = ReferenceRepositoryImpl(dataSource);
  });

  group('listArticles', () {
    test('возвращает карточки статей', () async {
      when(
        () => dataSource.fetchArticles(any()),
      ).thenAnswer((_) async => [_row]);

      final result = await repository.listArticles(const ArticleFilter());

      expect(result.valueOrNull?.single.slug, 'file-reading');
      expect(result.valueOrNull?.single.level, ArticleLevel.basic);
    });

    test('UC-36-P-02: фильтр передаётся в datasource без изменений', () async {
      const filter = ArticleFilter(egeNumber: 24, query: 'окно');
      when(() => dataSource.fetchArticles(any())).thenAnswer((_) async => []);

      await repository.listArticles(filter);

      verify(() => dataSource.fetchArticles(filter)).called(1);
    });

    test('обрыв связи превращается в сетевую ошибку', () async {
      when(
        () => dataSource.fetchArticles(any()),
      ).thenThrow(AuthRetryableFetchException());

      final result = await repository.listArticles(const ArticleFilter());

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('битая строка — ошибка базы данных', () async {
      when(
        () => dataSource.fetchArticles(any()),
      ).thenAnswer(
        (_) async => [
          const {'title': 'без slug'},
        ],
      );

      final result = await repository.listArticles(const ArticleFilter());

      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });

  group('getArticle', () {
    test('возвращает статью с текстом', () async {
      when(() => dataSource.fetchArticle('file-reading')).thenAnswer(
        (_) async => {..._row, 'content_md': '## Когда это нужно'},
      );

      final result = await repository.getArticle('file-reading');

      expect(result.valueOrNull?.contentMd, '## Когда это нужно');
    });

    test('UC-37-P-02: отсутствующая статья — понятная ошибка', () async {
      when(() => dataSource.fetchArticle('нет')).thenAnswer((_) async => null);

      final result = await repository.getArticle('нет');

      expect(result.failureOrNull, isA<DatabaseFailure>());
      expect(result.failureOrNull?.message, contains('не найдена'));
    });
  });

  group('articleTitles', () {
    test('UC-28-P-01: собирает словарь «slug — заголовок»', () async {
      when(() => dataSource.fetchTitles()).thenAnswer(
        (_) async => [
          {'slug': 'file-reading', 'title': 'Чтение файлов'},
          {'slug': 'regex-basics', 'title': 'Регулярные выражения'},
        ],
      );

      final result = await repository.articleTitles();

      expect(result.valueOrNull, {
        'file-reading': 'Чтение файлов',
        'regex-basics': 'Регулярные выражения',
      });
    });

    test('строки без нужных полей пропускаются', () async {
      when(() => dataSource.fetchTitles()).thenAnswer(
        (_) async => [
          {'slug': 'file-reading', 'title': 'Чтение файлов'},
          {'slug': 'broken'},
        ],
      );

      final result = await repository.articleTitles();

      expect(result.valueOrNull, {'file-reading': 'Чтение файлов'});
    });
  });
}
