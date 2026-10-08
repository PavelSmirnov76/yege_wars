# UC-4: Профиль

**Основание:** [R10](../../0-vibes/prd/PRD.md#r10), [BT-2](../../1-business-tasks/planning/BT-2-PLANNING-SIGN-IN.md), [MOD-1](../modules/MOD-1-AUTH.md).

**Актор, событие, сущность:** [ACTOR-2](../actors/ACTOR-2-USER-IN-AUTH.md), [EVT-4](../events/EVT-4-PROFILE-OPENED-IN-AUTH.md), [ENT-2](../entities/ENT-2-PROFILE-IN-AUTH.md).

## Триггер

Пользователь открывает экран профиля.

## Предусловия

Пользователь вошёл.

## Пути

### <a id="uc-4-p-01"></a>UC-4-P-01 — профиль

Экран показывает логин и роль: «ученик» или «администратор».

**Исход:** UC-4-O-01 — профиль показан

## Постусловия

Изменений нет.
