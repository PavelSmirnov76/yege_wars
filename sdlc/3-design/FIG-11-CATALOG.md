# FIG-11: Каталог

**Основание:** [UC-14](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md).

## Раскладка

Заголовок «Каталог». Под ним поле «Поиск по названию» со значком лупы, ряд
чипов номеров «№ N» с прокруткой вбок, ниже — чипы сложности и состояния
решения с переносом строк и кнопка «Сбросить фильтры». Ниже — список во всю
ширину: заголовки групп «Задание N» и «Без номера» и карточки задач. Пока
каталог загружается — индикатор по центру. Раскладка одна на любой ширине,
навигация — [COMP-4](design-system/COMP-4-NAVIGATION.md).

## Состояния

- [UC-14-P-01](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-01) — группы и карточки задач.
- [UC-14-P-02](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-02) — выбранные чипы подсвечены, видна «Сбросить
  фильтры».
- [UC-14-P-03](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-03) — вместо списка текст по центру: «Задач пока
  нет» или «По этим условиям задач нет».
- [UC-14-P-04](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-04) — вместо списка сообщение об ошибке и
  «Повторить».

## Тексты

| Ключ l10n | Текст |
|---|---|
| `navCatalog` | Каталог |
| `catalogSearchHint` | Поиск по названию |
| `referenceEgeNumber` | № {number} |
| `difficultyEasy` | Простая |
| `difficultyMedium` | Средняя |
| `difficultyHard` | Сложная |
| `progressSolved` | Решено |
| `progressAttempted` | Есть попытки |
| `progressNotStarted` | Не начата |
| `catalogResetFilters` | Сбросить фильтры |
| `catalogEgeGroup` | Задание {number} |
| `catalogEgeGroupNone` | Без номера |
| `catalogSolvedPercent` | Решили {percent}% |
| `catalogNoAttempts` | Ещё никто не решал |
| `catalogEmpty` | Задач пока нет |
| `catalogEmptyFiltered` | По этим условиям задач нет |
| `commonRetry` | Повторить |
| `errorUnexpected` | Что-то пошло не так. Попробуйте ещё раз. |

Текст ошибки загрузки приходит не из l10n, а из обработки ошибок; общий текст —
`errorUnexpected`.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md), [COMP-5](design-system/COMP-5-PROBLEM-CARD.md), [COMP-6](design-system/COMP-6-DIFFICULTY-BADGE.md), [COMP-7](design-system/COMP-7-PROGRESS-BADGE.md), [COMP-12](design-system/COMP-12-ERROR-RETRY.md).
