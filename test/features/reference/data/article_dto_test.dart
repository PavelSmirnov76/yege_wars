import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/reference/data/datasources/supabase_reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/data/dto/article_dto.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';

void main() {
  group('ArticleDto', () {
    test('разбирает карточку статьи', () {
      final brief = ArticleDto.fromJson(const {
        'slug': 'regex-basics',
        'title': 'Регулярные выражения',
        'summary': 'Как искать по шаблону.',
        'level': 2,
        'reading_minutes': 7,
        'ege_numbers': [24],
        'tags': ['regex', 'strings'],
      }).toBrief();

      expect(brief.slug, 'regex-basics');
      expect(brief.level, ArticleLevel.medium);
      expect(brief.readingMinutes, 7);
      expect(brief.egeNumbers, [24]);
      expect(brief.tags, ['regex', 'strings']);
    });

    test('пропуски в необязательных полях не ломают разбор', () {
      final brief = ArticleDto.fromJson(const {
        'slug': 'file-reading',
        'title': 'Чтение файлов',
      }).toBrief();

      expect(brief.summary, isEmpty);
      expect(brief.level, ArticleLevel.basic);
      expect(brief.readingMinutes, 0);
      expect(brief.egeNumbers, isEmpty);
      expect(brief.tags, isEmpty);
    });

    test('чужеродные значения в массивах отбрасываются', () {
      final brief = ArticleDto.fromJson(const {
        'slug': 'file-reading',
        'title': 'Чтение файлов',
        'ege_numbers': [24, 'ой', null],
        'tags': ['files', 7],
      }).toBrief();

      expect(brief.egeNumbers, [24]);
      expect(brief.tags, ['files']);
    });

    test('статья целиком содержит текст', () {
      final article = ArticleDto.fromJson(const {
        'slug': 'file-reading',
        'title': 'Чтение файлов',
        'content_md': '## Когда это нужно',
      }).toArticle();

      expect(article.contentMd, '## Когда это нужно');
      expect(article.brief.slug, 'file-reading');
    });

    test('без обязательных полей и без текста — FormatException', () {
      expect(
        () => ArticleDto.fromJson(const {'title': 'Без slug'}),
        throwsFormatException,
      );
      expect(
        () => ArticleDto.fromJson(const {
          'slug': 'file-reading',
          'title': 'Чтение файлов',
        }).toArticle(),
        throwsFormatException,
      );
    });
  });

  group('SupabaseReferenceRemoteDataSource.escapeSearch', () {
    test('убирает символы, ломающие фильтр PostgREST', () {
      expect(
        SupabaseReferenceRemoteDataSource.escapeSearch('re,(модуль)*%'),
        're  модуль',
      );
    });

    test('обычный запрос не меняется', () {
      expect(
        SupabaseReferenceRemoteDataSource.escapeSearch('  чтение файлов '),
        'чтение файлов',
      );
    });
  });
}
