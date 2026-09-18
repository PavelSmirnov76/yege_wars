import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_tasks_repository.dart';
import '../../../helpers/pump_app.dart';

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
  Future<void> openTask(WidgetTester tester, {Size? surface}) async {
    if (surface != null) {
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
    );
    containerOf(tester)
        .read(appRouterProvider)
        .go(
          '/task/${testTask24.slug}',
        );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает условие и подсказку про справку', (tester) async {
    await openTask(tester);

    expect(find.byType(TaskScreen), findsOneWidget);
    expect(find.text('Условие'), findsWidgets);
    expect(find.text('Найдите наибольший фрагмент.'), findsOneWidget);
    expect(find.text(l10n.taskHelpHint), findsOneWidget);
  });

  testWidgets('на узком экране условие, справка и файлы — вкладки', (
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

  testWidgets('файл разворачивается и показывает первые строки', (
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

  testWidgets('ошибка загрузки показывается с повтором', (tester) async {
    tasks.taskResult = const Err(
      DatabaseFailure(message: 'Задача не найдена или ещё не открыта.'),
    );
    await openTask(tester);

    expect(find.text('Задача не найдена или ещё не открыта.'), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });

  group('filePreview', () {
    test('короткий файл показывается целиком', () {
      expect(filePreview('первая\nвторая'), 'первая\nвторая');
    });

    test('длинная строка обрезается с многоточием', () {
      final preview = filePreview('A' * 25000, maxLineLength: 10000);

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
