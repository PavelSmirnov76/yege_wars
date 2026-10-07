import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';

class _MockDataSource extends Mock implements TasksRemoteDataSource {}

const Map<String, dynamic> _task24 = {
  'id': 'task-24',
  'slug': 'e24-longest-run',
  'ege_number': 24,
  'title': 'Наибольший фрагмент',
  'difficulty': 2,
  'tags': ['strings'],
};

const Map<String, dynamic> _task17 = {
  'id': 'task-17',
  'slug': 'e17-pairs-file',
  'ege_number': 17,
  'title': 'Пары чисел',
  'difficulty': 1,
  'tags': <String>[],
};

void main() {
  late _MockDataSource dataSource;
  late TasksRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const TaskFilter());
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    dataSource = _MockDataSource();
    repository = TasksRepositoryImpl(dataSource);
    when(() => dataSource.fetchStats()).thenAnswer((_) async => []);
    when(() => dataSource.fetchMyAttempts()).thenAnswer((_) async => []);
    when(() => dataSource.fetchFiles(any())).thenAnswer((_) async => []);
    when(() => dataSource.fetchArticleLinks(any())).thenAnswer((_) async => []);
    when(
      () => dataSource.fetchThemeArticles(any()),
    ).thenAnswer((_) async => []);
  });

  group('listCatalog', () {
    test('собирает карточки, прогресс и статистику', () async {
      when(
        () => dataSource.fetchTasks(any()),
      ).thenAnswer((_) async => [_task17, _task24]);
      when(() => dataSource.fetchStats()).thenAnswer(
        (_) async => [
          {
            'task_id': 'task-24',
            'attempted_students': 4,
            'solved_students': 3,
            'solved_percent': 75.0,
          },
        ],
      );
      when(() => dataSource.fetchMyAttempts()).thenAnswer(
        (_) async => [
          {'task_id': 'task-17', 'is_correct': false},
          {'task_id': 'task-17', 'is_correct': true},
          {'task_id': 'task-24', 'is_correct': false},
        ],
      );

      final items = (await repository.listCatalog(
        const TaskFilter(),
      )).valueOrNull!;

      expect(items.map((item) => item.task.slug), [
        'e17-pairs-file',
        'e24-longest-run',
      ]);
      expect(items.first.progress, TaskProgress.solved);
      expect(items.last.progress, TaskProgress.attempted);
      expect(items.last.stats.solvedPercent, 75.0);
      expect(items.first.stats.isEmpty, isTrue);
    });

    test('задача без моих попыток — не начата', () async {
      when(
        () => dataSource.fetchTasks(any()),
      ).thenAnswer((_) async => [_task24]);

      final items = (await repository.listCatalog(
        const TaskFilter(),
      )).valueOrNull!;

      expect(items.single.progress, TaskProgress.notStarted);
    });

    test('отбор по прогрессу выполняется на клиенте', () async {
      when(
        () => dataSource.fetchTasks(any()),
      ).thenAnswer((_) async => [_task17, _task24]);
      when(() => dataSource.fetchMyAttempts()).thenAnswer(
        (_) async => [
          {'task_id': 'task-17', 'is_correct': true},
        ],
      );

      final items = (await repository.listCatalog(
        const TaskFilter(progress: TaskProgress.solved),
      )).valueOrNull!;

      expect(items.single.task.slug, 'e17-pairs-file');
    });

    test('фильтр уходит в datasource без изменений', () async {
      const filter = TaskFilter(egeNumber: 24, difficulty: TaskDifficulty.hard);
      when(() => dataSource.fetchTasks(any())).thenAnswer((_) async => []);

      await repository.listCatalog(filter);

      verify(() => dataSource.fetchTasks(filter)).called(1);
    });

    test('обрыв связи превращается в сетевую ошибку', () async {
      when(
        () => dataSource.fetchTasks(any()),
      ).thenThrow(AuthRetryableFetchException());

      final result = await repository.listCatalog(const TaskFilter());

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('getTask', () {
    test('собирает условие, файлы и справку', () async {
      when(() => dataSource.fetchTask('e24-longest-run')).thenAnswer(
        (_) async => {
          ..._task24,
          'statement_md': '## Условие',
          'answer_format': 'single',
          'source': 'Оригинальная задача',
        },
      );
      when(() => dataSource.fetchFiles('task-24')).thenAnswer(
        (_) async => [
          {'filename': '24.txt', 'content': 'ABC', 'size_bytes': 3},
        ],
      );
      when(() => dataSource.fetchArticleLinks('task-24')).thenAnswer(
        (_) async => [
          {
            'relevance': 'related',
            'sort_order': 1,
            'reference_articles': {
              'slug': 'file-reading',
              'title': 'Чтение файлов',
              'summary': 'Как открыть файл.',
              'level': 1,
              'reading_minutes': 6,
            },
          },
          {
            'relevance': 'primary',
            'sort_order': 0,
            'reference_articles': {
              'slug': 'string-scan',
              'title': 'Проход по строке',
              'summary': 'Один проход вместо перебора.',
              'level': 1,
              'reading_minutes': 7,
            },
          },
        ],
      );

      final task = (await repository.getTask('e24-longest-run')).valueOrNull!;

      expect(task.statementMd, '## Условие');
      expect(task.files.single.filename, '24.txt');
      expect(task.source, 'Оригинальная задача');
      // Главные по теме статьи идут первыми.
      expect(task.articles.first.relevance, ArticleRelevance.primary);
      expect(task.primaryArticles.single.article.slug, 'string-scan');
    });

    test('справка по темам: статьи вторым запросом, ручные — следом', () async {
      when(
        () => dataSource.fetchTask('e24-longest-run'),
      ).thenAnswer((_) async => {..._task24, 'answer_format': 'single'});
      when(() => dataSource.fetchThemeArticles('task-24')).thenAnswer(
        (_) async => [
          {'article_id': 'a-39', 'sort_order': 0},
          {'article_id': 'a-32', 'sort_order': 1},
        ],
      );
      when(() => dataSource.fetchArticles(any())).thenAnswer(
        (_) async => [
          {'id': 'a-32', 'slug': 'kes-3-2', 'title': 'Тема 3.2'},
          {'id': 'a-39', 'slug': 'kes-3-9', 'title': 'Тема 3.9'},
        ],
      );
      when(() => dataSource.fetchArticleLinks('task-24')).thenAnswer(
        (_) async => [
          {
            'relevance': 'primary',
            'sort_order': 0,
            'reference_articles': {'slug': 'kes-3-2', 'title': 'Тема 3.2'},
          },
          {
            'relevance': 'related',
            'sort_order': 1,
            'reference_articles': {
              'slug': 'file-reading',
              'title': 'Чтение файлов',
            },
          },
        ],
      );

      final task = (await repository.getTask('e24-longest-run')).valueOrNull!;

      expect(
        [
          for (final link in task.articles)
            '${link.article.slug}: ${link.relevance.name}',
        ],
        ['kes-3-9: primary', 'kes-3-2: primary', 'file-reading: related'],
      );
      verify(() => dataSource.fetchArticles(['a-39', 'a-32'])).called(1);
    });

    test('без тем со статьями второй запрос не уходит', () async {
      when(
        () => dataSource.fetchTask('e24-longest-run'),
      ).thenAnswer((_) async => {..._task24, 'answer_format': 'single'});

      final task = (await repository.getTask('e24-longest-run')).valueOrNull!;

      expect(task.articles, isEmpty);
      verifyNever(() => dataSource.fetchArticles(any()));
    });

    test('неизвестная задача — понятная ошибка', () async {
      when(() => dataSource.fetchTask('нет')).thenAnswer((_) async => null);

      final result = await repository.getTask('нет');

      expect(result.failureOrNull, isA<DatabaseFailure>());
      expect(result.failureOrNull?.message, contains('не найдена'));
    });
  });

  test('номера заданий приходят без повторов и по порядку', () async {
    when(() => dataSource.fetchEgeNumbers()).thenAnswer(
      (_) async => [
        {'ege_number': 24},
        {'ege_number': 17},
        {'ege_number': 24},
      ],
    );

    final result = await repository.availableEgeNumbers();

    expect(result.valueOrNull, [17, 24]);
  });
}
