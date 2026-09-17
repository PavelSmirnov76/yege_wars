-- =============================================================================
-- ЭТАП 2, миграция 2/3: row level security и привилегии.
-- Принцип: чтение — по политикам RLS, все изменения — только через RPC
-- (security definer функции обходят RLS как владелец таблиц).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Включаем RLS на всех пяти таблицах.
-- ---------------------------------------------------------------------------
alter table public.profiles     enable row level security;
alter table public.tasks        enable row level security;
alter table public.task_answers enable row level security;
alter table public.submissions  enable row level security;
alter table public.app_settings enable row level security;

-- ---------------------------------------------------------------------------
-- Вспомогательные функции для политик.
-- is_admin() нужна политикам уже здесь, поэтому объявляется в этой миграции;
-- в миграции функций она пересоздаётся через create or replace без изменений.
-- ---------------------------------------------------------------------------

-- Является ли текущий пользователь администратором.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
      from public.profiles p
     where p.id = auth.uid()
       and p.role = 'admin'
  );
$$;

-- Есть ли у текущего пользователя верная попытка по задаче.
-- Вынесено в security definer функцию, потому что подзапрос к submissions
-- внутри политики самой submissions вызвал бы бесконечную рекурсию RLS.
create or replace function public.has_solved_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
      from public.submissions s
     where s.task_id = p_task_id
       and s.user_id = auth.uid()
       and s.is_correct
  );
$$;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.has_solved_task(uuid) from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.has_solved_task(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- profiles: чтение всем вошедшим (нужны username авторов решений).
-- Политик insert/update/delete нет: изменения только триггером и RPC.
-- ---------------------------------------------------------------------------
create policy profiles_select on public.profiles
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- tasks: студенты видят только опубликованные, админ видит и управляет всеми
-- прямо через API (политика all).
-- ---------------------------------------------------------------------------
create policy tasks_select on public.tasks
  for select
  to authenticated
  using (is_published = true or public.is_admin());

create policy tasks_admin_all on public.tasks
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- task_answers: ни одной политики — таблица полностью закрыта от клиентов.
-- Дополнительно отзываем привилегии (двойная защита);
-- эталон админ получает только через RPC admin_get_task_answer.
-- ---------------------------------------------------------------------------
revoke all on table public.task_answers from anon, authenticated;

-- ---------------------------------------------------------------------------
-- submissions: своя попытка, либо админ, либо чужое опубликованное решение
-- задачи, которую читающий сам верно решил.
-- Записи только через RPC: политик insert/update/delete нет + revoke.
-- ---------------------------------------------------------------------------
create policy submissions_select on public.submissions
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin()
    or (is_published = true and public.has_solved_task(task_id))
  );

revoke insert, update, delete on table public.submissions from anon, authenticated;

-- ---------------------------------------------------------------------------
-- app_settings: читать могут все вошедшие, менять — только админ.
-- insert/delete закрыты (набор ключей фиксируется миграциями).
-- ---------------------------------------------------------------------------
create policy app_settings_select on public.app_settings
  for select
  to authenticated
  using (true);

create policy app_settings_admin_update on public.app_settings
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Привилегии на таблицы.
-- anon не имеет доступа ни к одной таблице public (регистрация и вход идут
-- через auth, единственная нужная anon функция — is_registration_open).
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon;

-- Явные grant'ы для authenticated — чтобы схема одинаково работала и на
-- Supabase (там свои default privileges), и на голом PostgreSQL с шимом.
grant usage on schema public to anon, authenticated;
grant select on table public.profiles to authenticated;
grant select, insert, update, delete on table public.tasks to authenticated;
grant select on table public.submissions to authenticated;
grant select, update on table public.app_settings to authenticated;
