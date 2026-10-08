# FIG-13: Справочник

**Основание:** [UC-25](../2-specs/use-cases/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md).

## Раскладка

Заголовок — «Справочник». Навигация — [COMP-4](design-system/COMP-4-NAVIGATION.md),
выбран пункт «Справочник». Раскладка одна для любой ширины экрана.

Сверху, с отступами `AppSpacing.lg` по бокам — [TOKEN-3](design-system/TOKEN-3-SPACING.md#lg):
поле поиска с иконкой лупы, под ним панель отбора — между ними `AppSpacing.md`
— [TOKEN-3](design-system/TOKEN-3-SPACING.md#md). Панель отбора сверху вниз:
чипы уровня и кнопка «Сбросить фильтры» в одной строке с переносом; строка
чипов номеров «№ N» с прокруткой вбок; чипы тегов с переносом. Между чипами и
строками панели — `AppSpacing.sm` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#sm).

Ниже, во всю ширину, — список карточек статей [COMP-14](design-system/COMP-14-ARTICLE-CARD.md)
с прокруткой; поле поиска и панель отбора остаются на месте.

## Состояния

- [UC-25-P-01](../2-specs/use-cases/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-01) — список карточек; нажатие на карточку открывает страницу статьи.
- [UC-25-P-02](../2-specs/use-cases/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-02) — выбранные чипы отмечены; пока задано хоть одно условие, рядом с чипами уровня — «Сбросить фильтры»; если значения фильтров не загрузились — только чипы уровня.
- [UC-25-P-03](../2-specs/use-cases/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-03) — вместо списка по центру, с отступом `AppSpacing.xl` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#xl), цветом `AppColors.textSecondary` — [TOKEN-1](design-system/TOKEN-1-COLOR.md#text-secondary): «В справочнике пока нет статей» или «По этим условиям ничего не нашлось».
- [UC-25-P-04](../2-specs/use-cases/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-04) — вместо списка индикатор загрузки по центру, пока идут повторы; затем [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с текстом ошибки.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `navReference` | Справочник |
| `referenceSearchHint` | Поиск по названию |
| `referenceLevelBasic` | Базовый |
| `referenceLevelMedium` | Средний |
| `referenceLevelAdvanced` | Продвинутый |
| `referenceResetFilters` | Сбросить фильтры |
| `referenceEgeNumber` | № {number} |
| `referenceReadingMinutes` | {minutes} мин |
| `referenceEmpty` | В справочнике пока нет статей |
| `referenceEmptyFiltered` | По этим условиям ничего не нашлось |
| `commonRetry` | Повторить |
| `errorUnexpected` | Что-то пошло не так. Попробуйте ещё раз. |

Чипы тегов подписаны самими тегами статей.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md), [COMP-12](design-system/COMP-12-ERROR-RETRY.md), [COMP-13](design-system/COMP-13-ARTICLE-META.md), [COMP-14](design-system/COMP-14-ARTICLE-CARD.md).
