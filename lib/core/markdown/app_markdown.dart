import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/markdown/code_block.dart';
import 'package:yege_wars/core/markdown/wiki_link_syntax.dart';

/// Единый рендерер markdown: условия задач и статьи справочника рисуются
/// одним и тем же кодом, поэтому выглядят одинаково.
///
/// Поддерживает заголовки, списки, таблицы, цитаты, выделение, ссылки,
/// участки и блоки кода с подсветкой Python, а также внутренние ссылки
/// справочника `[[slug]]`.
class AppMarkdown extends StatelessWidget {
  /// Создаёт рендерер разметки [data].
  const AppMarkdown({
    required this.data,
    this.articleTitles = const {},
    this.onArticleTap,
    this.selectable = true,
    super.key,
  });

  /// Толщина полосы у цитаты.
  static const double _quoteBarWidth = 3;

  /// Размер шрифта участка кода внутри абзаца.
  static const double _inlineCodeFontSize = 13;

  /// Текст разметки.
  final String data;

  /// Заголовки известных статей по slug — для ссылок `[[slug]]`.
  ///
  /// Если slug отсутствует в словаре, ссылка рисуется обычным текстом.
  final Map<String, String> articleTitles;

  /// Вызывается при нажатии на внутреннюю ссылку справочника.
  final ValueChanged<String>? onArticleTap;

  /// Можно ли выделять текст.
  ///
  /// По умолчанию да: ученику нужно копировать примеры кода. Выделяемый
  /// текст рисуется полем ввода, поэтому в виджет-тестах нажатие по
  /// подстроке ищется только при `selectable: false`.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      // Разметка разбирается заново только при смене data, поэтому ключ
      // учитывает и словарь заголовков: он приезжает асинхронно, и без
      // этого ссылки [[slug]] остались бы обычным текстом.
      key: ValueKey(
        Object.hash(data, Object.hashAllUnordered(articleTitles.keys)),
      ),
      data: data,
      selectable: selectable,
      styleSheet: _styleSheet(context),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [WikiLinkSyntax((slug) => articleTitles[slug])],
      builders: {'pre': _CodeBlockBuilder()},
      onTapLink: (text, href, title) {
        final slug = WikiLinkSyntax.slugOf(href);
        if (slug != null) {
          onArticleTap?.call(slug);
        }
      },
    );
  }

  /// Стили разметки поверх темы приложения.
  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: text.bodyMedium,
      h1: text.headlineSmall,
      h2: text.titleLarge,
      h3: text.titleMedium,
      h4: text.titleSmall,
      listBullet: text.bodyMedium,
      code: AppTypography.code(fontSize: _inlineCodeFontSize).copyWith(
        backgroundColor: AppColors.codeBackground,
      ),
      // Рамку и фон блока кода рисует сам CodeBlock.
      codeblockPadding: EdgeInsets.zero,
      codeblockDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.all(AppSpacing.md),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: _quoteBarWidth),
        ),
      ),
      a: const TextStyle(
        color: AppColors.accent,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.accent,
      ),
      tableBorder: TableBorder.all(color: AppColors.border),
      tableCellsPadding: const EdgeInsets.all(AppSpacing.sm),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      blockSpacing: AppSpacing.md,
    );
  }
}

/// Билдер блоков кода: заменяет стандартный `pre` на [CodeBlock].
final class _CodeBlockBuilder extends MarkdownElementBuilder {
  /// Префикс класса, в котором приходит язык блока.
  static const String _languagePrefix = 'language-';

  /// Язык из ограды блока (` ```python `), если он указан.
  static String? _languageOf(md.Element element) {
    final children = element.children;
    if (children == null || children.isEmpty) {
      return null;
    }
    final first = children.first;
    final className = first is md.Element ? first.attributes['class'] : null;
    return className != null && className.startsWith(_languagePrefix)
        ? className.substring(_languagePrefix.length)
        : null;
  }

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return CodeBlock(
      code: element.textContent.trimRight(),
      language: _languageOf(element),
    );
  }
}
