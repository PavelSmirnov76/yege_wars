# UC-7: Открыть или закрыть регистрацию

**Основание:** [R6](../../0-vibes/prd/PRD.md#r6), [R5](../../0-vibes/prd/PRD.md#r5), [BT-4](../../1-business-tasks/planning/BT-4-PLANNING-ACCOUNT-MANAGEMENT.md), [MOD-2](../modules/MOD-2-MANAGEMENT.md).

**Актор, событие, сущность:** [ACTOR-3](../actors/ACTOR-3-ADMIN-IN-MANAGEMENT.md), [EVT-7](../events/EVT-7-REGISTRATION-SWITCHED-IN-MANAGEMENT.md), [ENT-4](../entities/ENT-4-SETTINGS-IN-MANAGEMENT.md).

## Триггер

Меняют `registration_open` в `app_settings` через API — экрана нет.

## Предусловия

Нет.

## Пути

### <a id="uc-7-p-01"></a>UC-7-P-01 — администратор

Флаг меняется; экран регистрации и триггер регистрации следуют новому значению.

**Исход:** UC-7-O-01 — регистрация переключена

### <a id="uc-7-p-02"></a>UC-7-P-02 — не администратор

Изменение не применяется: запрос не падает, но меняет 0 строк.

**Исход:** UC-7-O-02 — флаг не изменён

## Постусловия

—
