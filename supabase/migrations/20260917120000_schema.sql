-- =============================================================================
-- ЭТАП 2, миграция 1/3: расширения, таблицы, индексы, триггеры регистрации.
-- Совместимость: Supabase (PostgreSQL 17) и локальный PostgreSQL 17 с шимом auth.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Расширения. pgcrypto ставим в отдельную схему extensions (как в Supabase);
-- gen_random_uuid() берётся из ядра PostgreSQL и расширения не требует.
-- ---------------------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Таблица app_settings: настройки приложения в виде ключ/значение (jsonb).
-- Создаётся первой: её читает триггер check_registration_open на auth.users.
-- ---------------------------------------------------------------------------
create table if not exists public.app_settings (
  key   text primary key,
  value jsonb not null
);

comment on table  public.app_settings       is 'Настройки приложения (ключ/значение).';
comment on column public.app_settings.key   is 'Ключ настройки, например registration_open.';
comment on column public.app_settings.value is 'Значение настройки в формате jsonb.';

-- Стартовые значения настроек (повторный запуск миграции их не перезапишет).
insert into public.app_settings (key, value) values
  ('registration_open',      'true'::jsonb),
  ('submissions_per_minute', '10'::jsonb)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Таблица profiles: профиль пользователя, 1:1 с auth.users.
-- Строки создаются только триггером handle_new_user, роль меняется через RPC.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text not null unique,
  role       text not null default 'student' check (role in ('student', 'admin')),
  created_at timestamptz not null default now()
);

comment on table  public.profiles            is 'Профили пользователей (1:1 с auth.users).';
comment on column public.profiles.id         is 'id пользователя из auth.users.';
comment on column public.profiles.username   is 'Логин: 3–20 символов, латиница, цифры, подчёркивание.';
comment on column public.profiles.role       is 'Роль: student (по умолчанию) или admin.';
comment on column public.profiles.created_at is 'Дата регистрации.';

-- ---------------------------------------------------------------------------
-- Таблица tasks: задачи ЕГЭ по информатике.
-- ---------------------------------------------------------------------------
create table if not exists public.tasks (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  ege_number    smallint not null check (ege_number between 2 and 27),
  title         text not null,
  statement_md  text not null,
  difficulty    smallint not null check (difficulty between 1 and 3),
  answer_format text not null check (answer_format in ('single', 'pair', 'multi', 'string')),
  files         jsonb not null default '[]'::jsonb,
  tags          text[] not null default '{}',
  is_published  boolean not null default false,
  source        text,
  created_at    timestamptz not null default now()
);

comment on table  public.tasks               is 'Задачи ЕГЭ по информатике.';
comment on column public.tasks.slug          is 'Человекочитаемый уникальный идентификатор задачи.';
comment on column public.tasks.ege_number    is 'Номер задания ЕГЭ (2–27).';
comment on column public.tasks.title         is 'Название задачи.';
comment on column public.tasks.statement_md  is 'Условие задачи в Markdown.';
comment on column public.tasks.difficulty    is 'Сложность: 1–3.';
comment on column public.tasks.answer_format is 'Формат ответа: single (одно число), pair (два числа), multi (несколько чисел), string (строка).';
comment on column public.tasks.files         is 'Прикреплённые файлы задачи (jsonb-массив описаний).';
comment on column public.tasks.tags          is 'Теги задачи.';
comment on column public.tasks.is_published  is 'Опубликована ли задача для студентов.';
comment on column public.tasks.source        is 'Источник задачи (сборник, сайт и т.п.).';
comment on column public.tasks.created_at    is 'Дата создания.';

-- ---------------------------------------------------------------------------
-- Таблица task_answers: эталонные ответы. Хранится отдельно от tasks,
-- чтобы RLS полностью закрывала эталоны от клиентов (см. миграцию RLS).
-- ---------------------------------------------------------------------------
create table if not exists public.task_answers (
  task_id uuid primary key references public.tasks (id) on delete cascade,
  answer  text not null
);

comment on table  public.task_answers         is 'Эталонные ответы к задачам (закрыты от клиентов).';
comment on column public.task_answers.task_id is 'id задачи.';
comment on column public.task_answers.answer  is 'Эталонный ответ в исходном виде.';

-- ---------------------------------------------------------------------------
-- Таблица submissions: попытки решения. Вставка только через RPC submit_solution.
-- ---------------------------------------------------------------------------
create table if not exists public.submissions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  task_id      uuid not null references public.tasks (id) on delete cascade,
  code         text not null,
  answer       text not null,
  is_correct   boolean not null,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  -- Публиковать можно только верное решение.
  check (is_published = false or is_correct = true)
);

comment on table  public.submissions              is 'Попытки решения задач.';
comment on column public.submissions.user_id      is 'Автор попытки.';
comment on column public.submissions.task_id      is 'Задача.';
comment on column public.submissions.code         is 'Код решения (текст программы).';
comment on column public.submissions.answer       is 'Ответ пользователя в исходном виде.';
comment on column public.submissions.is_correct   is 'Верна ли попытка (сравнение с эталоном при отправке).';
comment on column public.submissions.is_published is 'Опубликовано ли решение для других решивших.';
comment on column public.submissions.published_at is 'Момент публикации решения (null, если снято с публикации).';
comment on column public.submissions.created_at   is 'Момент отправки попытки.';

-- ---------------------------------------------------------------------------
-- Индексы.
-- ---------------------------------------------------------------------------
create index if not exists submissions_user_id_task_id_idx      on public.submissions (user_id, task_id);
create index if not exists submissions_task_id_is_published_idx on public.submissions (task_id, is_published);
create index if not exists submissions_created_at_idx           on public.submissions (created_at desc);
create index if not exists tasks_ege_number_idx                 on public.tasks (ege_number);

-- ---------------------------------------------------------------------------
-- Триггер check_registration_open: запрет регистрации, когда она закрыта.
-- Срабатывает до вставки в auth.users.
-- ---------------------------------------------------------------------------
create or replace function public.check_registration_open()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  -- Настройки нет или она true — регистрация открыта.
  if not coalesce(
    (select (value #>> '{}')::boolean
       from public.app_settings
      where key = 'registration_open'),
    true
  ) then
    raise exception '[registration_closed] Регистрация закрыта администратором.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_registration_open on auth.users;
create trigger trg_check_registration_open
  before insert on auth.users
  for each row
  execute function public.check_registration_open();

-- ---------------------------------------------------------------------------
-- Триггер handle_new_user: создание профиля при регистрации.
-- Логин берётся из raw_user_meta_data->>'username' и валидируется.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_username text;
begin
  v_username := new.raw_user_meta_data ->> 'username';

  if v_username is null or v_username !~ '^[A-Za-z0-9_]{3,20}$' then
    raise exception '[invalid_username] Логин должен содержать от 3 до 20 символов: латинские буквы, цифры или подчёркивание.';
  end if;

  begin
    insert into public.profiles (id, username)
    values (new.id, v_username);
  exception
    when unique_violation then
      raise exception '[username_taken] Логин «%» уже занят, выберите другой.', v_username;
  end;

  return new;
end;
$$;

drop trigger if exists trg_handle_new_user on auth.users;
create trigger trg_handle_new_user
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
