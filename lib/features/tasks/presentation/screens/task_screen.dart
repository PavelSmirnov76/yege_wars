import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_breakpoints.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/markdown/app_markdown.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/editor/presentation/controllers/draft_controller.dart';
import 'package:yege_wars/features/editor/presentation/widgets/editor_panel.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';
import 'package:yege_wars/features/submissions/presentation/controllers/submissions_controllers.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/solutions_list.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_detail.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/ege_group_label.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/difficulty_badge.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_files_panel.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_help_panel.dart';

/// Страница задачи: условие, файлы данных и справка.
///
/// Редактор кода с запуском и отправкой ответа, свои попытки и решения
/// других — тоже здесь, вкладками: на широком экране код — справа от
/// условия во вкладке «Задача», на узком — своей вкладкой. Черновик кода
/// грузится вместе с задачей: пока нет обоих, страница не открыта, а сбой
/// любого — сообщение с «Повторить» вместо страницы.
///
/// Реализует UC-15, UC-28, UC-31, UC-34, UC-35 и UC-40.
class TaskScreen extends ConsumerWidget {
  /// Создаёт страницу задачи с идентификатором [slug].
  const TaskScreen({required this.slug, super.key});

  /// Идентификатор задачи.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final task = ref.watch(taskProvider(slug));
    // Черновик ищется по id задачи — он известен, когда пришла задача.
    final taskId = task.value?.brief.id;
    final draft = taskId == null
        ? null
        : ref.watch(draftControllerProvider(taskId));
    final error = switch ((task, draft)) {
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => error,
      _ => null,
    };
    final loaded = switch ((task, draft)) {
      (AsyncData(:final value), AsyncData()) => value,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loaded?.brief.title ?? l10n.navCatalog,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: switch ((error, loaded)) {
        (final Object error, _) => ReferenceErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(taskProvider(slug));
            if (taskId != null) {
              ref.invalidate(draftControllerProvider(taskId));
            }
          },
        ),
        (_, final TaskDetail task) => _TaskBody(task: task),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Содержимое страницы: вкладки широкого или узкого экрана.
///
/// Это разные раскладки: при переходе через [AppBreakpoints.tabletMax]
/// вкладки строятся заново и открыта первая.
///
/// Переход в другой раздел страницу не снимает, а прячет: ветка навигации
/// остаётся в памяти с выключенным `TickerMode`. В этот момент черновик
/// записывается сразу — это уход со страницы.
class _TaskBody extends ConsumerStatefulWidget {
  const _TaskBody({required this.task});

  final TaskDetail task;

  @override
  ConsumerState<_TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends ConsumerState<_TaskBody> {
  bool _isVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = TickerMode.valuesOf(context).enabled;
    if (_isVisible && !isVisible) {
      ref.read(draftControllerProvider(widget.task.brief.id).notifier).flush();
    }
    _isVisible = isVisible;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.tabletMax) {
          return _TaskTabs(task: task);
        }
        return _TaskWideTabs(task: task);
      },
    );
  }
}

/// Вкладки для узкого экрана: код — своей вкладкой, вместе с попытками.
class _TaskTabs extends StatelessWidget {
  const _TaskTabs({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TaskTabView(
      tabs: [
        l10n.taskStatementTitle,
        l10n.editorTitle,
        l10n.solutionsTitle,
        l10n.taskHelpTitle,
        l10n.taskFilesTitle,
      ],
      pages: [
        _TaskTabPage(child: _TaskStatement(task: task)),
        _TaskTabPage(child: _TaskCode(task: task)),
        _TaskTabPage(child: _TaskSolutions(task: task)),
        _TaskTabPage(child: TaskHelpPanel(articles: task.articles)),
        _TaskTabPage(child: TaskFilesPanel(files: task.files)),
      ],
    );
  }
}

/// Вкладки для широкого экрана: во «Задаче» две колонки 3 : 2 — условие и
/// код без попыток, попытки — своей вкладкой.
class _TaskWideTabs extends StatelessWidget {
  const _TaskWideTabs({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TaskTabView(
      tabs: [
        l10n.taskTabProblem,
        l10n.taskTabAttempts,
        l10n.solutionsTitle,
        l10n.taskHelpTitle,
        l10n.taskFilesTitle,
      ],
      pages: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _TaskTabPage(child: _TaskStatement(task: task)),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: _TaskTabPage(child: EditorPanel(task: task)),
            ),
          ],
        ),
        _TaskTabPage(child: AttemptsList(taskId: task.brief.id)),
        _TaskTabPage(child: _TaskSolutions(task: task)),
        _TaskTabPage(child: TaskHelpPanel(articles: task.articles)),
        _TaskTabPage(child: TaskFilesPanel(files: task.files)),
      ],
    );
  }
}

/// Строка вкладок с прокруткой вбок и страницы под ней.
///
/// Невидимые страницы `TabBarView` снимает: при возврате на вкладку они
/// строятся заново.
class _TaskTabView extends StatelessWidget {
  const _TaskTabView({required this.tabs, required this.pages});

  final List<String> tabs;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final title in tabs) Tab(text: title)],
          ),
          Expanded(child: TabBarView(children: pages)),
        ],
      ),
    );
  }
}

/// Страница вкладки с прокруткой и отступом.
class _TaskTabPage extends StatelessWidget {
  const _TaskTabPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

/// Раздел «Код» узкого экрана: редактор с отправкой ответа и свои попытки.
class _TaskCode extends StatelessWidget {
  const _TaskCode({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorPanel(task: task),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.attemptsTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AttemptsList(taskId: task.brief.id),
      ],
    );
  }
}

/// Условие задачи со сведениями о ней.
///
/// Всё условие — одна область выделения: от «Задание N» до источника,
/// через абзацы, таблицы и блоки кода.
class _TaskStatement extends ConsumerWidget {
  const _TaskStatement({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titles = ref.watch(articleTitlesProvider).value ?? const {};

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                egeGroupLabel(l10n, task.brief.egeNumber),
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
      ),
    );
  }
}

/// Решения других учеников: открываются после своего верного ответа.
///
/// Решена ли задача, видно по своим попыткам. Если они не загрузились, это
/// неизвестно — вместо решений сообщение и «Повторить», а не «откроются
/// после верного ответа».
class _TaskSolutions extends ConsumerWidget {
  const _TaskSolutions({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(myAttemptsProvider(task.brief.id));
    if (attempts case AsyncError(:final error)) {
      return ReferenceErrorView(
        error: error,
        onRetry: () => ref.invalidate(myAttemptsProvider(task.brief.id)),
      );
    }
    final isSolved =
        attempts.value?.any((attempt) => attempt.isCorrect) ?? false;
    return SolutionsList(taskId: task.brief.id, isUnlocked: isSolved);
  }
}
