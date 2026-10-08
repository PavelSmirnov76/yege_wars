# UC-24: Запись попытки через API

**Основание:** [R30](../../0-vibes/prd/PRD.md#r30), [BT-11](../../1-business-tasks/planning/BT-11-PLANNING-ANSWER-CHECK.md), [MOD-6](../modules/MOD-6-SUBMISSION.md).

**Актор, событие, сущность:** [ACTOR-4](../actors/ACTOR-4-STUDENT-IN-SUBMISSION.md), [EVT-19](../events/EVT-19-ATTEMPT-WRITTEN-IN-SUBMISSION.md), [ENT-11](../entities/ENT-11-ATTEMPT-IN-SUBMISSION.md).

## Триггер

Вошедший вставляет, меняет или удаляет строку `submissions` через API.

## Предусловия

Нет.

## Пути

### <a id="uc-24-p-01"></a>UC-24-P-01 — отказ

База отвечает `permission denied`. Попытку создаёт только `submit_solution`,
публикацию меняет только `set_solution_published`.

**Исход:** UC-24-O-01 — отказ

## Постусловия

Изменений нет.
