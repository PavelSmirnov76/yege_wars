# COMP-9: Консоль

Вывод программы и сообщения об ошибках.

## Варианты

Один.

## Состояния

- **Пустая** — «Здесь появится вывод программы» цветом `AppColors.textDisabled` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#text-disabled).
- **Вывод** — текст программы моноширинным шрифтом; его можно выделить и
  скопировать, длинный — прокручивается.
- **Ошибка** — трассировка или причина сбоя среды после вывода, цветом
  `AppColors.danger` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#danger).

## Размеры и токены

- Высота — не меньше 120 — константа компонента, своего токена нет.
- Шрифт: `AppTypography.code` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#code).
- Фон: `AppColors.codeBackground` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#code-background); рамка — `AppColors.border` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#border).
- Отступ внутри: `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md); скругление — `AppRadius.md` — [TOKEN-4](TOKEN-4-RADIUS.md#md).
