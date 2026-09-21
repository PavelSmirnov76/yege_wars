-- =============================================================================
-- ИМПОРТ БАНКА ФИПИ, миграция 1/3: темы как основная ось навигации.
--
-- Тема перестаёт быть строкой в tasks.tags и становится сущностью: у задания
-- есть темы, у темы — статья справочника, справка задания выводится через
-- темы. Заодно tasks получают поля, которых требует выгрузка банка: номер
-- задания становится необязательным, появляется происхождение fipi, ссылка
-- на родительское задание и признаки неполного условия и дубля.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- themes: кодификатор КЭС (45 тем ФИПИ) плюс служебная тема «Без темы».
-- Сами 45 строк заливает импорт: они берутся из выгрузки, а не пишутся руками.
-- ---------------------------------------------------------------------------
create table if not exists public.themes (
  code          text primary key
    constraint themes_code_check check (code ~ '^([0-9]+\.[0-9]+|none)$'),
  title         text not null,
  section_code  text not null,
  section_title text not null,
  level         text,
  sort_order    smallint not null default 0
);

comment on table  public.themes               is 'Темы кодификатора КЭС: основная ось навигации по заданиям.';
comment on column public.themes.code          is 'Код КЭС: 1.1 … 4.6, либо служебное none.';
comment on column public.themes.section_code  is 'Код раздела кодификатора: 1…4, у служебной темы none.';
comment on column public.themes.level         is 'Уровень изучения: БУ, УУ или «БУ, УУ»; у служебной темы пусто.';
comment on column public.themes.sort_order    is 'Порядок показа: служебная тема идёт последней.';

-- Служебная тема: без неё задания, которым ФИПИ не проставил КЭС,
-- выпали бы из навигации по темам.
insert into public.themes (code, title, section_code, section_title, level, sort_order)
values ('none', 'Без темы', 'none', 'Без темы', null, 999)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- task_themes: какие темы у задания. Первая по sort_order считается основной.
-- ---------------------------------------------------------------------------
create table if not exists public.task_themes (
  task_id    uuid not null references public.tasks (id) on delete cascade,
  theme_code text not null references public.themes (code),
  sort_order smallint not null default 0,
  primary key (task_id, theme_code)
);

comment on table  public.task_themes            is 'Связь «задание — тема кодификатора».';
comment on column public.task_themes.sort_order is 'Порядок тем задания; 0 — основная тема.';

create index if not exists task_themes_theme_idx
  on public.task_themes (theme_code);

-- ---------------------------------------------------------------------------
-- «У каждого задания есть хотя бы одна тема» — по построению, а не вручную.
--
-- Проверка отложена до конца транзакции: импорт вставляет задания и темы
-- разными командами, и в середине транзакции задание законно остаётся без
-- темы. Если к концу транзакции тем так и нет, ставится служебная none.
-- ---------------------------------------------------------------------------
create or replace function public.ensure_task_has_theme(p_task_id uuid)
returns void
language plpgsql
as $$
begin
  -- Задачу могли удалить в той же транзакции — тогда проверять нечего.
  if not exists (select 1 from public.tasks t where t.id = p_task_id) then
    return;
  end if;
  if exists (select 1 from public.task_themes tt where tt.task_id = p_task_id) then
    return;
  end if;
  insert into public.task_themes (task_id, theme_code, sort_order)
  values (p_task_id, 'none', 0)
  on conflict do nothing;
end;
$$;

comment on function public.ensure_task_has_theme(uuid) is
  'Ставит заданию служебную тему none, если к концу транзакции тем не осталось.';

-- Новое задание к концу транзакции обязано иметь тему.
create or replace function public.task_theme_guard_insert()
returns trigger
language plpgsql
as $$
begin
  perform public.ensure_task_has_theme(new.id);
  return null;
end;
$$;

-- Последнюю тему у задания снять нельзя: вместо неё встанет none.
create or replace function public.task_theme_guard_delete()
returns trigger
language plpgsql
as $$
begin
  perform public.ensure_task_has_theme(old.task_id);
  return null;
