# Находки приёмки TASK-4

2026-10-08, приёмка [ACC-TASK-4-01](../../../6-eval/acceptance/ACC-TASK-4-01.md)
сдачи [RESULT-TASK-4-01](../../../5-results/RESULT-TASK-4-01.md).

1. Части путей с метками тестами не проверены. Исполнитель спросил, дописать
   ли их сверх минимума задания; владелец ответил, что лишнего делать не
   нужно. Перечень — в сдаче, «Найдено вне задания», п. 1. Два пункта
   проверены по коду:
   - [UC-23-P-01](../../../2-specs/use-cases/UC-23-ACTOR-4-EVT-18-ENT-10-ANSWER-KEY-DENIED-IN-SUBMISSION.md#uc-23-p-01):
     в `tasks_public` колонок `reference_solution` и `answer_explanation`
     нет (определение представления —
     `supabase/migrations/20260917130000_content_schema.sql`). Отказ
     администратору в этих колонках даёт та же роль `authenticated`, что и
     ученику, — её проверяет матрица прав, раздел (п). Отдельных проверок нет;
   - [UC-17-P-03](../../../2-specs/use-cases/obsolete/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-03):
     «Остановлено» на экране не проверено. Подделка `FakePythonRuntime` на
     «Стоп» по умолчанию отдаёт исход `finished`; исход `stopped` тест может
     задать сам через `runResult`.
2. Код, который реализует пути среза, без метки: провайдеры `task` (UC-15) и
   `catalogEgeNumbers` (UC-14, `catalog_controllers.dart`); методы
   `TasksRepositoryImpl.getTask`, `SupabaseTasksRemoteDataSource.fetchTask` и
   `fetchFiles` — UC-15, а у классов метка `UC-14`; `SubmissionsRepositoryImpl`
   и `SupabaseSubmissionsRemoteDataSource` — ещё UC-20…UC-22, а у классов
   метка `UC-19`; `runStatusLabel` (`console_view.dart`) — строки состояния
   UC-17. Причина — таблица «Где реализованы UC в клиенте» задания TASK-4
   неполна; исполнитель метил строго по ней. «Где реализован» у этих UC не
   пуст. Источник — сдача; подтверждено по коду.
3. Устаревший doc-комментарий `_TaskSidePanels`
   (`lib/features/tasks/presentation/screens/task_screen.dart`): «Правая
   колонка широкого экрана: место редактора, справка и файлы». В колонке —
   сам редактор, решения других, справка и файлы. В находку 14 прохода 5
   (`as-built-problems.md`) не попал. Источник — сдача; подтверждено по коду.
