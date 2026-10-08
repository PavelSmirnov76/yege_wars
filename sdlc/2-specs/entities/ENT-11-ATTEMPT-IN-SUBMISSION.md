# ENT-11: Попытка

**Модуль:** [MOD-6](../modules/MOD-6-SUBMISSION.md). **Профиль:** [ENT-2](ENT-2-PROFILE-IN-AUTH.md). **Задача:** [ENT-6](ENT-6-PROBLEM-IN-CATALOG.md). **Эталонный ответ:** [ENT-10](ENT-10-ANSWER-KEY-IN-SUBMISSION.md).

Таблица `submissions`.

| Поле | Тип | Правило |
|---|---|---|
| `id` | uuid | ключ |
| `user_id` | uuid | автор — профиль; удаляется вместе с ним |
| `task_id` | uuid | задача; удаляется вместе с ней |
| `code` | text | код на момент отправки |
| `answer` | text | ответ, как отправлен |
| `is_correct` | boolean | вердикт |
| `is_published` | boolean | опубликовано ли решение, по умолчанию `false` |
| `published_at` | timestamptz | время публикации; `null`, если не опубликовано |
| `created_at` | timestamptz | время отправки |

- Опубликовать можно только верную попытку:
  `check (is_published = false or is_correct = true)`.
- Создаёт попытку только `submit_solution(p_task_id, p_code, p_answer)` →
  `{is_correct, submission_id}`. Отказы без записи: `[not_authenticated]`,
  `[empty_answer]`, `[task_not_found]` — задача не опубликована, а вызывающий не
  администратор, `[rate_limit]` — за последнюю минуту уже
  `submissions_per_minute` попыток (ключ настроек
  [ENT-4](ENT-4-SETTINGS-IN-MANAGEMENT.md), по умолчанию 10).
- Сравнение — `normalize_answer` по формату задачи: края обрезаются от
  пробелов, пробельные последовательности сжимаются в один пробел. `single`,
  `pair`, `multi` — ровно одно, ровно два, одно и больше чисел; каждое
  приводится к каноническому виду: без ведущих нулей, `-0` — `0`, без
  незначащих нулей дробной части. `string` — как есть, с учётом регистра.
  Ответ, который не разобрался по формату, неверен.
- Публикацию меняет только `set_solution_published(p_submission_id,
  p_published)`: ставит или очищает `published_at`. Отказы: `[not_found]`,
  `[not_owner]` — чужая попытка, `[not_correct]` — неверная, `[bad_argument]`.
- Читает (политика `submissions_select`): автор — свои; администратор — все;
  остальные — чужие опубликованные по задаче, если у читающего есть своя
  верная попытка по ней (`has_solved_task`). Вставка, изменение и удаление
  через API отозваны.
- Состояние решения задачи — по своим попыткам: нет попыток — не начата, нет
  верной — есть попытки, есть верная — решено. Считает клиент.
