import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yege_wars/core/markdown/wiki_link_syntax.dart';

/// Преобразует разметку в HTML так же, как это делает AppMarkdown.
String render(String source, {Map<String, String> titles = const {}}) {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [WikiLinkSyntax((slug) => titles[slug])],
  );
  return md.renderToHtml(document.parse(source));
}

void main() {
  const titles = {'regex-basics': 'Регулярные выражения в Python'};

  group('WikiLinkSyntax', () {
    test('известный slug становится ссылкой с заголовком статьи', () {
      final html = render('См. [[regex-basics]] дальше.', titles: titles);

      expect(
        html,
        contains(
          '<a href="wiki://regex-basics">Регулярные выражения в Python</a>',
        ),
      );
    });

    test('неизвестный slug остаётся обычным текстом', () {
      final html = render('См. [[no-such-article]].', titles: titles);

      expect(html, contains('no-such-article'));
      expect(html, isNot(contains('<a href=')));
    });

    test('внутри блока кода ссылка не создаётся', () {
      final html = render(
        '```python\nprint("[[regex-basics]]")\n```',
        titles: titles,
      );

      expect(html, contains('[[regex-basics]]'));
      expect(html, isNot(contains('<a href=')));
    });

    test('внутри участка кода ссылка не создаётся', () {
      final html = render('Пиши `[[regex-basics]]` в тексте.', titles: titles);

      expect(html, contains('<code>[[regex-basics]]</code>'));
      expect(html, isNot(contains('<a href=')));
    });

    test('slug узнаётся по адресу ссылки', () {
      expect(WikiLinkSyntax.slugOf('wiki://graph-paths'), 'graph-paths');
      expect(WikiLinkSyntax.slugOf('https://example.com'), isNull);
      expect(WikiLinkSyntax.slugOf(null), isNull);
    });
  });
}
