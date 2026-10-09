# COMP-16: Разметка

supersedes: [COMP-15](obsolete/COMP-15-MARKDOWN.md)

Текст в разметке Markdown: условие задачи и текст статьи рисуются одним и тем
же компонентом и выглядят одинаково. Заголовки, абзацы, списки, таблицы,
цитаты, участки и блоки кода, картинки, ссылки и ссылки на статьи `[[slug]]`.

## Варианты

Один.

## Состояния

- Обычное; текст выделяется и копируется одной областью вместе с текстом
  экрана вокруг — её задаёт экран: через абзацы, списки, таблицы, цитаты и
  блоки кода.
- Ссылка на известную статью — название статьи ссылкой; нажатие открывает
  статью.
- `[[slug]]` статьи, которой нет в словаре заголовков, — сам slug обычным
  текстом; внутри участков и блоков кода `[[slug]]` остаётся как есть.
- Обычная ссылка выглядит так же, как ссылка на статью; нажатие ничего не
  делает.

## Размеры и токены

- Абзац и пункты списка — `bodyMedium`; заголовки первого–четвёртого уровня —
  `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`: стили из
  `AppTypography.textTheme` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#text-theme).
- Между блоками — `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md).
- Ссылка — цветом `AppColors.accent` с подчёркиванием того же цвета — [TOKEN-7](TOKEN-7-COLOR.md#accent).
- Участок кода в абзаце — шрифтом кода `AppTypography.code` — [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#code), мельче основного кода, на фоне `AppColors.codeBackground` — [TOKEN-7](TOKEN-7-COLOR.md#code-background); его размер задан в виджете, токена у него нет.
- Блок кода — [COMP-11](COMP-11-CODE-BLOCK.md).
- Цитата — фон `AppColors.surface` — [TOKEN-7](TOKEN-7-COLOR.md#surface), полоса слева цветом `AppColors.accent` — [TOKEN-7](TOKEN-7-COLOR.md#accent), скругление `AppRadius.sm` — [TOKEN-4](TOKEN-4-RADIUS.md#sm), отступ внутри `AppSpacing.md` — [TOKEN-3](TOKEN-3-SPACING.md#md); толщина полосы задана в виджете, токена у неё нет.
- Таблица — рамка цветом `AppColors.border` — [TOKEN-7](TOKEN-7-COLOR.md#border), отступ в ячейке `AppSpacing.sm` — [TOKEN-3](TOKEN-3-SPACING.md#sm); черта — линия того же цвета.
- Картинки условия — из хранилища файлов проекта.
