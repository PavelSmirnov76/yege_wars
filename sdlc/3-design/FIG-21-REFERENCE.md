# FIG-21: Справочник

supersedes: [FIG-17](obsolete/FIG-17-REFERENCE.md)

**Основание:** [UC-39](../2-specs/use-cases/UC-39-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md).

## Раскладка

Заголовок — «Справочник». Навигация — [COMP-4](design-system/COMP-4-NAVIGATION.md),
выбран пункт «Справочник». Раскладка одна для любой ширины экрана.

Сверху, с отступами `AppSpacing.lg` по бокам — [TOKEN-3](design-system/TOKEN-3-SPACING.md#lg):
поле поиска с иконкой лупы, под ним панель отбора — между ними `AppSpacing.md`
— [TOKEN-3](design-system/TOKEN-3-SPACING.md#md). Панель отбора сверху вниз:
чипы уровня и кнопка «Сбросить фильтры» в одной строке с переносом; строка
чипов номеров «№ N» с прокруткой вбок; чипы разделов кодификатора — номер и
название раздела — с переносом. Между чипами и строками панели —
`AppSpacing.sm` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#sm).

Ниже, во всю ширину, — список карточек статей [COMP-14](design-system/COMP-14-ARTICLE-CARD.md)
с прокруткой; поле поиска и панель отбора остаются на месте.

## Состояния

- [UC-39-P-01](../2-specs/use-cases/UC-39-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-39-p-01) — список карточек; нажатие на карточку открывает страницу статьи.
- [UC-39-P-02](../2-specs/use-cases/UC-39-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-39-p-02) — выбранные чипы отмечены; пока задано хоть одно условие, рядом с чипами уровня — «Сбросить фильтры»; если значения фильтров не загрузились — только чипы уровня.
- [UC-39-P-03](../2-specs/use-cases/UC-39-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-39-p-03) — вместо списка по центру, с отступом `AppSpacing.xl` — [TOKEN-3](design-system/TOKEN-3-SPACING.md#xl), цветом `AppColors.textSecondary` — [TOKEN-7](design-system/TOKEN-7-COLOR.md#text-secondary): «В справочнике пока нет статей» или «По этим условиям ничего не нашлось».
- [UC-39-P-04](../2-specs/use-cases/UC-39-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-39-p-04) — вместо списка по центру — [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с текстом ошибки.

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
| `referenceSection1` | 1 · Цифровая грамотность |
| `referenceSection2` | 2 · Теоретические основы информатики |
| `referenceSection3` | 3 · Алгоритмы и программирование |
| `referenceSection4` | 4 · Информационные технологии |
| `referenceReadingMinutes` | {minutes} мин |
| `referenceEmpty` | В справочнике пока нет статей |
| `referenceEmptyFiltered` | По этим условиям ничего не нашлось |
| `commonRetry` | Повторить |
| `errorUnexpected` | Что-то пошло не так. Попробуйте ещё раз. |

`referenceSection1`…`referenceSection4` — новые ключи: подпись чипа раздела
кодификатора по его номеру. Чипы тегов на карточках подписаны самими тегами
статей.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md), [COMP-12](design-system/COMP-12-ERROR-RETRY.md), [COMP-13](design-system/COMP-13-ARTICLE-META.md), [COMP-14](design-system/COMP-14-ARTICLE-CARD.md).
