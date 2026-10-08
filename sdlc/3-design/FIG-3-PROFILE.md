# FIG-3: Профиль

**Основание:** [UC-4](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md), [UC-3](../2-specs/use-cases/UC-3-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md).

## Раскладка

Заголовок «Профиль», под ним иконка пользователя, логин крупным шрифтом,
строка роли, заглушка будущего раздела и кнопка «Выйти» с иконкой. Внизу или
сбоку — навигация.

## Состояния

- [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01) — логин и «Роль: Ученик» или «Роль: Администратор».
- [UC-3-P-01](../2-specs/use-cases/UC-3-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-3-p-01) — после «Выйти» открывается экран входа. Ошибка выхода — во
  всплывающем сообщении внизу.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `navProfile` | Профиль |
| `profileRoleLabel` | Роль |
| `profileRoleStudent` | Ученик |
| `profileRoleAdmin` | Администратор |
| `comingSoon` | Раздел в разработке |
| `profileSignOut` | Выйти |

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md).
