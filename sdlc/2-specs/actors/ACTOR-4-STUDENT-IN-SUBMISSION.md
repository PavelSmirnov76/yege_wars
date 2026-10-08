# ACTOR-4: Ученик

**Кто:** пользователь с ролью `student`, который решает задачи. Администратор
решает так же; его попытки не входят в долю решивших.

**Цели:** найти задачу, решить её программой в браузере, получить вердикт,
посмотреть чужие решения.

**Права:** читает опубликованные задачи и их файлы; отправляет ответы через
`submit_solution` — не чаще 10 в минуту; публикует свои верные попытки и
снимает их с публикации через `set_solution_published`; читает свои попытки и
чужие опубликованные решения задач, которые сам решил верно. Не читает
эталонный ответ, эталонное решение и разбор; не пишет в `submissions` напрямую.

**Сущности:** [ENT-6](../entities/ENT-6-PROBLEM-IN-CATALOG.md), [ENT-7](../entities/ENT-7-FILE-IN-CATALOG.md), [ENT-8](../entities/obsolete/ENT-8-CODE-IN-EDITOR.md), [ENT-9](../entities/ENT-9-RUN-IN-EDITOR.md), [ENT-10](../entities/ENT-10-ANSWER-KEY-IN-SUBMISSION.md), [ENT-11](../entities/ENT-11-ATTEMPT-IN-SUBMISSION.md). **События:** [EVT-11](../events/EVT-11-CATALOG-OPENED-IN-CATALOG.md), [EVT-12](../events/EVT-12-PROBLEM-OPENED-IN-CATALOG.md), [EVT-13](../events/obsolete/EVT-13-CODE-EDITED-IN-EDITOR.md), [EVT-14](../events/EVT-14-RUN-STARTED-IN-EDITOR.md), [EVT-15](../events/EVT-15-OUTPUT-TAKEN-IN-SUBMISSION.md), [EVT-16](../events/EVT-16-ANSWER-SUBMITTED-IN-SUBMISSION.md), [EVT-17](../events/EVT-17-PUBLICATION-SWITCHED-IN-SUBMISSION.md), [EVT-18](../events/EVT-18-ANSWER-KEY-REQUESTED-IN-SUBMISSION.md), [EVT-19](../events/EVT-19-ATTEMPT-WRITTEN-IN-SUBMISSION.md).
