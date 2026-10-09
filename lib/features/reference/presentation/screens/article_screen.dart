import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/domain/entities/reference_article.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_meta.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';

/// Страница статьи справочника.
///
/// Реализует UC-37 и UC-28.
class ArticleScreen extends ConsumerWidget {
  /// Создаёт страницу статьи с идентификатором [slug].
  const ArticleScreen({required this.slug, super.key});

  /// Максимальная ширина колонки текста: длинная строка читается плохо.
  static const double _maxContentWidth = 720;

  /// Идентификатор статьи.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final article = ref.watch(articleProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.value?.brief.title ?? l10n.navReference,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: switch (article) {
        AsyncError(:final error) => ReferenceErrorView(
          error: error,
          onRetry: () => ref.invalidate(articleProvider(slug)),
        ),
        AsyncData(:final value) => _ArticleBody(
          article: value,
          maxWidth: _maxContentWidth,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Содержимое статьи: заголовок, сведения, текст и теги.
class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({required this.article, required this.maxWidth});

  final ReferenceArticle article;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brief = article.brief;
    // Словарь заголовков нужен ссылкам [[slug]]; пока он грузится,
    // ссылки показываются обычным текстом.
    final titles = ref.watch(articleTitlesProvider).value ?? const {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(brief.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              ArticleMeta(brief),
              if (brief.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in brief.tags)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppMarkdown(
                data: article.contentMd,
                articleTitles: titles,
                onArticleTap: (slug) => context.goNamed(
                  AppRoutes.referenceArticleName,
                  pathParameters: {AppRoutes.slugParam: slug},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
