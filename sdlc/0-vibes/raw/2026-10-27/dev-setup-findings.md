# Находки при настройке тестового проекта yege_wars_dev (2026-10-27)

Тестовый проект собран по `docs/SUPABASE_SETUP.md` и контентной цепочке
`tools/` (решение 50); схема совпадает с боевой (таблицы, функции, политики,
бакет, права `anon` — сверено чтением на обоих).

1. **Content API не создаёт новые задачи — на боевом тоже.**
   `tools/import_repo_tasks.py --slug e24-longest-run` упал с
   `[http_error] permission denied for function ensure_task_has_theme`.
   Причина: `trg_tasks_have_theme` — отложенный constraint-триггер
   (`deferrable initially deferred`, `20260921100000_fipi_schema.sql`); он
   срабатывает при коммите, вне `security definer`-функции
   `admin_upsert_task`, от роли `authenticated`, а
   `20261006100000_revoke_excess_privileges.sql` отнял у неё `execute` на
   `ensure_task_has_theme(uuid)` в расчёте, что служебные функции вызываются
   от владельца. Права на боевом те же (проверено чтением:
   `has_function_privilege('authenticated', …) = false`). Ученики не
   задеты: вставка задачи — только контентная работа; обновления (ответы,
   публикация) триггер не задевают — поэтому 139 заданий 2026-10-07
   опубликовались. Тот же отложенный путь может быть у
   `task_theme_guard_delete` (снятие последней темы) — не проверялось.
   Путь: проход и задание (миграция); на тестовом проекте задача
   `e24-longest-run` перенесена с боевого данными от владельца базы.
