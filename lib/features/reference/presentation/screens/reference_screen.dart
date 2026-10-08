import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_card.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_filters_bar.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';

/// Раздел «Справочник»: список статей с поиском и фильтрами.
///
/// Реализует UC-25.
class ReferenceScreen extends ConsumerStatefulWidget {
  /// Создаёт экран справочника.
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> {
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
      ref.read(articleFilterControllerProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final articles = ref.watch(articlesProvider);
    final filter = ref.watch(articleFilterControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReference)),
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
                    hintText: l10n.referenceSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const ArticleFiltersBar(),
              ],
            ),
          ),
          Expanded(
            child: switch (articles) {
              AsyncError(:final error) => ReferenceErrorView(
                error: error,
                onRetry: () => ref.invalidate(articlesProvider),
              ),
              AsyncData(:final value) when value.isEmpty => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    filter.isEmpty
                        ? l10n.referenceEmpty
                        : l10n.referenceEmptyFiltered,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              AsyncData(:final value) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final brief = value[index];
                  return ArticleCard(
                    brief: brief,
                    onTap: () => context.goNamed(
                      AppRoutes.referenceArticleName,
                      pathParameters: {AppRoutes.slugParam: brief.slug},
                    ),
                  );
                },
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
