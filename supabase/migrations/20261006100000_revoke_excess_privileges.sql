-- =============================================================================
-- ПРАВА КЛИЕНТСКИХ РОЛЕЙ: снять всё, что выдали не миграции.
--
-- Supabase выдаёт anon, authenticated и service_role все права на каждый
-- новый объект, который postgres создаёт в public (pg_default_acl).
-- Миграции выдают нужное явно, но лишнее снимали не везде: у представлений
-- остались права на запись, у таблиц — TRUNCATE, REFERENCES, TRIGGER и
-- MAINTAIN, у последовательности audit_log_id_seq — всё. Функции, созданные
-- после 20260917120002, остались доступны PUBLIC.
--
-- Принцип: у объекта снимается всё, затем выдаётся ровно задуманное.
-- Полная матрица прав anon и authenticated закреплена тестом в rls_tests.sql,
-- раздел (п): новая миграция, забывшая снять лишнее, его не пройдёт.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Таблицы и представления: ученику только чтение (строки отбирает RLS),
-- администратору — ещё изменение настроек (политика app_settings_admin_update).
-- tasks и task_answers уже закрыты в 20260917130001 и 20260917120001.
-- ---------------------------------------------------------------------------
revoke all on table
  public.app_settings,
  public.audit_log,
  public.profiles,
  public.reference_articles,
  public.submissions,
  public.task_articles,
  public.task_files,
  public.task_references,
  public.task_themes,
  public.tasks_public,
  public.themes
  from anon, authenticated;

grant select on table
  public.app_settings,
  public.audit_log,
  public.profiles,
  public.reference_articles,
  public.submissions,
  public.task_articles,
  public.task_files,
  public.task_references,
  public.task_themes,
  public.tasks_public,
  public.themes
  to authenticated;

grant update on table public.app_settings to authenticated;

-- ---------------------------------------------------------------------------
-- Журнал пишут только security definer функции, счётчик клиенту не нужен.
-- ---------------------------------------------------------------------------
revoke all on sequence public.audit_log_id_seq from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Служебные функции: триггерные и вызываемые из других функций. Триггер
-- права EXECUTE у роли клиента не требует, security definer функции
-- вызывают их от владельца.
-- ---------------------------------------------------------------------------
revoke execute on function
  public.assert_content_admin(),
  public.check_registration_open(),
  public.handle_new_user(),
  public.ensure_task_has_theme(uuid),
  public.task_files_set_size(),
  public.task_theme_guard_delete(),
  public.task_theme_guard_insert(),
  public.touch_updated_at()
  from public, anon, authenticated;
