import 'package:markdown/markdown.dart' as md;

/// Внутренние ссылки справочника вида `[[slug]]`.
///
/// Известный slug превращается в обычную ссылку markdown: адрес
/// `wiki://<slug>`, текст — заголовок статьи. Неизвестный slug становится
/// простым текстом: опечатка автора не должна выглядеть как поломка.
///
/// Внутри блоков и участков кода подстановка не работает: блочный код
/// разбирается до инлайн-разметки, а участок в обратных кавычках
/// разбирается целиком с первой кавычки.
final class WikiLinkSyntax extends md.InlineSyntax {
  /// Создаёт синтаксис; [titleOf] возвращает заголовок статьи по slug
  /// или `null`, если такой статьи нет.
  WikiLinkSyntax(this.titleOf) : super(linkPattern);

  /// Схема адреса, по которой ссылка узнаётся при нажатии.
  static const String scheme = 'wiki://';

  /// Шаблон ссылки: две квадратные скобки и slug статьи.
  static const String linkPattern = r'\[\[([a-z0-9-]{3,64})\]\]';

  /// Заголовок статьи по slug.
  final String? Function(String slug) titleOf;

  /// Возвращает slug, если [href] — внутренняя ссылка справочника.
  static String? slugOf(String? href) => href != null && href.startsWith(scheme)
      ? href.substring(scheme.length)
      : null;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final slug = match[1]!;
    final title = titleOf(slug);
    if (title == null) {
      parser.addNode(md.Text(slug));
      return true;
    }
    parser.addNode(
      md.Element.text('a', title)..attributes['href'] = '$scheme$slug',
    );
    return true;
  }
}
