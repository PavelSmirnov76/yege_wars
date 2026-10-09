import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/features/reference/presentation/controllers/reference_controllers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_level_label.dart';
import 'package:yege_wars/features/reference/presentation/widgets/codifier_section_label.dart';

/// Фильтры справочника: уровень, номер задания и раздел кодификатора.
///
/// Чип раздела отбирает статьи по тегу раздела — весь раздел; темы
/// кодификатора чипами не показываются.
///
/// Реализует UC-39.
class ArticleFiltersBar extends ConsumerWidget {
  /// Создаёт панель фильтров.
  const ArticleFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(articleFilterControllerProvider);
    final controller = ref.read(articleFilterControllerProvider.notifier);
    final facets = ref.watch(articleFacetsProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final level in ArticleLevel.values)
              FilterChip(
                label: Text(articleLevelLabel(level, l10n)),
                selected: filter.level == level,
                onSelected: (_) => controller.toggleLevel(level),
              ),
            if (!filter.isEmpty)
              TextButton(
                onPressed: controller.reset,
                child: Text(l10n.referenceResetFilters),
              ),
          ],
        ),
        if (facets != null && facets.egeNumbers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final number in facets.egeNumbers)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(l10n.referenceEgeNumber(number)),
                      selected: filter.egeNumber == number,
                      onSelected: (_) => controller.toggleEgeNumber(number),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (facets != null && facets.sections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final section in facets.sections)
                FilterChip(
                  label: Text(codifierSectionLabel(section, l10n)),
                  selected: filter.tag == section.tag,
                  onSelected: (_) => controller.toggleTag(section.tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
