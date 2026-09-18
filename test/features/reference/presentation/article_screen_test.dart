import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
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
  Future<void> openArticle(WidgetTester tester, String slug) async {
    await pumpApp(
      tester,
      repository: auth,
      initialUserId: testStudent.id,
      reference: reference,
    );
    containerOf(tester).read(appRouterProvider).go('/reference/$slug');
    await tester.pumpAndSettle();
  }

  testWidgets('показывает заголовок, сведения и текст', (tester) async {
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

  testWidgets('заголовки статей передаются в разметку', (tester) async {
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

  testWidgets('ошибка загрузки показывается с повтором', (tester) async {
    reference.articleResult = const Err(
      DatabaseFailure(message: 'Статья справочника не найдена.'),
    );
    await openArticle(tester, 'no-such-article');

    expect(find.text('Статья справочника не найдена.'), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });
}
