-- =============================================================================
-- drafts: черновик кода ученика по задаче.
--
-- Одна строка на пользователя и задачу. Клиент пишет её upsert по ключу
-- (user_id, task_id) и удаляет напрямую, RPC нет. Строку читает, пишет и
-- удаляет только её автор — администратору чужие черновики тоже не видны;
-- записать можно только по задаче, которую автор видит. Код из одних
-- пробельных символов клиент не хранит, а удаляет строку. С пользователем
-- или задачей удаляется и черновик.
--
-- Реализует UC-31.
-- =============================================================================

create table public.drafts (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  task_id    uuid not null references public.tasks (id) on delete cascade,
  code       text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, task_id)
);

comment on table  public.drafts            is 'Черновики кода: одна строка на пользователя и задачу.';
comment on column public.drafts.user_id    is 'Автор черновика.';
comment on column public.drafts.task_id    is 'Задача.';
comment on column public.drafts.code       is 'Код из поля кода.';
comment on column public.drafts.updated_at is 'Время последней записи.';

-- Время перезаписи ставит база, а не клиент.
create trigger trg_drafts_touch_updated_at
  before update on public.drafts
  for each row
  execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS: только автор; писать — только по видимой задаче.
-- ---------------------------------------------------------------------------
alter table public.drafts enable row level security;

create policy drafts_select on public.drafts
  for select
  to authenticated
  using (user_id = auth.uid());

create policy drafts_insert on public.drafts
  for insert
  to authenticated
  with check (user_id = auth.uid() and public.is_task_visible(task_id));

create policy drafts_update on public.drafts
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.is_task_visible(task_id));

create policy drafts_delete on public.drafts
  for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Права. Supabase выдаёт anon и authenticated всё на новую таблицу: снимаем
-- и выдаём ровно задуманное. Upsert PostgREST — это insert … on conflict do
-- update: ему нужны insert, update и select.
-- ---------------------------------------------------------------------------
revoke all on table public.drafts from anon, authenticated;
grant select, insert, update, delete on table public.drafts to authenticated;
