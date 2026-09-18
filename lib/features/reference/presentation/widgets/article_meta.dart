import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/reference/domain/entities/article_brief.dart';
import 'package:yege_wars/features/reference/presentation/widgets/article_level_label.dart';

/// Строка сведений о статье: уровень, время чтения и номера заданий.
class ArticleMeta extends StatelessWidget {
  /// Создаёт строку сведений для статьи [brief].
  const ArticleMeta(this.brief, {super.key});

  /// Размер иконок.
  static const double _iconSize = 14;

  /// Сколько номеров ЕГЭ показывать до сокращения.
  static const int _maxEgeNumbers = 4;

  /// Карточка статьи.
  final ArticleBrief brief;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    final numbers = brief.egeNumbers.take(_maxEgeNumbers).toList();
    final tail = brief.egeNumbers.length - numbers.length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(articleLevelLabel(brief.level, l10n), style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: _iconSize,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              l10n.referenceReadingMinutes(brief.readingMinutes),
              style: style,
            ),
          ],
        ),
        if (numbers.isNotEmpty)
          Text(
            [
              for (final number in numbers) l10n.referenceEgeNumber(number),
              if (tail > 0) '…',
            ].join(' '),
            style: style,
          ),
      ],
    );
  }
}
