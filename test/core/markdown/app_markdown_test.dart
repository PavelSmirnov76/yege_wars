import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/theme/app_theme.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/markdown/code_block.dart';

/// Собирает экран с разметкой [data].
Future<void> pumpMarkdown(
  WidgetTester tester,
  String data, {
  Map<String, String> articleTitles = const {},
  ValueChanged<String>? onArticleTap,
  bool selectable = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: AppMarkdown(
            data: data,
            articleTitles: articleTitles,
            onArticleTap: onArticleTap,
            selectable: selectable,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('UC-26-P-01: рисует заголовок, абзац и блок '
      'кода', (tester) async {
    await pumpMarkdown(
      tester,
      '# Чтение файлов\n\nОткрываем файл.\n\n```python\nprint(1)\n```\n',
    );

    expect(find.text('Чтение файлов'), findsOneWidget);
    expect(find.text('Открываем файл.'), findsOneWidget);
    expect(find.byType(CodeBlock), findsOneWidget);
  });

  testWidgets('UC-28-P-01: нажатие на внутреннюю ссылку отдаёт '
      'slug', (tester) async {
    String? tapped;
    await pumpMarkdown(
      tester,
      'Смотри [[regex-basics]] дальше.',
      articleTitles: const {'regex-basics': 'Регулярные выражения'},
      onArticleTap: (slug) => tapped = slug,
      // Нажатие по подстроке ищется только в невыделяемом тексте.
      selectable: false,
    );

    expect(find.textContaining('Регулярные выражения'), findsOneWidget);

    await tester.tapOnText(find.textRange.ofSubstring('Регулярные'));
    await tester.pumpAndSettle();

    expect(tapped, 'regex-basics');
  });

  testWidgets('UC-28-P-02: неизвестная ссылка остаётся '
      'текстом', (tester) async {
    var tapped = false;
    await pumpMarkdown(
      tester,
      'Смотри [[no-such-article]] дальше.',
      onArticleTap: (_) => tapped = true,
    );

    expect(find.textContaining('no-such-article'), findsOneWidget);
    expect(tapped, isFalse);
  });

  testWidgets('UC-26-P-01: таблица и цитата не ломают '
      'разметку', (tester) async {
    await pumpMarkdown(
      tester,
      '| Поле | Тип |\n|---|---|\n| slug | text |\n\n> Важно помнить.\n',
    );

    expect(find.text('Важно помнить.'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
  });
}
