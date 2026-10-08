# UC-8: Назначить или снять роль администратора

**Основание:** [R13](../../0-vibes/prd/PRD.md#r13), [BT-4](../../1-business-tasks/planning/BT-4-PLANNING-ACCOUNT-MANAGEMENT.md), [MOD-2](../modules/MOD-2-MANAGEMENT.md).

**Актор, событие, сущность:** [ACTOR-3](../actors/ACTOR-3-ADMIN-IN-MANAGEMENT.md), [EVT-8](../events/EVT-8-ROLE-CHANGED-IN-MANAGEMENT.md), [ENT-2](../entities/ENT-2-PROFILE-IN-AUTH.md).

## Триггер

Администратор вызывает `admin_set_role(p_user_id, p_role)` — экрана нет.

## Предусловия

Вызывающий — администратор; иначе — [UC-6](UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md).

## Пути

### <a id="uc-8-p-01"></a>UC-8-P-01 — роль изменена

Роль пользователя становится `student` или `admin`.

**Исход:** UC-8-O-01 — роль изменена

### <a id="uc-8-p-02"></a>UC-8-P-02 — снять роль с себя

База отвечает `[self_demote]`; роль не меняется.

**Исход:** UC-8-O-02 — отказ: роль с себя не снимают

### <a id="uc-8-p-03"></a>UC-8-P-03 — недопустимая роль

База отвечает `[bad_role]`.

**Исход:** UC-8-O-03 — отказ: такой роли нет

### <a id="uc-8-p-04"></a>UC-8-P-04 — пользователя нет

База отвечает `[user_not_found]`.

**Исход:** UC-8-O-04 — отказ: пользователь не найден

## Постусловия

—
