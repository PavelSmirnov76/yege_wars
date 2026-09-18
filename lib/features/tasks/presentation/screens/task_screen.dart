import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_breakpoints.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/widgets/editor_panel.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/solutions_list.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/difficulty_badge.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_help_panel.dart';

/// Страница задачи: условие, файлы данных и справка.
///
/// Редактор кода, запуск и отправка ответа появятся на следующих этапах;
/// место под них уже выделено правой колонкой на широком экране.
class TaskScreen extends ConsumerWidget {
  /// Создаёт страницу задачи с идентификатором [slug].
  const TaskScreen({required this.slug, super.key});

  /// Идентификатор задачи.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final task = ref.watch(taskProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          task.value?.brief.title ?? l10n.navCatalog,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: switch (task) {
        AsyncError(:final error) => ReferenceErrorView(
          error: error,
          onRetry: () => ref.invalidate(taskProvider(slug)),
        ),
        AsyncData(:final value) => _TaskBody(task: value),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Содержимое страницы: на широком экране две колонки, на узком — вкладки.
class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.tabletMax) {
          return _TaskTabs(task: task);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _TaskStatement(task: task),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _TaskSidePanels(task: task),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Вкладки для узкого экрана.
class _TaskTabs extends StatelessWidget {
  const _TaskTabs({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.taskStatementTitle),
              Tab(text: l10n.editorTitle),
              Tab(text: l10n.solutionsTitle),
              Tab(text: l10n.taskHelpTitle),
              Tab(text: l10n.taskFilesTitle),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _TaskStatement(task: task),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: EditorPanel(task: task),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _TaskSolutions(task: task),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TaskHelpPanel(articles: task.articles),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TaskFilesPanel(files: task.files),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Условие задачи со сведениями о ней.
class _TaskStatement extends ConsumerWidget {
  const _TaskStatement({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titles = ref.watch(articleTitlesProvider).value ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.catalogEgeGroup(task.brief.egeNumber),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            DifficultyBadge(task.brief.difficulty),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (task.primaryArticles.isNotEmpty) ...[
          Text(
            l10n.taskHelpHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppMarkdown(
          data: task.statementMd,
          articleTitles: titles,
          onArticleTap: (slug) => context.goNamed(
            AppRoutes.referenceArticleName,
            pathParameters: {AppRoutes.slugParam: slug},
          ),
        ),
        if (task.source case final source? when source.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${l10n.taskSourceLabel}: $source',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Правая колонка широкого экрана: место редактора, справка и файлы.
class _TaskSidePanels extends StatelessWidget {
  const _TaskSidePanels({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.editorTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        EditorPanel(task: task),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.solutionsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _TaskSolutions(task: task),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.taskHelpTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TaskHelpPanel(articles: task.articles),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.taskFilesTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TaskFilesPanel(files: task.files),
      ],
    );
  }
}

/// Решения других учеников: открываются после своего верного ответа.
class _TaskSolutions extends ConsumerWidget {
  const _TaskSolutions({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(myAttemptsProvider(task.brief.id)).value;
    final isSolved = attempts?.any((attempt) => attempt.isCorrect) ?? false;
    return SolutionsList(taskId: task.brief.id, isUnlocked: isSolved);
  }
}
