-- =============================================================================
-- ДОРАБОТКА 2, миграция 1/3: источник истины по контенту — база.
-- Задачи получают статусы, эталонное решение и авторство; файлы задач
-- переезжают из репозитория в таблицу; появляется справочник статей,
-- связь «задача ↔ статья» и журнал действий администраторов.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- touch_updated_at: общий триггер для таблиц с updated_at.
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- tasks: статусы вместо булева флага, эталон решения и авторство.
-- ---------------------------------------------------------------------------
alter table public.tasks
  add column if not exists status text not null default 'draft'
    check (status in ('draft', 'review', 'published')),
  add column if not exists reference_solution text,
  add column if not exists answer_explanation text,
  add column if not exists created_by uuid
    references public.profiles (id) on delete set null,
  add column if not exists origin text not null default 'human'
    check (origin in ('human', 'ai')),
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists reference_verified_at timestamptz;

comment on column public.tasks.status is
  'draft — черновик, review — ждёт проверки человеком, published — видно ученикам.';
comment on column public.tasks.reference_solution is
  'Эталонное решение на Python. Ученикам не отдаётся никогда.';
comment on column public.tasks.answer_explanation is
  'Краткий разбор для администратора: как получен ответ.';
comment on column public.tasks.created_by is
  'Кто создал задачу: живой админ или сервисный аккаунт агента.';
comment on column public.tasks.origin is
  'human — создано человеком, ai — сгенерировано агентом.';
comment on column public.tasks.updated_at is 'Дата последнего изменения.';
comment on column public.tasks.reference_verified_at is
  'Когда эталон в последний раз проверяли: его вывод совпал с ответом. '
  'Без этой отметки задачу нельзя опубликовать; любое изменение задачи её снимает.';

-- Политики этапа 2 ссылаются на is_published; заново они создаются
-- в миграции прав доступа, поэтому здесь их просто снимаем.
drop policy if exists tasks_select on public.tasks;
drop policy if exists tasks_admin_all on public.tasks;

-- Переносим прежний флаг публикации в статус и убираем его.
update public.tasks
   set status = case when is_published then 'published' else 'draft' end
 where is_published is not null;

alter table public.tasks
  drop column if exists is_published,
  -- Список файлов заменила таблица task_files.
  drop column if exists files;

-- Номера заданий: доработка расширяет диапазон до 1–27.
alter table public.tasks drop constraint if exists tasks_ege_number_check;
alter table public.tasks
  add constraint tasks_ege_number_check check (ege_number between 1 and 27);

drop trigger if exists trg_tasks_touch_updated_at on public.tasks;
create trigger trg_tasks_touch_updated_at
  before update on public.tasks
  for each row
  execute function public.touch_updated_at();

create index if not exists tasks_status_idx on public.tasks (status);
create index if not exists tasks_ege_number_idx on public.tasks (ege_number);

-- ---------------------------------------------------------------------------
-- task_files: файлы данных задачи целиком в базе.
-- Все файлы КЕГЭ текстовые, поэтому Storage не нужен: так контент попадает
-- в один дамп при бэкапе и не зависит от внешнего хостинга.
-- ---------------------------------------------------------------------------
create table if not exists public.task_files (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks (id) on delete cascade,
  filename   text not null
    -- Только имя файла: без путей, пробелов и «..».
    constraint task_files_filename_check
      check (filename ~ '^[A-Za-z0-9_.-]{1,64}$' and filename !~ '\.\.'),
  content    text not null
    -- 4 МБ на файл; суммарный лимит на задачу проверяет RPC.
    constraint task_files_size_check check (octet_length(content) <= 4194304),
  size_bytes int generated always as (octet_length(content)) stored,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now(),
  unique (task_id, filename)
);

comment on table  public.task_files            is 'Файлы данных задачи (текст).';
comment on column public.task_files.filename   is 'Имя, под которым файл увидит Python: 24.txt, 27_A.txt.';
comment on column public.task_files.content    is 'Содержимое файла целиком.';
comment on column public.task_files.size_bytes is 'Размер в байтах, считается автоматически.';
comment on column public.task_files.sort_order is 'Порядок показа в интерфейсе.';

