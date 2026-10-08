import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_meta.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';

/// Справка к задаче: статьи справочника, сначала главные по теме.
///
/// Статьи не склеиваются в один текст: каждая — самостоятельный мини-урок,
/// который используется многими задачами.
///
/// Реализует UC-27.
class TaskHelpPanel extends StatelessWidget {
  /// Создаёт панель для связей [articles].
  const TaskHelpPanel({required this.articles, super.key});

  /// Связи задачи со статьями.
  final List<TaskArticleLink> articles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (articles.isEmpty) {
      return Text(
        l10n.taskHelpEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final link in articles)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ExpansionTile(
              initiallyExpanded: link.isPrimary,
              title: Text(link.article.title),
              subtitle: Text(
                link.article.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ArticleMeta(link.article),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => context.goNamed(
                      AppRoutes.referenceArticleName,
                      pathParameters: {
                        AppRoutes.slugParam: link.article.slug,
                      },
                    ),
                    child: Text(l10n.taskHelpTitle),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
