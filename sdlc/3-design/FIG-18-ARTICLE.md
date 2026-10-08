# FIG-18: Статья

supersedes: [FIG-14](obsolete/FIG-14-ARTICLE.md)

**Основание:** [UC-37](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md), [UC-28](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md).

## Раскладка

Заголовок — название статьи; пока статья загружается и при ошибке —
«Справочник». Навигация — [COMP-4](design-system/COMP-4-NAVIGATION.md), выбран
пункт «Справочник».

Статья — одной колонкой по центру с прокруткой, отступ `AppSpacing.lg` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#lg);
на широком экране колонка не растягивается на всю ширину — её предел задан в
виджете, токена у него нет. Сверху вниз: название — `headlineSmall` из
`AppTypography.textTheme` — [TOKEN-2](design-system/TOKEN-2-TYPOGRAPHY.md#text-theme);
сведения о статье [COMP-13](design-system/COMP-13-ARTICLE-META.md); все теги
чипами; текст статьи [COMP-15](design-system/COMP-15-MARKDOWN.md). Перед
сведениями и перед тегами — `AppSpacing.sm` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#sm),
между тегами — `AppSpacing.xs` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#xs),
перед текстом — `AppSpacing.lg` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#lg).

## Состояния

- [UC-37-P-01](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-01) — статья, как в раскладке.
- [UC-37-P-02](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-02) — по центру — [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с «Статья справочника не найдена.».
- [UC-37-P-03](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-03) — по центру — [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с текстом ошибки.
- [UC-28-P-01](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-01) — в тексте статьи название другой статьи ссылкой; нажатие открывает её здесь же, в разделе «Справочник».
- [UC-28-P-02](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-02) — на месте ссылки на статью — slug обычным текстом.
- [UC-28-P-03](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-03) — обычная ссылка выглядит ссылкой; нажатие ничего не делает.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `navReference` | Справочник |
| `referenceLevelBasic` | Базовый |
| `referenceLevelMedium` | Средний |
| `referenceLevelAdvanced` | Продвинутый |
| `referenceReadingMinutes` | {minutes} мин |
| `referenceEgeNumber` | № {number} |
| `commonRetry` | Повторить |
| `errorUnexpected` | Что-то пошло не так. Попробуйте ещё раз. |

«Статья справочника не найдена.» и тексты сбоев приходят не из l10n, а из
обработки ошибок. Чипы тегов подписаны самими тегами статьи.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md), [COMP-11](design-system/COMP-11-CODE-BLOCK.md), [COMP-12](design-system/COMP-12-ERROR-RETRY.md), [COMP-13](design-system/COMP-13-ARTICLE-META.md), [COMP-15](design-system/COMP-15-MARKDOWN.md).
