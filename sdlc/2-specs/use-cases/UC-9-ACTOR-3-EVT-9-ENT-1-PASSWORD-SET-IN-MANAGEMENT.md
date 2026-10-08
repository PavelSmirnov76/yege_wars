# UC-9: Задать пароль пользователю

**Основание:** [R14](../../0-vibes/prd/PRD.md#r14), [BT-4](../../1-business-tasks/planning/BT-4-PLANNING-ACCOUNT-MANAGEMENT.md), [MOD-2](../modules/MOD-2-MANAGEMENT.md).

**Актор, событие, сущность:** [ACTOR-3](../actors/ACTOR-3-ADMIN-IN-MANAGEMENT.md), [EVT-9](../events/EVT-9-PASSWORD-RESET-IN-MANAGEMENT.md), [ENT-1](../entities/ENT-1-ACCOUNT-IN-AUTH.md).

## Триггер

Администратор вызывает `admin_reset_password(p_user_id, p_new_password)` — экрана нет.

## Предусловия

Вызывающий — администратор; иначе — [UC-6](UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md).

## Пути

### <a id="uc-9-p-01"></a>UC-9-P-01 — пароль задан

Пароль учётной записи заменяется новым; пользователь входит с ним.

**Исход:** UC-9-O-01 — пароль задан

### <a id="uc-9-p-02"></a>UC-9-P-02 — пароль короче 8 символов

База отвечает `[weak_password]`.

**Исход:** UC-9-O-02 — отказ: слабый пароль

### <a id="uc-9-p-03"></a>UC-9-P-03 — пользователя нет

База отвечает `[user_not_found]`.

**Исход:** UC-9-O-03 — отказ: пользователь не найден

## Постусловия

—
