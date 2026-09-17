-- =============================================================================
-- ДОРАБОТКА 2, миграция 2/3: права доступа к контенту.
-- Принцип прежний: чтение — по политикам RLS, запись — только через RPC.
-- Новое: эталон решения и разбор ответа недоступны ученику даже на уровне
-- привилегий на колонки, а не только «потому что клиент их не запрашивает».
-- =============================================================================

alter table public.task_files         enable row level security;
alter table public.reference_articles enable row level security;
alter table public.task_references    enable row level security;
alter table public.audit_log          enable row level security;

-- ---------------------------------------------------------------------------
-- Вспомогательные функции для политик: доступна ли сущность читающему.
-- Security definer, чтобы политики не зависели от привилегий на колонки.
-- ---------------------------------------------------------------------------
create or replace function public.is_task_visible(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and (t.status = 'published' or public.is_admin())
  );
$$;

create or replace function public.is_article_visible(p_article_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
      from public.reference_articles a
     where a.id = p_article_id
       and (a.is_published or public.is_admin())
  );
$$;

revoke execute on function public.is_task_visible(uuid) from public, anon;
revoke execute on function public.is_article_visible(uuid) from public, anon;
grant execute on function public.is_task_visible(uuid) to authenticated;
grant execute on function public.is_article_visible(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- tasks: строки — по статусу, колонки — по привилегиям.
-- Прямая запись в таблицу закрыта всем: контент меняется только через
-- admin_* RPC, которые ведут журнал и проверяют payload.
-- ---------------------------------------------------------------------------
drop policy if exists tasks_select on public.tasks;
drop policy if exists tasks_admin_all on public.tasks;

create policy tasks_select on public.tasks
  for select
  to authenticated
  using (status = 'published' or public.is_admin());

revoke all on table public.tasks from anon, authenticated;

-- Колонки reference_solution и answer_explanation не выдаются никому:
-- админ получает их через admin_get_task.
grant select (
  id, slug, ege_number, title, statement_md, difficulty, answer_format,
  tags, status, source, origin, created_at, updated_at
) on table public.tasks to authenticated;

grant select on table public.tasks_public to authenticated;

-- ---------------------------------------------------------------------------
-- task_files: видны вместе с задачей, меняются только через RPC.
-- ---------------------------------------------------------------------------
create policy task_files_select on public.task_files
  for select
  to authenticated
  using (public.is_task_visible(task_id));

grant select on table public.task_files to authenticated;

-- ---------------------------------------------------------------------------
-- reference_articles: опубликованные статьи читают все вошедшие.
-- Ответов и решений в статьях нет, скрывать содержимое не нужно.
-- ---------------------------------------------------------------------------
create policy reference_articles_select on public.reference_articles
  for select
  to authenticated
  using (is_published or public.is_admin());

grant select on table public.reference_articles to authenticated;

-- ---------------------------------------------------------------------------
-- task_references: связь видна, если видны и задача, и статья.
-- ---------------------------------------------------------------------------
create policy task_references_select on public.task_references
  for select
  to authenticated
  using (
    public.is_task_visible(task_id) and public.is_article_visible(article_id)
  );

grant select on table public.task_references to authenticated;

-- ---------------------------------------------------------------------------
-- audit_log: читает только админ, пишут только security definer функции.
-- ---------------------------------------------------------------------------
create policy audit_log_select on public.audit_log
  for select
  to authenticated
  using (public.is_admin());

grant select on table public.audit_log to authenticated;

-- ---------------------------------------------------------------------------
-- Никаких прямых изменений контента: ни ученику, ни админу.
-- ---------------------------------------------------------------------------
revoke insert, update, delete on table public.task_files         from anon, authenticated;
revoke insert, update, delete on table public.reference_articles from anon, authenticated;
revoke insert, update, delete on table public.task_references    from anon, authenticated;
revoke insert, update, delete on table public.audit_log          from anon, authenticated;

-- anon не имеет доступа ни к одной таблице public (включая новые).
revoke all on all tables in schema public from anon;