end;
$$;

drop trigger if exists trg_tasks_have_theme on public.tasks;
create constraint trigger trg_tasks_have_theme
  after insert on public.tasks
  deferrable initially deferred
  for each row
  execute function public.task_theme_guard_insert();

drop trigger if exists trg_task_themes_keep_theme on public.task_themes;
create constraint trigger trg_task_themes_keep_theme
  after delete on public.task_themes
  deferrable initially deferred
  for each row
  execute function public.task_theme_guard_delete();

-- ---------------------------------------------------------------------------
-- Статья справочника привязывается к теме один к одному.
-- ---------------------------------------------------------------------------
alter table public.reference_articles
  add column if not exists theme_code text
    references public.themes (code);

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.reference_articles'::regclass
       and conname = 'reference_articles_theme_code_key'
  ) then
    alter table public.reference_articles
      add constraint reference_articles_theme_code_key unique (theme_code);
  end if;
end;
$$;

comment on column public.reference_articles.theme_code is
  'Тема кодификатора, которую объясняет статья. Одна статья — одна тема.';

-- ---------------------------------------------------------------------------
-- tasks: поля банка ФИПИ.
-- ---------------------------------------------------------------------------

-- Номер задания в КИМ банк не публикует: у 457 заданий его нет вовсе.
alter table public.tasks alter column ege_number drop not null;

alter table public.tasks
  add column if not exists ege_number_source text,
  add column if not exists fipi_id text,
  add column if not exists fipi_short_id text,
  add column if not exists parent_task_id uuid references public.tasks (id),
  add column if not exists condition_incomplete boolean not null default false,
  add column if not exists duplicate_of uuid references public.tasks (id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.tasks'::regclass
       and conname = 'tasks_ege_number_source_check'
  ) then
    alter table public.tasks
      add constraint tasks_ege_number_source_check
        check (ege_number_source in ('fipi-spec-2026', 'manual'));
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.tasks'::regclass
       and conname = 'tasks_fipi_id_key'
  ) then
    alter table public.tasks add constraint tasks_fipi_id_key unique (fipi_id);
  end if;
end;
$$;

comment on column public.tasks.ege_number is
  'Номер задания в КИМ; null, если задание к актуальной структуре КИМ не отнесено.';
comment on column public.tasks.ege_number_source is
  'Откуда номер: fipi-spec-2026 — восстановлен по спецификации ЕГЭ-2026, '
  'manual — проставлен вручную.';
comment on column public.tasks.fipi_id is
  'Идентификатор задания в открытом банке ФИПИ (32-символьный GUID).';
comment on column public.tasks.fipi_short_id is
  'Шифр задания, который показывает сайт банка, например 48F84F.';
comment on column public.tasks.parent_task_id is
  'Задание с общим условием: задания 20 и 21 ссылаются на условие задания 19.';
comment on column public.tasks.condition_incomplete is
  'Условие неполное: родительское задание найти не удалось. Не публиковать.';
comment on column public.tasks.duplicate_of is
  'Задание полностью повторяет другое: разметка условия и вложения совпадают.';

-- Происхождение: к человеку и агенту добавляется банк ФИПИ.
do $$
declare
  v_name text;
begin
  select conname into v_name
    from pg_constraint
   where conrelid = 'public.tasks'::regclass
     and contype = 'c'
     and pg_get_constraintdef(oid) like '%origin%';
  if v_name is not null then
    execute format('alter table public.tasks drop constraint %I', v_name);
  end if;
end;
$$;

alter table public.tasks
  add constraint tasks_origin_check check (origin in ('human', 'ai', 'fipi'));

comment on column public.tasks.origin is
  'human — создано человеком, ai — сгенерировано агентом, fipi — импорт банка ФИПИ.';

