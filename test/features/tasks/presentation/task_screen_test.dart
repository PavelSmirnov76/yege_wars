import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/editor/presentation/controllers/draft_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/code_editor.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_card.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';
import 'package:yege_wars/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_draft_repository.dart';
import '../../../helpers/fake_submissions_repository.dart';
import '../../../helpers/fake_tasks_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/selection.dart';

class _MockDataSource extends Mock implements TasksRemoteDataSource {}

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeTasksRepository tasks;

  setUp(() {
    auth = FakeAuthRepository();
    tasks = FakeTasksRepository();
  });

  tearDown(() => auth.dispose());

  /// Переключает вкладку, доскроллив до неё: вкладок больше, чем влезает.
  Future<void> openTab(WidgetTester tester, String title) async {
    await tester.dragUntilVisible(
      find.descendant(of: find.byType(TabBar), matching: find.text(title)),
      find.byType(TabBar),
      const Offset(-120, 0),
    );
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text(title)),
    );
    await tester.pumpAndSettle();
  }

  /// Подписи вкладок страницы задачи — слева направо.
  List<String?> tabLabels(WidgetTester tester) => [
    for (final tab in tester.widgetList<Tab>(
      find.descendant(of: find.byType(TabBar), matching: find.byType(Tab)),
    ))
      tab.text,
  ];

  /// Открывает страницу задачи на узком экране (вкладки).
  ///
  /// [repository] подменяет репозиторий задач вместо [tasks], [drafts] —
  /// черновики, [submissions] — попытки. Без [settle] страница открывается
  /// конечным числом кадров: так видно, что сбой показан сразу, а не после
  /// автоповторов.
  Future<void> openTask(
    WidgetTester tester, {
    Size? surface,
    TasksRepository? repository,
    FakeDraftRepository? drafts,
    FakeSubmissionsRepository? submissions,
    bool settle = true,
  }) async {
    if (surface != null) {
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: repository ?? tasks,
      drafts: drafts,
      submissions: submissions,
    );
    containerOf(tester)
        .read(appRouterProvider)
        .go(
          '/task/${testTask24.slug}',
        );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('UC-15-P-01, UC-40-P-01: показывает условие и подсказку про '
      'справку', (
    tester,
  ) async {
    await openTask(tester);

    expect(find.byType(TaskScreen), findsOneWidget);
    expect(find.text('Условие'), findsWidgets);
    expect(find.text('Найдите наибольший фрагмент.'), findsOneWidget);
    expect(find.text(l10n.taskHelpHint), findsOneWidget);
  });

  testWidgets('UC-15-P-01, UC-40-P-01: на узком экране условие, справка и '
      'файлы — вкладки', (
    tester,
  ) async {
    await openTask(tester, surface: const Size(390, 800));

    expect(find.byType(TabBar), findsOneWidget);
    expect(tabLabels(tester), [
      'Условие',
      'Код',
      'Решения',
      'Справка',
      'Файлы',
    ]);

    await openTab(tester, l10n.taskFilesTitle);
    expect(find.text('24.txt'), findsOneWidget);
    expect(find.byType(TaskFilesPanel), findsOneWidget);

    await openTab(tester, l10n.taskHelpTitle);
    expect(find.text('Проход по строке окном'), findsOneWidget);
  });

  testWidgets('UC-40-P-01: без ручных связей справка показывает статью по '
      'теме', (
    tester,
  ) async {
    // Настоящий репозиторий поверх заглушки datasource: так проверяется,
    // что справка собирается из task_articles, а не только из ручных связей.
    final dataSource = _MockDataSource();
    when(() => dataSource.fetchTask(testTask24.slug)).thenAnswer(
      (_) async => {
        'id': testTask24.id,
        'slug': testTask24.slug,
        'ege_number': 24,
        'title': testTask24.title,
        'difficulty': 2,
        'statement_md': 'Найдите наибольший фрагмент.',
        'answer_format': 'single',
      },
    );
    when(() => dataSource.fetchFiles(testTask24.id)).thenAnswer(
      (_) async => [],
    );
    when(() => dataSource.fetchArticleLinks(testTask24.id)).thenAnswer(
      (_) async => [],
    );
    when(() => dataSource.fetchThemeArticles(testTask24.id)).thenAnswer(
      (_) async => [
        {'article_id': 'a-39', 'sort_order': 0},
      ],
    );
    when(() => dataSource.fetchArticles(['a-39'])).thenAnswer(
      (_) async => [
        {
          'id': 'a-39',
          'slug': 'kes-3-9',
          'title': 'Обработка строк',
          'summary': 'Статья основной темы задания.',
          'level': 1,
          'reading_minutes': 8,
        },
      ],
    );
    await openTask(
      tester,
      surface: const Size(390, 800),
      repository: TasksRepositoryImpl(dataSource),
    );

    // Статья основной темы — главная: над условием подсказка про справку.
    expect(find.text(l10n.taskHelpHint), findsOneWidget);

    await openTab(tester, l10n.taskHelpTitle);

    expect(find.widgetWithText(ArticleCard, 'Обработка строк'), findsOne);
    expect(find.text('Статья основной темы задания.'), findsOneWidget);
  });

  testWidgets('UC-15-P-01: файл разворачивается и показывает первые строки', (
    tester,
  ) async {
    await openTask(tester, surface: const Size(390, 800));

    await openTab(tester, l10n.taskFilesTitle);
    await tester.tap(find.text('24.txt'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.taskFilePreview), findsOneWidget);
    expect(find.text(l10n.taskFileCopy), findsOneWidget);
  });

  testWidgets('UC-40-P-01: справка — карточки как в справочнике, главные '
      'первыми, без раскрытия и кнопки «Справка»', (tester) async {
    tasks.taskResult = const Ok(
      TaskDetail(
        brief: testTask24,
        statementMd: 'Найдите наибольший фрагмент.',
        answerFormat: AnswerFormat.single,
        articles: [
          TaskArticleLink(
            article: ArticleBrief(
              slug: 'string-scan',
              title: 'Проход по строке окном',
              summary: 'Как посчитать фрагменты за один проход.',
              level: ArticleLevel.basic,
              readingMinutes: 7,
              egeNumbers: [24],
              tags: ['3.13', '3'],
            ),
            relevance: ArticleRelevance.primary,
          ),
          TaskArticleLink(
            article: ArticleBrief(
              slug: 'file-reading',
              title: 'Чтение файлов в Python',
              summary: 'Как открыть файл задания и пройти его построчно.',
              level: ArticleLevel.medium,
              readingMinutes: 6,
              egeNumbers: [9, 17, 24, 26, 27],
              tags: ['3.12', '3', 'files', 'extra'],
            ),
            relevance: ArticleRelevance.related,
          ),
        ],
      ),
    );
    await openTask(tester, surface: const Size(390, 800));
    await openTab(tester, l10n.taskHelpTitle);

    final primary = find.widgetWithText(ArticleCard, 'Проход по строке окном');
    final related = find.widgetWithText(ArticleCard, 'Чтение файлов в Python');
    expect(primary, findsOneWidget);
    expect(related, findsOneWidget);
    // Главная — первой.
    expect(
      tester.getTopLeft(primary).dy,
      lessThan(tester.getTopLeft(related).dy),
    );
    // Сопутствующая выглядит так же, как главная: описание, уровень, время
    // чтения, номера с «…» после четырёх, до трёх тегов.
    for (final text in [
      'Как открыть файл задания и пройти его построчно.',
      l10n.referenceLevelMedium,
      l10n.referenceReadingMinutes(6),
      '№ 9 № 17 № 24 № 26 …',
      '3.12',
      '3',
      'files',
    ]) {
      expect(
        find.descendant(of: related, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(find.text('extra'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.widgetWithText(FilledButton, l10n.taskHelpTitle), findsNothing);
  });

  testWidgets('UC-40-P-01: нажатие на карточку справки открывает статью в '
      'разделе «Справочник»', (tester) async {
    await openTask(tester, surface: const Size(390, 800));

    await openTab(tester, l10n.taskHelpTitle);
    await tester.tap(
      find.widgetWithText(ArticleCard, 'Проход по строке окном'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(currentLocation(tester), '/reference/string-scan');
  });

  testWidgets('UC-40-P-02: у задачи без статей справка пустая, подсказки над '
      'условием нет', (tester) async {
    tasks.taskResult = const Ok(
      TaskDetail(
        brief: testTask24,
        statementMd: '## Условие\n\nНайдите наибольший фрагмент.',
        answerFormat: AnswerFormat.single,
      ),
    );
    await openTask(tester, surface: const Size(390, 800));

    expect(find.text('Найдите наибольший фрагмент.'), findsOneWidget);
    expect(find.text(l10n.taskHelpHint), findsNothing);

    await openTab(tester, l10n.taskHelpTitle);

    expect(find.text(l10n.taskHelpEmpty), findsOneWidget);
  });

  testWidgets('UC-15-P-02: ошибка загрузки показывается с повтором', (
    tester,
  ) async {
    tasks.taskResult = const Err(
      DatabaseFailure(message: 'Задача не найдена или ещё не открыта.'),
    );
    await openTask(tester);

    expect(find.text('Задача не найдена или ещё не открыта.'), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });

  testWidgets('UC-15-P-03: сбой связи показывается сообщением с повтором', (
    tester,
  ) async {
    const failure = NetworkFailure();
    tasks.taskResult = const Err(failure);
    await openTask(tester);

    expect(find.text(failure.message), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l10n.commonRetry), findsOne);
    expect(find.byType(TaskFilesPanel), findsNothing);
  });

  testWidgets('UC-31-P-01, UC-31-P-04: пока черновик грузится, страница '
      'задачи не открыта — затем в поле кода черновик', (tester) async {
    final drafts = FakeDraftRepository()
      ..drafts[testTask24.id] = 'print(1)'
      ..loadGate = Completer<void>();
    // Широкий экран: поле кода сразу во вкладке «Задача».
    await openTask(
      tester,
      surface: const Size(1600, 900),
      drafts: drafts,
      settle: false,
    );

    // Задача пришла, черновик ещё нет — страница не открыта, поля кода нет.
    expect(
      containerOf(tester).read(taskProvider(testTask24.slug)),
      isA<AsyncData<TaskDetail>>(),
    );
    expect(drafts.loadCalls, 1);
    expect(find.byType(CodeEditor), findsNothing);
    expect(
      find.descendant(
        of: find.byType(TaskScreen),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    drafts.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(CodeEditor),
        matching: find.text('print(1)'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('UC-31-P-04: задача загрузилась, а черновик нет — вместо '
      'страницы сразу сообщение и «Повторить»', (tester) async {
    const failure = NetworkFailure();
    final drafts = FakeDraftRepository()
      ..drafts[testTask24.id] = 'print(1)'
      ..loadResult = const Err(failure);
    await openTask(tester, drafts: drafts, settle: false);

    // Задача пришла, черновик — нет; автоповторов нет, запрос один.
    final container = containerOf(tester);
    expect(
      container.read(taskProvider(testTask24.slug)),
      isA<AsyncData<TaskDetail>>(),
    );
    expect(
      container.read(draftControllerProvider(testTask24.id)),
      isA<AsyncError<String>>(),
    );
    expect(drafts.loadCalls, 1);

    final retry = find.widgetWithText(OutlinedButton, l10n.commonRetry);
    expect(find.text(failure.message), findsOneWidget);
    expect(retry, findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Заголовок — «Каталог», как при сбое загрузки задачи.
    expect(
      find.descendant(
        of: find.byType(TaskScreen),
        matching: find.text(l10n.navCatalog),
      ),
      findsOneWidget,
    );

    // «Повторить» открывает страницу, в поле кода — черновик.
    drafts.loadResult = null;
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(drafts.loadCalls, 2);
    expect(find.text(failure.message), findsNothing);
    expect(
      find.descendant(
        of: find.byType(TaskScreen),
        matching: find.text(testTask24.title),
      ),
      findsOneWidget,
    );
    await openTab(tester, l10n.editorTitle);
    expect(find.text('print(1)'), findsOneWidget);
  });

  testWidgets('UC-15-P-01, UC-34-P-01: на широком экране — вкладки «Задача», '
      '«Попытки», «Решения», «Справка», «Файлы»; во «Задаче» условие и код '
      'без «Моих попыток», во «Попытках» — список', (tester) async {
    final submissions = FakeSubmissionsRepository()
      ..attemptsResult = Ok([testCorrectAttempt]);
    await openTask(
      tester,
      surface: const Size(1600, 900),
      submissions: submissions,
    );

    expect(tabLabels(tester), [
      'Задача',
      'Попытки',
      'Решения',
      'Справка',
      'Файлы',
    ]);

    // «Задача»: слева условие, справа код — колонки 3 : 2.
    final statement = find.text('Найдите наибольший фрагмент.');
    expect(statement, findsOneWidget);
    expect(find.byType(CodeEditor), findsOneWidget);
    expect(
      tester.getCenter(statement).dx,
      lessThan(tester.getTopLeft(find.byType(CodeEditor)).dx),
    );
    final page = tester.getRect(find.byType(TabBarView));
    final divider = find.descendant(
      of: find.byType(TabBarView),
      matching: find.byType(VerticalDivider),
    );
    expect(
      tester.getCenter(divider).dx,
      moreOrLessEquals(page.left + page.width * 3 / 5, epsilon: 1),
    );
    expect(find.text(l10n.attemptsTitle), findsNothing);
    expect(find.byType(AttemptsList), findsNothing);

    await openTab(tester, 'Попытки');

    expect(find.byType(AttemptsList), findsOneWidget);
    expect(find.text(testCorrectAttempt.answer), findsOneWidget);
    expect(find.byType(CodeEditor), findsNothing);
  });

  /// Условие со всеми видами блоков: абзацы, таблица, блок кода.
  const statementBlocks = TaskDetail(
    brief: testTask24,
    statementMd:
        'Найдите наибольший фрагмент.\n\n'
        '| Строка | Длина |\n|---|---|\n| ABC | 3 |\n\n'
        '```python\nprint(len(s))\n```\n\n'
        'Ответ запишите числом.',
    answerFormat: AnswerFormat.single,
    source: 'Оригинальная задача',
    articles: [
      TaskArticleLink(
        article: ArticleBrief(
          slug: 'string-scan',
          title: 'Проход по строке окном',
          summary: 'Как посчитать фрагменты за один проход.',
          level: ArticleLevel.basic,
          readingMinutes: 7,
        ),
        relevance: ArticleRelevance.primary,
      ),
    ],
  );

  /// Выделяет условие от «Задание N» до источника и проверяет, что в
  /// скопированном всё условие: абзацы, таблица и блок кода.
  Future<String?> copyStatement(WidgetTester tester) async {
    final copied = await selectAndCopy(
      tester,
      from: find.text('Задание 24'),
      to: find.text('Источник: Оригинальная задача'),
    );
    for (final part in [
      'Задание 24',
      'Средняя',
      l10n.taskHelpHint,
      'Найдите наибольший фрагмент.',
      'ABC',
      'print(len(s))',
      'Ответ запишите числом.',
      'Источник: Оригинальная задача',
    ]) {
      expect(copied, contains(part));
    }
    return copied;
  }

  testWidgets('UC-15-P-01: на узком экране условие — одна область '
      'выделения от «Задание N» до источника', (tester) async {
    tasks.taskResult = const Ok(statementBlocks);
    await openTask(tester, surface: const Size(390, 1600));

    await copyStatement(tester);
  });

  testWidgets('UC-15-P-01: на широком экране условие — одна область '
      'выделения, код в неё не входит', (tester) async {
    tasks.taskResult = const Ok(statementBlocks);
    await openTask(tester, surface: const Size(1600, 1600));

    final copied = await copyStatement(tester);
    expect(copied, isNot(contains(l10n.editorRunHint)));
  });

  testWidgets('UC-28-P-01: ссылка на статью в условии открывает статью в '
      'разделе «Справочник»', (tester) async {
    tasks.taskResult = const Ok(
      TaskDetail(
        brief: testTask24,
        statementMd: 'Перечитай [[regex-basics]] перед решением.',
        answerFormat: AnswerFormat.single,
      ),
    );
    await openTask(tester, surface: const Size(390, 800));

    await tester.tapOnText(find.textRange.ofSubstring('Регулярные'));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(currentLocation(tester), '/reference/regex-basics');
  });

  group('filePreview', () {
    test('короткий файл показывается целиком', () {
      expect(filePreview('первая\nвторая'), 'первая\nвторая');
    });

    test('длинная строка обрезается с многоточием', () {
      final preview = filePreview('A' * 25000);

      expect(preview.length, 10001);
      expect(preview.endsWith('…'), isTrue);
    });

    test('лишние строки заменяются многоточием', () {
      final preview = filePreview(
        List.generate(40, (index) => 'строка $index').join('\n'),
      );

      expect(preview.split('\n').length, 11);
      expect(preview.split('\n').last, '…');
      expect(preview, contains('строка 9'));
      expect(preview, isNot(contains('строка 10')));
    });

    test('файл задания в одну строку не тянет за собой мегабайт', () {
      final preview = filePreview('ABC' * 400000);

      expect(preview.length, lessThan(10100));
    });
  });

  group('fileSizeLabel', () {
    test('маленький файл — в байтах', () {
      expect(fileSizeLabel(512, l10n), l10n.unitBytes(512));
    });

    test('большой файл — в килобайтах', () {
      expect(fileSizeLabel(1024 * 1024, l10n), l10n.unitKilobytes('1024'));
      expect(fileSizeLabel(2560, l10n), l10n.unitKilobytes('2.5'));
    });
  });
}
