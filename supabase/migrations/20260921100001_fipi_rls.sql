-- =============================================================================
-- ИМПОРТ БАНКА ФИПИ, миграция 2/3: права доступа к темам и вложениям.
-- Принцип прежний: чтение — по политикам RLS, запись — только через RPC.
-- =============================================================================

alter table public.themes      enable row level security;
alter table public.task_themes enable row level security;

-- ---------------------------------------------------------------------------
-- themes: кодификатор — справочные данные, скрывать в нём нечего.
-- ---------------------------------------------------------------------------
create policy themes_select on public.themes
  for select
  to authenticated
  using (true);

grant select on table public.themes to authenticated;

-- ---------------------------------------------------------------------------
-- task_themes: связь видна вместе с заданием.
-- ---------------------------------------------------------------------------
create policy task_themes_select on public.task_themes
  for select
  to authenticated
  using (public.is_task_visible(task_id));

grant select on table public.task_themes to authenticated;

-- ---------------------------------------------------------------------------
-- task_articles: представление с security_invoker, поэтому строки отбирают
-- политики task_themes и reference_articles.
-- ---------------------------------------------------------------------------
grant select on table public.task_articles to authenticated;

-- ---------------------------------------------------------------------------
-- Прямых изменений контента по-прежнему нет ни у кого.
-- ---------------------------------------------------------------------------
revoke insert, update, delete on table public.themes      from anon, authenticated;
revoke insert, update, delete on table public.task_themes from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Вложения в Storage: бакет публичный на чтение (материалы банка ФИПИ и так
-- открыты, ответов в них нет), запись — только администратору.
-- Схема storage существует только в Supabase, поэтому блок условный.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_namespace where nspname = 'storage') then
    return;
  end if;

  if not exists (
    select 1 from pg_policies
     where schemaname = 'storage' and tablename = 'objects'
       and policyname = 'task_assets_admin_write'
  ) then
    execute $policy$
      create policy task_assets_admin_write on storage.objects
        for insert to authenticated
        with check (bucket_id = 'task-assets' and public.is_admin())
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
     where schemaname = 'storage' and tablename = 'objects'
       and policyname = 'task_assets_admin_update'
  ) then
    execute $policy$
      create policy task_assets_admin_update on storage.objects
        for update to authenticated
        using (bucket_id = 'task-assets' and public.is_admin())
        with check (bucket_id = 'task-assets' and public.is_admin())
    $policy$;
  end if;

  if not exists (
    select 1 from pg_policies
     where schemaname = 'storage' and tablename = 'objects'
       and policyname = 'task_assets_admin_delete'
  ) then
    execute $policy$
      create policy task_assets_admin_delete on storage.objects
        for delete to authenticated
        using (bucket_id = 'task-assets' and public.is_admin())
    $policy$;
  end if;
end;
$$;

-- anon не имеет доступа ни к одной таблице public (включая новые).
revoke all on all tables in schema public from anon;
