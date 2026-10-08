# COMP-10: Вердикт

Крупная плашка во всю ширину: значок и текст вердикта.

## Варианты

- **Верно** — галочка и «Верно!» цветом `AppColors.success` — [TOKEN-1](TOKEN-1-COLOR.md#success).
- **Неверно** — крестик и «Неверно. Попробуй ещё раз» цветом `AppColors.danger` — [TOKEN-1](TOKEN-1-COLOR.md#danger).

## Состояния

Обычное.

## Размеры и токены

- Рамка — цветом варианта; подложка — тот же цвет с прозрачностью 0,15 —
  константа компонента.
- Значок 28 — константа компонента, своего токена нет.
- Текст: `titleMedium` из `AppTypography.textTheme` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#text-theme), цветом варианта.
- Отступ внутри: `AppSpacing.lg` — [TOKEN-3](TOKEN-3-SPACING.md#lg); между значком и текстом — `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md); скругление — `AppRadius.md` — [TOKEN-4](TOKEN-4-RADIUS.md#md).