create index if not exists task_files_task_id_idx
  on public.task_files (task_id, sort_order);

-- ---------------------------------------------------------------------------
-- reference_articles: справочник мини-уроков.
-- Статья пишется один раз и привязывается ко многим задачам.
-- ---------------------------------------------------------------------------
create table if not exists public.reference_articles (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique
    constraint reference_articles_slug_check check (slug ~ '^[a-z0-9-]{3,64}$'),
  title           text not null,
  summary         text not null,
  content_md      text not null,
  ege_numbers     smallint[] not null default '{}',
  tags            text[] not null default '{}',
  level           smallint not null default 1 check (level between 1 and 3),
  reading_minutes smallint not null default 5 check (reading_minutes > 0),
  is_published    boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table  public.reference_articles                 is 'Статьи справочника (мини-уроки по приёмам).';
comment on column public.reference_articles.slug            is 'Человекочитаемый идентификатор, например regex-basics.';
comment on column public.reference_articles.summary         is 'Одно предложение для карточки в списке.';
comment on column public.reference_articles.ege_numbers     is 'Номера заданий ЕГЭ, где приём пригодится.';
comment on column public.reference_articles.level           is 'Уровень: 1 базовый, 2 средний, 3 продвинутый.';
comment on column public.reference_articles.reading_minutes is 'Оценка времени чтения в минутах.';

create index if not exists reference_articles_published_idx
  on public.reference_articles (is_published);

drop trigger if exists trg_reference_articles_touch_updated_at
  on public.reference_articles;
create trigger trg_reference_articles_touch_updated_at
  before update on public.reference_articles
  for each row
  execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- task_references: какие статьи справочника относятся к задаче.
-- ---------------------------------------------------------------------------
create table if not exists public.task_references (
  task_id    uuid not null references public.tasks (id) on delete cascade,
  article_id uuid not null
    references public.reference_articles (id) on delete cascade,
  relevance  text not null check (relevance in ('primary', 'related')),
  sort_order smallint not null default 0,
  primary key (task_id, article_id)
);

comment on table  public.task_references           is 'Связь «задача — статья справочника».';
comment on column public.task_references.relevance is 'primary — главная тема задачи, related — пригодится.';

create index if not exists task_references_article_idx
  on public.task_references (article_id);

-- ---------------------------------------------------------------------------
-- audit_log: кто и что менял в контенте.
-- Пишется только из security definer функций; служит ещё и счётчиком
-- частоты вызовов для ограничения записи.
-- ---------------------------------------------------------------------------
create table if not exists public.audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid references public.profiles (id) on delete set null,
  action      text not null,
  entity      text not null,
  entity_slug text,
  details     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

comment on table  public.audit_log             is 'Журнал действий администраторов и агента над контентом.';
comment on column public.audit_log.action      is 'Что сделали: upsert_task, delete_task, set_status и т.п.';
comment on column public.audit_log.entity      is 'Над чем: task или article.';
comment on column public.audit_log.entity_slug is 'slug задачи или статьи.';

create index if not exists audit_log_actor_created_idx
  on public.audit_log (actor_id, created_at desc);

-- ---------------------------------------------------------------------------
-- tasks_public: то, и только то, что видит ученик.
-- Эталон решения и разбор ответа в представление не входят вовсе, поэтому
-- получить их «случайным» запросом невозможно.
-- ---------------------------------------------------------------------------
create or replace view public.tasks_public with (security_invoker = on) as
  select t.id,
         t.slug,
         t.ege_number,
         t.title,
         t.statement_md,
         t.difficulty,
         t.answer_format,
         t.tags,
         t.source,
         t.origin,
         t.created_at,
         t.updated_at
    from public.tasks t
   where t.status = 'published';

-- Лимит частоты записи в контент (вызовы admin_* функций в минуту).
insert into public.app_settings (key, value) values
  ('content_writes_per_minute', '60'::jsonb)
on conflict (key) do nothing;

comment on view public.tasks_public is
  'Опубликованные задачи без эталона и разбора — единственный вход для учеников.';
