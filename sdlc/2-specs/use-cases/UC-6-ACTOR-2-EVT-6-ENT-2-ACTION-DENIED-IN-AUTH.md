# UC-6: Действие администратора без роли

**Основание:** [R12](../../0-vibes/prd/PRD.md#r12), [BT-3](../../1-business-tasks/planning/BT-3-PLANNING-ROLE-ACCESS.md), [MOD-1](../modules/MOD-1-AUTH.md).

**Актор, событие, сущность:** [ACTOR-2](../actors/ACTOR-2-USER-IN-AUTH.md), [EVT-6](../events/EVT-6-ADMIN-ACTION-CALLED-IN-AUTH.md), [ENT-2](../entities/ENT-2-PROFILE-IN-AUTH.md).

## Триггер

Вошедший вызывает RPC `admin_*` через API.

## Предусловия

У пользователя роль `student`.

## Пути

### <a id="uc-6-p-01"></a>UC-6-P-01 — не администратор

База отвечает `[forbidden] Доступно только администратору.`; данные не меняются.

**Исход:** UC-6-O-01 — отказ

## Постусловия

Изменений нет.
