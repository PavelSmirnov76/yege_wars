# COMP-14: Карточка статьи

Строка справочника: название, под ним описание, ниже — сведения о статье
([COMP-13](COMP-13-ARTICLE-META.md)) и до трёх тегов чипами.

## Варианты

Один.

## Состояния

- Обычное; у статьи без тегов строки тегов нет.
- Нажатие — отклик карточки и переход на страницу статьи.

## Размеры и токены

- Отступ между карточками: `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md).
- Отступ внутри: `AppSpacing.lg` — [TOKEN-3](TOKEN-3-SPACING.md#lg); между названием и описанием — `AppSpacing.xs` — [TOKEN-3](TOKEN-3-SPACING.md#xs); перед сведениями — `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md); перед тегами — `AppSpacing.sm` — [TOKEN-3](TOKEN-3-SPACING.md#sm); между тегами — `AppSpacing.xs` — [TOKEN-3](TOKEN-3-SPACING.md#xs).
- Название — `titleMedium`, описание — `bodyMedium` цветом `AppColors.textSecondary`: стили из `AppTypography.textTheme` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#text-theme), цвет — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#text-secondary).
- Фон, рамка и скругление — из темы карточек: `AppColors.surface` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#surface), `AppColors.border` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#border), `AppRadius.lg` — [TOKEN-4](TOKEN-4-RADIUS.md#lg).