create index if not exists tasks_fipi_id_idx on public.tasks (fipi_id);
create index if not exists tasks_parent_idx on public.tasks (parent_task_id);

-- ---------------------------------------------------------------------------
-- task_files: вложения банка лежат в Supabase Storage, а не в базе.
--
-- Текстовые файлы собственных задач по-прежнему хранятся в content: так они
-- попадают в дамп при бэкапе. Вложения ФИПИ — 405 МБ архивов, таблиц и
-- картинок — в колонку text не помещаются ни по типу, ни по размеру,
-- поэтому у файла появляется адрес в Storage.
-- ---------------------------------------------------------------------------
alter table public.task_files alter column content drop not null;

alter table public.task_files
  add column if not exists storage_bucket text,
  add column if not exists storage_path text,
  add column if not exists content_type text,
  add column if not exists source_url text,
  add column if not exists kind text not null default 'file';

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.task_files'::regclass
       and conname = 'task_files_kind_check'
  ) then
    alter table public.task_files
      add constraint task_files_kind_check check (kind in ('file', 'image'));
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.task_files'::regclass
       and conname = 'task_files_body_check'
  ) then
    alter table public.task_files
      add constraint task_files_body_check
        check (content is not null or storage_path is not null);
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.task_files'::regclass
       and conname = 'task_files_storage_check'
  ) then
    alter table public.task_files
      add constraint task_files_storage_check
        check ((storage_bucket is null) = (storage_path is null));
  end if;
end;
$$;

comment on column public.task_files.content        is 'Содержимое текстового файла; null, если файл лежит в Storage.';
comment on column public.task_files.storage_bucket is 'Бакет Supabase Storage, где лежит файл.';
comment on column public.task_files.storage_path   is 'Путь к файлу внутри бакета.';
comment on column public.task_files.content_type   is 'MIME-тип файла для отдачи браузеру.';
comment on column public.task_files.source_url     is 'Откуда файл взят: адрес на сайте ФИПИ.';
comment on column public.task_files.kind           is 'file — вложение задания, image — картинка условия.';

-- Размер больше не вычисляемая колонка: у файла в Storage содержимого в базе
-- нет, а размер знать надо. Для файлов в базе его по-прежнему считает база.
alter table public.task_files drop column if exists size_bytes;
alter table public.task_files
  add column if not exists size_bytes int not null default 0;

create or replace function public.task_files_set_size()
returns trigger
language plpgsql
as $$
begin
  if new.content is not null then
    new.size_bytes := octet_length(new.content);
  else
    new.size_bytes := greatest(coalesce(new.size_bytes, 0), 0);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_task_files_set_size on public.task_files;
create trigger trg_task_files_set_size
  before insert or update on public.task_files
  for each row
  execute function public.task_files_set_size();

comment on column public.task_files.size_bytes is
  'Размер в байтах: для файла в базе считается сам, для файла в Storage приходит с импортом.';

-- ---------------------------------------------------------------------------
-- task_articles: справка задания, выведенная через темы.
--
-- Ручные связи из task_references остаются: они нужны, когда админ хочет
-- привязать к задаче статью, которой по теме не полагается.
-- ---------------------------------------------------------------------------
create or replace view public.task_articles with (security_invoker = on) as
  select tt.task_id,
         a.id as article_id,
         a.slug,
         a.title,
         a.summary,
         tt.theme_code,
         tt.sort_order
    from public.task_themes tt
    join public.reference_articles a on a.theme_code = tt.theme_code;

comment on view public.task_articles is
  'Статьи справочника, которые полагаются заданию по его темам.';

-- ---------------------------------------------------------------------------
-- Бакет Storage для вложений банка.
--
-- Схема storage есть только в Supabase; на локальном PostgreSQL, где гоняются
-- RLS-тесты и проверка импорта, её нет, поэтому блок условный.
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    insert into storage.buckets (id, name, public)
    values ('task-assets', 'task-assets', true)
    on conflict (id) do nothing;
  end if;
end;
$$;
