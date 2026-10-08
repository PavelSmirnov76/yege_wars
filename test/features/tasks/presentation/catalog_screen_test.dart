import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_progress.dart';
import 'package:yege_wars/features/tasks/presentation/screens/catalog_screen.dart';
import 'package:yege_wars/features/tasks/presentation/screens/task_screen.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_card.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_reference_repository.dart';
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

  /// Открывает каталог под вошедшим учеником.
  Future<void> openCatalog(WidgetTester tester) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      tasks: tasks,
    );
    expect(find.byType(CatalogScreen), findsOneWidget);
  }

  testWidgets('UC-14-P-01: показывает задачи с группировкой по номеру', (
    tester,
  ) async {
    await openCatalog(tester);

    expect(find.text(testTask17.title), findsOneWidget);
    expect(find.text(testTask24.title), findsOneWidget);
    expect(find.text(l10n.catalogEgeGroup(17)), findsOneWidget);
    expect(find.text(l10n.catalogEgeGroup(24)), findsOneWidget);
  });

  testWidgets('UC-14-P-01: задача без номера КИМ попадает в группу «Без '
      'номера»', (
    tester,
  ) async {
    tasks.catalogResult = const Ok([testNoNumberItem]);
    await openCatalog(tester);

    expect(find.text(testTaskNoNumber.title), findsOneWidget);
    expect(find.text(l10n.catalogEgeGroupNone), findsOneWidget);
  });

  testWidgets('UC-14-P-01: показывает статус и статистику', (tester) async {
    await openCatalog(tester);

    // Те же слова есть среди фильтров, поэтому ищем внутри карточек.
    Finder inCards(String text) => find.descendant(
      of: find.byType(TaskCard),
      matching: find.text(text),
    );

    expect(inCards(l10n.progressSolved), findsOneWidget);
    expect(inCards(l10n.difficultyEasy), findsOneWidget);
    expect(find.text(l10n.catalogSolvedPercent(75)), findsOneWidget);
    expect(find.text(l10n.catalogNoAttempts), findsOneWidget);
  });

  testWidgets('UC-14-P-03: пустой каталог объясняет себя', (tester) async {
    tasks.catalogResult = const Ok([]);
    await openCatalog(tester);

    expect(find.text(l10n.catalogEmpty), findsOneWidget);
  });

  testWidgets('UC-14-P-02: фильтр по сложности уходит в запрос', (
    tester,
  ) async {
    await openCatalog(tester);

    await tester.tap(find.widgetWithText(FilterChip, l10n.difficultyHard));
    await tester.pumpAndSettle();

    expect(tasks.lastFilter?.difficulty, TaskDifficulty.hard);
  });

  testWidgets('UC-14-P-02: фильтр по состоянию решения уходит в запрос', (
    tester,
  ) async {
    await openCatalog(tester);

    await tester.tap(find.widgetWithText(FilterChip, l10n.progressSolved));
    await tester.pumpAndSettle();

    expect(tasks.lastFilter?.progress, TaskProgress.solved);
  });

  testWidgets('UC-14-P-04: ошибка каталога показывается с повтором', (
    tester,
  ) async {
    tasks.catalogResult = const Err(testNetworkFailure);
    await openCatalog(tester);

    expect(find.text(testNetworkFailure.message), findsOneWidget);

    tasks
      ..catalogResult = const Ok([testFreshItem])
      ..listCalls = 0;
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(tasks.listCalls, greaterThan(0));
    expect(find.text(testTask24.title), findsOneWidget);
  });

  testWidgets('UC-14-P-01: нажатие на карточку открывает задачу', (
    tester,
  ) async {
    await openCatalog(tester);

    await tester.tap(find.text(testTask24.title));
    await tester.pumpAndSettle();

    expect(find.byType(TaskScreen), findsOneWidget);
    expect(tasks.lastSlug, testTask24.slug);
  });
}
