import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
import 'package:yege_wars/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:yege_wars/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_tasks_repository.dart';
import '../../../helpers/pump_app.dart';

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

  /// Открывает страницу задачи на узком экране (вкладки).
  ///
  /// [repository] подменяет репозиторий задач вместо [tasks].
  Future<void> openTask(
    WidgetTester tester, {
    Size? surface,
    TasksRepository? repository,
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
    );
    containerOf(tester)
        .read(appRouterProvider)
        .go(
          '/task/${testTask24.slug}',
        );
    await tester.pumpAndSettle();
  }

  testWidgets('UC-15-P-01: показывает условие и подсказку про справку', (
    tester,
  ) async {
    await openTask(tester);

    expect(find.byType(TaskScreen), findsOneWidget);
    expect(find.text('Условие'), findsWidgets);
    expect(find.text('Найдите наибольший фрагмент.'), findsOneWidget);
    expect(find.text(l10n.taskHelpHint), findsOneWidget);
  });

  testWidgets('UC-15-P-01: на узком экране условие, справка и файлы — '
      'вкладки', (
    tester,
  ) async {
    await openTask(tester, surface: const Size(390, 800));

    expect(find.byType(TabBar), findsOneWidget);

    await openTab(tester, l10n.taskFilesTitle);
    expect(find.text('24.txt'), findsOneWidget);
    expect(find.byType(TaskFilesPanel), findsOneWidget);

    await openTab(tester, l10n.taskHelpTitle);
    expect(find.text('Проход по строке окном'), findsOneWidget);
  });

  testWidgets('без ручных связей справка показывает статью по теме', (
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
    await openTab(tester, l10n.taskHelpTitle);

    expect(find.text('Обработка строк'), findsOneWidget);
    // Статья основной темы — главная: раскрыта и ведёт в справочник.
    expect(find.widgetWithText(FilledButton, l10n.taskHelpTitle), findsOne);
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

  testWidgets('из справки к задаче можно перейти в статью', (tester) async {
    await openTask(tester, surface: const Size(390, 800));

    await openTab(tester, l10n.taskHelpTitle);
    await tester.tap(find.widgetWithText(FilledButton, l10n.taskHelpTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
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
