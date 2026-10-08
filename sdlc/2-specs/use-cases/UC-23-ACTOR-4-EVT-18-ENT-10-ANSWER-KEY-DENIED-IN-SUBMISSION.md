# UC-23: Эталон через API

**Основание:** [R29](../../0-vibes/prd/PRD.md#r29), [BT-11](../../1-business-tasks/planning/BT-11-PLANNING-ANSWER-CHECK.md), [MOD-6](../modules/MOD-6-SUBMISSION.md).

**Актор, событие, сущность:** [ACTOR-4](../actors/ACTOR-4-STUDENT-IN-SUBMISSION.md), [EVT-18](../events/EVT-18-ANSWER-KEY-REQUESTED-IN-SUBMISSION.md), [ENT-10](../entities/ENT-10-ANSWER-KEY-IN-SUBMISSION.md).

## Триггер

Вошедший читает через API таблицу `task_answers` или колонки
`reference_solution` и `answer_explanation` таблицы `tasks`.

## Предусловия

Нет.

## Пути

### <a id="uc-23-p-01"></a>UC-23-P-01 — отказ

База отвечает `permission denied` — и ученику, и администратору. В
`tasks_public` этих полей нет. Эталонный ответ сравнивает с ответом
пользователя только `submit_solution`.

**Исход:** UC-23-O-01 — отказ

## Постусловия

Изменений нет.
