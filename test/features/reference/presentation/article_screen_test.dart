import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/screens/article_screen.dart';
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

  /// Открывает статью по адресу.
  ///
  /// Без [settle] экран открывается конечным числом кадров: так видно, что
  /// сбой показан сразу, а не после автоповторов, — пока шли бы повторы,
  /// крутился бы индикатор, и `pumpAndSettle` прокрутил бы их.
  Future<void> openArticle(
    WidgetTester tester,
    String slug, {
    bool settle = true,
  }) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );
    containerOf(tester).read(appRouterProvider).go('/reference/$slug');
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Нажимает ссылку с текстом [text] в разметке статьи.
  ///
  /// Текст статьи выделяемый, и `tapOnText` подстроку в нём не находит
  /// (doc-комментарий `AppMarkdown`), поэтому нажатие отдаётся
  /// распознавателю ссылки — тому же, что сработал бы от пальца.
  void tapLink(WidgetTester tester, String text) {
    TapGestureRecognizer? recognizer;
    for (final widget in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      widget.textSpan?.visitChildren((span) {
        if (span is TextSpan &&
            span.text == text &&
            span.recognizer is TapGestureRecognizer) {
          recognizer = span.recognizer! as TapGestureRecognizer;
          return false;
        }
        return true;
      });
    }
    expect(recognizer, isNotNull, reason: 'нет ссылки «$text»');
    recognizer!.onTap!();
  }

  testWidgets('UC-37-P-01: показывает заголовок, сведения и '
      'текст', (tester) async {
    reference.articleResult = const Ok(
      ReferenceArticle(
        brief: testFileReading,
        contentMd:
            '## Когда это нужно\n\nПочти в каждом задании.\n\n'
            '```python\nprint(1)\n```\n',
      ),
    );
    await openArticle(tester, testFileReading.slug);

    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(find.text('Когда это нужно'), findsOneWidget);
    expect(find.text('Почти в каждом задании.'), findsOneWidget);
    expect(find.byType(CodeBlock), findsOneWidget);
    expect(
      find.text(l10n.referenceReadingMinutes(testFileReading.readingMinutes)),
      findsOneWidget,
    );
  });

  testWidgets('UC-28-P-01: заголовки статей передаются в '
      'разметку', (tester) async {
    reference.articleResult = const Ok(
      ReferenceArticle(
        brief: testFileReading,
        contentMd: 'Читай [[regex-basics]] дальше.',
      ),
    );
    await openArticle(tester, testFileReading.slug);

    final markdown = tester.widget<AppMarkdown>(find.byType(AppMarkdown));
    expect(markdown.articleTitles, {'regex-basics': 'Регулярные выражения'});
    expect(find.textContaining('Регулярные выражения'), findsOneWidget);
  });

  testWidgets('UC-37-P-02: статьи нет — сразу «Статья справочника не '
      'найдена.» и «Повторить»', (tester) async {
    reference.articleResult = const Err(
      DatabaseFailure(message: 'Статья справочника не найдена.'),
    );
    await openArticle(tester, 'no-such-article', settle: false);

    // Автоповторов нет: провайдер сразу в AsyncError, запрос один.
    expect(
      containerOf(tester).read(articleProvider('no-such-article')),
      isA<AsyncError<ReferenceArticle>>(),
    );
    expect(reference.articleCalls, 1);
    expect(
      find.descendant(
        of: find.byType(ArticleScreen),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(find.text('Статья справочника не найдена.'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, l10n.commonRetry),
      findsOneWidget,
    );
  });

  testWidgets('UC-37-P-03: сбой связи — сразу сообщение и «Повторить», '
      'без автоповторов', (tester) async {
    reference.articleResult = const Err(testNetworkFailure);
    await openArticle(tester, testFileReading.slug, settle: false);

    final retry = find.widgetWithText(OutlinedButton, l10n.commonRetry);
    expect(
      containerOf(tester).read(articleProvider(testFileReading.slug)),
      isA<AsyncError<ReferenceArticle>>(),
    );
    expect(reference.articleCalls, 1);
    expect(
      find.descendant(
        of: find.byType(ArticleScreen),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(find.text(testNetworkFailure.message), findsOneWidget);
    expect(retry, findsOneWidget);

    // «Повторить» загружает статью.
    reference.articleResult = const Ok(
      ReferenceArticle(brief: testFileReading, contentMd: 'Текст статьи.'),
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(reference.articleCalls, 2);
    expect(find.text(testNetworkFailure.message), findsNothing);
    expect(find.text('Текст статьи.', findRichText: true), findsOneWidget);
  });

  testWidgets('UC-28-P-02: словарь заголовков не загрузился — slug текстом '
      'до конца сессии', (tester) async {
    reference
      ..titlesResult = const Err(testNetworkFailure)
      ..articleResult = const Ok(
        ReferenceArticle(
          brief: testFileReading,
          contentMd: 'Читай [[regex-basics]] дальше.',
        ),
      );
    await openArticle(tester, testFileReading.slug);

    expect(find.textContaining('Читай regex-basics дальше.'), findsOneWidget);
    expect(find.textContaining('Регулярные выражения'), findsNothing);

    // Связь вернулась, но словарь за сессию больше не запрашивается: ни
    // сразу, ни после ухода из раздела ссылка не появляется.
    reference.titlesResult = const Ok({
      'regex-basics': 'Регулярные выражения',
    });
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Регулярные выражения'), findsNothing);

    final router = containerOf(tester).read(appRouterProvider)
      ..go(AppRoutes.catalog);
    await tester.pumpAndSettle();
    router.go('/reference/other-article');
    await tester.pumpAndSettle();

    expect(reference.lastSlug, 'other-article');
    expect(find.textContaining('Читай regex-basics дальше.'), findsOneWidget);
    expect(find.textContaining('Регулярные выражения'), findsNothing);
  });

  testWidgets('UC-28-P-03: обычная ссылка не открывается', (tester) async {
    reference.articleResult = const Ok(
      ReferenceArticle(
        brief: testFileReading,
        contentMd: 'Подробнее — в [документации](https://docs.python.org/3/).',
      ),
    );
    await openArticle(tester, testFileReading.slug);
    final location = currentLocation(tester);

    tapLink(tester, 'документации');
    await tester.pumpAndSettle();

    expect(currentLocation(tester), location);
    expect(reference.lastSlug, testFileReading.slug);
    expect(find.byType(ArticleScreen), findsOneWidget);
  });
}
