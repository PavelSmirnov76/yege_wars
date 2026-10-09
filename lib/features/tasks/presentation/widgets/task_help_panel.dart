import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_card.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_article_link.dart';

/// Справка к задаче: статьи справочника, сначала главные по теме.
///
/// Статьи не склеиваются в один текст: каждая — самостоятельный мини-урок,
/// который используется многими задачами. Карточка — та же, что в
/// справочнике; главная и сопутствующая выглядят одинаково, порядок
/// приходит готовым.
///
/// Реализует UC-40.
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
          ArticleCard(
            brief: link.article,
            onTap: () => context.goNamed(
              AppRoutes.referenceArticleName,
              pathParameters: {AppRoutes.slugParam: link.article.slug},
            ),
          ),
      ],
    );
  }
}
