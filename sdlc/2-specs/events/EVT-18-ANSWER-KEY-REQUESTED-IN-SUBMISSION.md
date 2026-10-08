# EVT-18: Запрошен эталон

**Сущность:** [ENT-10](../entities/ENT-10-ANSWER-KEY-IN-SUBMISSION.md).

- **Триггер:** вошедший читает через API таблицу `task_answers` или колонки
  `reference_solution` и `answer_explanation` таблицы `tasks`.
- **Переход:** изменений нет; база отвечает `permission denied`.
