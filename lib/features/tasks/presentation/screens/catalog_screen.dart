import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';
import 'package:yege_wars/features/tasks/domain/entities/catalog_item.dart';
import 'package:yege_wars/features/tasks/presentation/controllers/catalog_controllers.dart';
import 'package:yege_wars/features/tasks/presentation/ege_group_label.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/catalog_filters_bar.dart';
import 'package:yege_wars/features/tasks/presentation/widgets/task_card.dart';

/// Каталог задач: поиск, фильтры и карточки, сгруппированные по номеру
/// задания ЕГЭ.
///
/// Реализует UC-14.
class CatalogScreen extends ConsumerStatefulWidget {
  /// Создаёт экран каталога.
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  /// Пауза после ввода, чтобы не дёргать базу на каждую букву.
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Откладывает применение строки поиска.
  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      ref.read(taskFilterControllerProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final catalog = ref.watch(catalogProvider);
    final filter = ref.watch(taskFilterControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCatalog)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: l10n.catalogSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const CatalogFiltersBar(),
              ],
            ),
          ),
          Expanded(
            child: switch (catalog) {
              AsyncError(:final error) => ReferenceErrorView(
                error: error,
                onRetry: () => ref.invalidate(catalogProvider),
              ),
              AsyncData(:final value) when value.isEmpty => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    filter.isEmpty
                        ? l10n.catalogEmpty
                        : l10n.catalogEmptyFiltered,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              AsyncData(:final value) => _CatalogList(items: value),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Список карточек с заголовками групп по номеру задания.
class _CatalogList extends StatelessWidget {
  const _CatalogList({required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Каталог приходит отсортированным по номеру задания, поэтому
        // заголовок группы рисуется на первой задаче нового номера.
        final isGroupStart =
            index == 0 ||
            items[index - 1].task.egeNumber != item.task.egeNumber;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isGroupStart) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  egeGroupLabel(l10n, item.task.egeNumber),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            TaskCard(
              item: item,
              onTap: () => context.goNamed(
                AppRoutes.taskName,
                pathParameters: {AppRoutes.slugParam: item.task.slug},
              ),
            ),
          ],
        );
      },
    );
  }
}
