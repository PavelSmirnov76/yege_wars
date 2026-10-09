# COMP-8: Поле кода

Многострочное поле кода на Python с подсветкой.

## Варианты

Один.

## Состояния

- **Пустое** — заглушка «# Твоё решение на Python» цветом `AppColors.textDisabled` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#text-disabled).
- **С кодом** — подсветка: ключевые слова, встроенные функции, строки, числа
  и комментарии — своими цветами `AppColors.codeKeyword`, `codeBuiltin`,
  `codeString`, `codeNumber`, `codeComment` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#code-keyword); остальное — `AppColors.textPrimary` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#text-primary).
- **Фокус** — рамка темы полей ввода. Ctrl/Cmd+Enter запускает программу.

## Размеры и токены

- Высота — от 10 строк, дальше растёт с текстом — константа компонента.
- Шрифт: `AppTypography.code` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#code).
- Фон: `AppColors.codeBackground` — [TOKEN-1](obsolete/TOKEN-1-COLOR.md#code-background).
- Отступ внутри: `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md); скругление — `AppRadius.md` — [TOKEN-4](TOKEN-4-RADIUS.md#md).
