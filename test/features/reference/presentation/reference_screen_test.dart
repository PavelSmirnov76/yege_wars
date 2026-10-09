import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
import 'package:yege_wars/features/reference/presentation/screens/reference_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_reference_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final l10n = AppLocalizationsRu();
  late FakeAuthRepository auth;
  late FakeReferenceRepository reference;

  setUp(() {
    auth = FakeAuthRepository();
    reference = FakeReferenceRepository();
  });

  tearDown(() => auth.dispose());

  /// Открывает раздел «Справочник» под вошедшим учеником.
  ///
  /// Без [settle] экран открывается конечным числом кадров: так видно, что
  /// сбой показан сразу, а не после автоповторов, — пока шли бы повторы,
  /// крутился бы индикатор, и `pumpAndSettle` прокрутил бы их.
  Future<void> openReference(WidgetTester tester, {bool settle = true}) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );
    containerOf(tester).read(appRouterProvider).go(AppRoutes.reference);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(find.byType(ReferenceScreen), findsOneWidget);
  }

  /// Подписи чипов отбора — сверху вниз, слева направо.
  List<String?> chipLabels(WidgetTester tester) => [
    for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip)))
      (chip.label as Text).data,
  ];

  /// Чипы уровня — они есть всегда.
  List<String> levelChips() => [
    l10n.referenceLevelBasic,
    l10n.referenceLevelMedium,
    l10n.referenceLevelAdvanced,
  ];

  testWidgets('пункт «Справочник» есть в навигации', (tester) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );

    expect(find.text(l10n.navReference), findsOneWidget);
  });

  testWidgets('UC-39-P-01: показывает список статей', (tester) async {
    await openReference(tester);

    expect(find.text(testFileReading.title), findsOneWidget);
    expect(find.text(testRegexBasics.title), findsOneWidget);
    expect(find.text(testFileReading.summary), findsOneWidget);
  });

  testWidgets('UC-39-P-03: пустой справочник объясняет себя', (tester) async {
    reference.articlesResult = const Ok([]);
    await openReference(tester);

    expect(find.text(l10n.referenceEmpty), findsOneWidget);
  });

  testWidgets('UC-39-P-02: выбор уровня уходит в запрос', (tester) async {
    await openReference(tester);

    await tester.tap(
      find.widgetWithText(FilterChip, l10n.referenceLevelMedium),
    );
    await tester.pumpAndSettle();

    expect(reference.lastFilter?.level, ArticleLevel.medium);
  });

  testWidgets('UC-39-P-04: ошибка списка показывается с кнопкой '
      'повтора', (tester) async {
    reference.articlesResult = const Err(testNetworkFailure);
    await openReference(tester);

    expect(find.text(testNetworkFailure.message), findsOneWidget);

    reference
      ..articlesResult = const Ok([testFileReading])
      ..listCalls = 0;
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(reference.listCalls, greaterThan(0));
    expect(find.text(testFileReading.title), findsOneWidget);
  });

  testWidgets('UC-39-P-01: нажатие на карточку открывает '
      'статью', (tester) async {
    await openReference(tester);

    await tester.tap(find.text(testFileReading.title));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(reference.lastSlug, testFileReading.slug);
  });

  testWidgets('UC-39-P-02: чипы номеров и разделов кодификатора — из '
      'значений фильтров, темы чипами не показываются', (tester) async {
    await openReference(tester);

    // Номера и разделы — ровно те, что есть у статей справочника: у первой
    // статьи раздел 3, у второй — 1; разделы идут по номеру. Темы «3.12» и
    // «1.4» и разделов 2 и 4, которых у статей нет, среди чипов нет.
    expect(chipLabels(tester), [
      ...levelChips(),
      l10n.referenceEgeNumber(17),
      l10n.referenceEgeNumber(24),
      '1 · Цифровая грамотность',
      '3 · Алгоритмы и программирование',
    ]);
  });

  testWidgets('UC-39-P-02: чип раздела отбирает по тегу раздела, повторное '
      'нажатие снимает условие', (tester) async {
    await openReference(tester);
    final section = find.widgetWithText(
      FilterChip,
      l10n.referenceSection3,
    );

    await tester.tap(section);
    await tester.pumpAndSettle();

    expect(reference.lastFilter, const ArticleFilter(tag: '3'));
    expect(tester.widget<FilterChip>(section).selected, isTrue);

    await tester.tap(section);
    await tester.pumpAndSettle();

    expect(reference.lastFilter, const ArticleFilter());
    expect(tester.widget<FilterChip>(section).selected, isFalse);
  });

  testWidgets('UC-39-P-02: у статей нет разделов — строки разделов нет', (
    tester,
  ) async {
    reference.articlesResult = const Ok([
      ArticleBrief(
        slug: 'no-section',
        title: 'Статья без раздела',
        summary: 'Только тема кодификатора.',
        level: ArticleLevel.basic,
        readingMinutes: 3,
        tags: ['2.1'],
      ),
    ]);
    await openReference(tester);

    expect(chipLabels(tester), levelChips());
  });

  testWidgets('UC-39-P-02: значения фильтров не загрузились — чипов номеров '
      'и разделов нет до перезагрузки страницы, а список работает', (
    tester,
  ) async {
    // При открытии нет связи: не загрузились ни список, ни значения
    // фильтров.
    reference.articlesResult = const Err(testNetworkFailure);
    await openReference(tester);

    // Связь вернулась: список поднимает «Повторить», а значения фильтров
    // больше не запрашиваются.
    reference.articlesResult = const Ok([testFileReading, testRegexBasics]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(testFileReading.title), findsOneWidget);
    expect(chipLabels(tester), levelChips());

    await tester.tap(find.widgetWithText(FilterChip, l10n.referenceLevelBasic));
    await tester.pumpAndSettle();

    expect(reference.lastFilter?.level, ArticleLevel.basic);

    // Не возвращаются они и после «Повторить».
    reference.articlesResult = const Err(testNetworkFailure);
    await tester.tap(find.widgetWithText(FilterChip, l10n.referenceLevelBasic));
    await tester.pumpAndSettle();
    reference.articlesResult = const Ok([testFileReading, testRegexBasics]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(testFileReading.title), findsOneWidget);
    expect(chipLabels(tester), levelChips());
  });

  testWidgets('UC-39-P-02: строка поиска уходит в запрос через 300 мс после '
      'ввода', (tester) async {
    await openReference(tester);
    final calls = reference.listCalls;

    await tester.enterText(find.byType(TextField), 'файл');
    await tester.pump(const Duration(milliseconds: 299));

    expect(reference.listCalls, calls);
    expect(reference.lastFilter?.query, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(reference.listCalls, calls + 1);
    expect(reference.lastFilter?.query, 'файл');
  });

  testWidgets('UC-39-P-02: «Сбросить фильтры» снимает все условия и строку '
      'поиска, а текст в поле остаётся', (tester) async {
    await openReference(tester);
    final reset = find.widgetWithText(TextButton, l10n.referenceResetFilters);

    expect(reset, findsNothing);

    await tester.tap(
      find.widgetWithText(FilterChip, l10n.referenceLevelMedium),
    );
    await tester.pumpAndSettle();

    expect(reset, findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilterChip, l10n.referenceEgeNumber(24)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, l10n.referenceSection1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'окно');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      reference.lastFilter,
      const ArticleFilter(
        egeNumber: 24,
        tag: '1',
        level: ArticleLevel.medium,
        query: 'окно',
      ),
    );

    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(reference.lastFilter, const ArticleFilter());
    expect(reset, findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'окно',
    );
  });

  testWidgets('UC-39-P-03: по заданным условиям статей нет', (tester) async {
    reference.articlesResult = const Ok([]);
    await openReference(tester);

    await tester.tap(
      find.widgetWithText(FilterChip, l10n.referenceLevelAdvanced),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.referenceEmptyFiltered), findsOneWidget);
    expect(find.text(l10n.referenceEmpty), findsNothing);
  });

  testWidgets('UC-39-P-04: сбой связи — сразу сообщение и «Повторить», '
      'без автоповторов', (tester) async {
    reference.articlesResult = const Err(testNetworkFailure);
    await openReference(tester, settle: false);

    final spinner = find.descendant(
      of: find.byType(ReferenceScreen),
      matching: find.byType(CircularProgressIndicator),
    );

    // Провайдер сразу в AsyncError; запросов два — список и значения
    // фильтров, по одному.
    expect(
      containerOf(tester).read(articlesProvider),
      isA<AsyncError<List<ArticleBrief>>>(),
    );
    expect(reference.listCalls, 2);
    expect(spinner, findsNothing);
    expect(find.text(testNetworkFailure.message), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, l10n.commonRetry),
      findsOneWidget,
    );

    // И через минуту повторов нет.
    await tester.pump(const Duration(minutes: 1));
    expect(reference.listCalls, 2);
  });
}
