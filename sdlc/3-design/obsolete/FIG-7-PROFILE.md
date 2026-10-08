> **Похоронен:** 2026-10-08
> **Почему:** состояния выхода — по путям UC-13 вместо похороненного UC-11
> **Заменён:** [FIG-10](../FIG-10-PROFILE.md)

# FIG-7: Профиль

supersedes: [FIG-3](FIG-3-PROFILE.md)

**Основание:** [UC-4](../../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md), [UC-11](../../2-specs/use-cases/obsolete/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md).

## Раскладка

Заголовок «Профиль», под ним иконка пользователя, логин крупным шрифтом,
строка роли, заглушка будущего раздела и кнопка «Выйти» с иконкой. Внизу или
сбоку — навигация.

## Состояния

- [UC-4-P-01](../../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01) — логин и «Роль: Ученик» или «Роль: Администратор».
- [UC-11-P-01](../../2-specs/use-cases/obsolete/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-01) — после «Выйти» открывается экран входа.
- [UC-11-P-02](../../2-specs/use-cases/obsolete/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-02) — ошибка выхода: сообщение внизу экрана, пользователь
  остаётся в профиле.
- [UC-11-P-03](../../2-specs/use-cases/obsolete/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-03) — выход в другой вкладке: эта вкладка переходит на экран
  входа.

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

[COMP-4](../design-system/COMP-4-NAVIGATION.md).
