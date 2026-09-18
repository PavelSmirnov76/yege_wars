import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
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
  Future<void> openReference(WidgetTester tester) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );
    containerOf(tester).read(appRouterProvider).go(AppRoutes.reference);
    await tester.pumpAndSettle();
    expect(find.byType(ReferenceScreen), findsOneWidget);
  }

  testWidgets('пункт «Справочник» есть в навигации', (tester) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );

    expect(find.text(l10n.navReference), findsOneWidget);
  });

  testWidgets('показывает список статей', (tester) async {
    await openReference(tester);

    expect(find.text(testFileReading.title), findsOneWidget);
    expect(find.text(testRegexBasics.title), findsOneWidget);
    expect(find.text(testFileReading.summary), findsOneWidget);
  });

  testWidgets('пустой справочник объясняет себя', (tester) async {
    reference.articlesResult = const Ok([]);
    await openReference(tester);

    expect(find.text(l10n.referenceEmpty), findsOneWidget);
  });

  testWidgets('выбор уровня уходит в запрос', (tester) async {
    await openReference(tester);

    await tester.tap(
      find.widgetWithText(FilterChip, l10n.referenceLevelMedium),
    );
    await tester.pumpAndSettle();

    expect(reference.lastFilter?.level, ArticleLevel.medium);
  });

  testWidgets('ошибка списка показывается с кнопкой повтора', (tester) async {
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

  testWidgets('нажатие на карточку открывает статью', (tester) async {
    await openReference(tester);

    await tester.tap(find.text(testFileReading.title));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(reference.lastSlug, testFileReading.slug);
  });
}
