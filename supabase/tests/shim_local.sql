-- =============================================================================
-- ШИМ SUPABASE ДЛЯ ЛОКАЛЬНОГО «ГОЛОГО» PostgreSQL 17
--
-- Только для локального прогона RLS-тестов (supabase/tests/run_local.sh).
-- На реальный Supabase этот файл НЕ применяется: там роли, схема auth
-- и функция auth.uid() уже существуют.
--
-- Эмулируется ровно тот минимум, на который опираются миграции:
--   * роли anon, authenticated, service_role;
--   * схема auth с таблицей auth.users и функцией auth.uid();
--   * схема extensions с pgcrypto;
--   * схема tests с хелперами login/logout/signup для тестов.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Роли Supabase (nologin; создаём только если ещё нет)
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- Схема extensions + pgcrypto (так же, как это делают миграции; if not exists —
-- чтобы шим и миграции не конфликтовали)
-- -----------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- -----------------------------------------------------------------------------
-- Схема auth: таблица пользователей и auth.uid()
-- -----------------------------------------------------------------------------
create schema if not exists auth;

-- Минимальный аналог auth.users из Supabase — только колонки,
-- разрешённые контрактом совместимости.
create table if not exists auth.users (
  id                 uuid primary key default gen_random_uuid(),
  email              text unique,
  encrypted_password text,
  raw_user_meta_data jsonb not null default '{}',
  created_at         timestamptz not null default now()
);

-- auth.uid(): id текущего пользователя из GUC request.jwt.claims (ключ sub),
-- как в Supabase. Если GUC не выставлен или пуст — null.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
$$;

-- -----------------------------------------------------------------------------
-- Права на схемы (как в Supabase)
-- -----------------------------------------------------------------------------
grant usage on schema public     to anon, authenticated, service_role;
grant usage on schema auth       to anon, authenticated, service_role;
grant usage on schema extensions to anon, authenticated, service_role;

-- Читать auth.users напрямую роли не могут (как и в Supabase):
-- доступ к ней есть только у security definer функций.

-- -----------------------------------------------------------------------------
-- Схема tests: хелперы для тестового сценария
-- -----------------------------------------------------------------------------
create schema if not exists tests;

-- usage нужен и «залогиненным» ролям: tests.logout() вызывается под authenticated
grant usage on schema tests to anon, authenticated, service_role;

-- «Войти» пользователем: выставить JWT-claims c sub и переключить роль
-- на authenticated (эмуляция запроса от залогиненного пользователя).
create or replace function tests.login(p_user_id uuid)
returns void
language plpgsql
as $$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_user_id::text, 'role', 'authenticated')::text,
    false
  );
  -- эквивалент SET ROLE authenticated
  perform set_config('role', 'authenticated', false);
end;
$$;

-- «Выйти»: вернуть роль сессии (суперпользователь) и очистить claims.
create or replace function tests.logout()
returns void
language plpgsql
as $$
begin
  -- эквивалент RESET ROLE
  perform set_config('role', 'none', false);
  perform set_config('request.jwt.claims', '', false);
end;
$$;

-- Регистрация пользователя: insert в auth.users от суперпользователя
-- (эмуляция supabase auth.signUp; профиль создаёт триггер из миграций).
create or replace function tests.signup(p_username text)
returns uuid
language plpgsql
as $$
declare
  v_id uuid;
begin
  insert into auth.users (email, raw_user_meta_data)
  values (
    p_username || '@ege.local',
    jsonb_build_object('username', p_username)
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function tests.login(uuid) to anon, authenticated, service_role;
grant execute on function tests.logout()    to anon, authenticated, service_role;
