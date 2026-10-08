import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/theme_article.dart';
import 'package:yege_wars/features/tasks/domain/task_help_rules.dart';

/// Карточка статьи с заданным slug.
ArticleBrief _article(String slug) => ArticleBrief(
  slug: slug,
  title: 'Статья $slug',
  summary: '',
  level: ArticleLevel.basic,
  readingMinutes: 5,
);

ThemeArticle _byTheme(String slug, int themeOrder) =>
    ThemeArticle(article: _article(slug), themeOrder: themeOrder);

TaskArticleLink _manual(String slug, ArticleRelevance relevance) =>
    TaskArticleLink(article: _article(slug), relevance: relevance);

/// Итог слияния в виде «slug: значимость» — так виден и порядок.
List<String> _view(List<TaskArticleLink> links) => [
  for (final link in links) '${link.article.slug}: ${link.relevance.name}',
];

void main() {
  group('TaskHelpRules.merge', () {
    test('UC-27-P-01: статья основной темы главная, других тем — '
        'сопутствующая', () {
      final links = TaskHelpRules.merge(
        byTheme: [_byTheme('kes-3-2', 0), _byTheme('kes-3-3', 1)],
        manual: const [],
      );

      expect(_view(links), ['kes-3-2: primary', 'kes-3-3: related']);
    });

    test('UC-27-P-01: без ручных связей справка состоит из статей по '
        'темам', () {
      final links = TaskHelpRules.merge(
        byTheme: [_byTheme('kes-3-9', 0)],
        manual: const [],
      );

      expect(links.single.article.slug, 'kes-3-9');
      expect(links.single.isPrimary, isTrue);
    });

    test('UC-27-P-01: без тем справка — ручные связи', () {
      final links = TaskHelpRules.merge(
        byTheme: const [],
        manual: [
          _manual('file-reading', ArticleRelevance.related),
          _manual('string-scan', ArticleRelevance.primary),
        ],
      );

      expect(_view(links), [
        'string-scan: primary',
        'file-reading: related',
      ]);
    });

    test('UC-27-P-01: главные первыми, внутри — по порядку темы, затем '
        'ручные', () {
      final links = TaskHelpRules.merge(
        // Темы пришли не по порядку: порядок задаёт правило, а не запрос.
        byTheme: [
          _byTheme('kes-3-5', 3),
          _byTheme('kes-3-2', 0),
          _byTheme('kes-3-4', 2),
          _byTheme('kes-3-3', 1),
        ],
        manual: [
          _manual('regex-basics', ArticleRelevance.related),
          _manual('file-reading', ArticleRelevance.primary),
          _manual('graph-paths', ArticleRelevance.related),
        ],
      );

      expect(_view(links), [
        'kes-3-2: primary',
        'file-reading: primary',
        'kes-3-3: related',
        'kes-3-4: related',
        'kes-3-5: related',
        'regex-basics: related',
        'graph-paths: related',
      ]);
    });

    test('UC-27-P-01: статья по теме и вручную — один раз, с более сильной '
        'значимостью и на месте темы', () {
      final links = TaskHelpRules.merge(
        byTheme: [
          _byTheme('kes-3-2', 0),
          _byTheme('kes-3-3', 1),
          _byTheme('kes-3-4', 2),
        ],
        manual: [
          _manual('string-scan', ArticleRelevance.primary),
          _manual('kes-3-4', ArticleRelevance.primary),
          _manual('kes-3-2', ArticleRelevance.related),
        ],
      );

      expect(_view(links), [
        'kes-3-2: primary',
        'kes-3-4: primary',
        'string-scan: primary',
        'kes-3-3: related',
      ]);
    });

    test('UC-27-P-01: повтор ручной связи не дублирует статью', () {
      final links = TaskHelpRules.merge(
        byTheme: const [],
        manual: [
          _manual('file-reading', ArticleRelevance.related),
          _manual('file-reading', ArticleRelevance.primary),
        ],
      );

      expect(_view(links), ['file-reading: primary']);
    });

    test('UC-27-P-01: статья двух тем — один раз, по ранней теме', () {
      final links = TaskHelpRules.merge(
        byTheme: [
          _byTheme('kes-3-3', 1),
          _byTheme('kes-3-4', 2),
          _byTheme('kes-3-3', 3),
          _byTheme('kes-3-2', 0),
        ],
        manual: const [],
      );

      expect(_view(links), [
        'kes-3-2: primary',
        'kes-3-3: related',
        'kes-3-4: related',
      ]);
    });

    test('UC-27-P-02: нет ни тем, ни ручных связей — справка пустая', () {
      expect(
        TaskHelpRules.merge(byTheme: const [], manual: const []),
        isEmpty,
      );
    });
  });
}
