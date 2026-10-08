# UC-3: Выход

**Основание:** [R8](../../0-vibes/prd/PRD.md#r8), [BT-2](../../1-business-tasks/planning/BT-2-PLANNING-SIGN-IN.md), [MOD-1](../modules/MOD-1-AUTH.md).

**Актор, событие, сущность:** [ACTOR-2](../actors/ACTOR-2-USER-IN-AUTH.md), [EVT-3](../events/EVT-3-SIGNED-OUT-IN-AUTH.md), [ENT-3](../entities/ENT-3-SESSION-IN-AUTH.md).

## Триггер

Пользователь нажимает «Выйти» в профиле.

## Предусловия

Пользователь вошёл.

## Пути

### <a id="uc-3-p-01"></a>UC-3-P-01 — выход

Сессия завершается, приложение показывает экран входа.

**Исход:** UC-3-O-01 — сессия завершена

## Постусловия

Состояние входа — «не вошёл».
