-- =============================================================================
-- ДОРАБОТКА 2, миграция 3/3: Content API.
-- Контент пишется только этими функциями: одна задача — это запись в tasks,
-- эталонный ответ, файлы и связи со справочником, и всё это должно
-- появляться одной транзакцией. Функция = транзакция, поэтому при любой
-- ошибке в базе не остаётся полузадачи.
-- Все функции security definer и сами проверяют роль admin у auth.uid().
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Функции этапа 2, где булев флаг публикации заменён статусом.
-- ---------------------------------------------------------------------------
create or replace function public.submit_solution(
  p_task_id uuid,
  p_code    text,
  p_answer  text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid            uuid;
  v_format         text;
  v_task_published boolean;
  v_limit          int;
  v_recent         bigint;
  v_key            text;
  v_correct        boolean;
  v_submission_id  uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception '[not_authenticated] Требуется войти в систему.';
  end if;

  if p_answer is null or btrim(p_answer) = '' then
    raise exception '[empty_answer] Ответ не может быть пустым.';
  end if;

  select t.answer_format, t.status = 'published'
    into v_format, v_task_published
    from public.tasks t
   where t.id = p_task_id;

  -- Неопубликованную задачу может решать только админ; существование
  -- скрытой задачи студенту не раскрываем.
  if not found or not (v_task_published or public.is_admin()) then
    raise exception '[task_not_found] Задача не найдена или недоступна.';
  end if;

  v_limit := coalesce(
    (select (value #>> '{}')::int
       from public.app_settings
      where key = 'submissions_per_minute'),
    10
  );

  select count(*)
    into v_recent
    from public.submissions s
   where s.user_id = v_uid
     and s.created_at > now() - interval '1 minute';

  if v_recent >= v_limit then
    raise exception '[rate_limit] Слишком много отправок, подождите минуту.';
  end if;

  select ta.answer
    into v_key
    from public.task_answers ta
   where ta.task_id = p_task_id;

  v_correct := coalesce(
    public.normalize_answer(p_answer, v_format) = public.normalize_answer(v_key, v_format),
    false
  );

  insert into public.submissions (user_id, task_id, code, answer, is_correct)
  values (v_uid, p_task_id, coalesce(p_code, ''), p_answer, v_correct)
  returning id into v_submission_id;

  return jsonb_build_object(
    'is_correct', v_correct,
    'submission_id', v_submission_id
  );
end;
$$;

create or replace function public.get_user_progress(p_user_id uuid)
returns table (ege_number smallint, solved bigint, total bigint)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if p_user_id is distinct from auth.uid() and not public.is_admin() then
    raise exception '[forbidden] Нет доступа к чужому прогрессу.';
  end if;

  return query
  select t.ege_number,
         count(*) filter (
           where exists (
             select 1
               from public.submissions s
              where s.task_id = t.id
                and s.user_id = p_user_id
                and s.is_correct
           )
         )::bigint as solved,
         count(*)::bigint as total
    from public.tasks t
   where t.status = 'published'
   group by t.ege_number
   order by t.ege_number;
end;
$$;

create or replace function public.get_task_stats()
returns table (task_id uuid, attempted_students bigint, solved_students bigint, solved_percent numeric)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  return query
  select t.id as task_id,
         count(distinct s.user_id) as attempted_students,
         count(distinct s.user_id) filter (where s.is_correct) as solved_students,
         case
           when count(distinct s.user_id) = 0 then 0::numeric
           else round(
             100.0 * count(distinct s.user_id) filter (where s.is_correct)
                   / count(distinct s.user_id),
             1
           )
         end as solved_percent
    from public.tasks t
    left join public.submissions s
      on s.task_id = t.id
     and exists (
           select 1
             from public.profiles p
            where p.id = s.user_id
              and p.role = 'student'
         )
   where t.status = 'published'
   group by t.id
   order by t.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- assert_content_admin: общая проверка для всех пишущих функций.
-- Роль admin + ограничение частоты записи (защита от сбойного цикла агента).
-- Возвращает id вызывающего.
-- ---------------------------------------------------------------------------
create or replace function public.assert_content_admin()
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid    uuid;
  v_limit  int;
  v_recent bigint;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception '[not_authenticated] Требуется войти в систему.';
  end if;
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  v_limit := coalesce(
    (select (value #>> '{}')::int
       from public.app_settings
      where key = 'content_writes_per_minute'),
    60
  );

  select count(*)
    into v_recent
    from public.audit_log a
   where a.actor_id = v_uid
     and a.created_at > now() - interval '1 minute';

  if v_recent >= v_limit then
    raise exception '[rate_limit] Слишком много изменений контента, подождите минуту.';
  end if;

  return v_uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- write_audit: запись в журнал. Вызывается только из функций ниже.
-- ---------------------------------------------------------------------------
create or replace function public.write_audit(
  p_actor   uuid,
  p_action  text,
  p_entity  text,
  p_slug    text,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public, extensions
as $$
  insert into public.audit_log (actor_id, action, entity, entity_slug, details)
  values (p_actor, p_action, p_entity, p_slug, coalesce(p_details, '{}'::jsonb));
$$;

-- ---------------------------------------------------------------------------
-- admin_check_slug_available: свободен ли slug задачи.
-- ---------------------------------------------------------------------------
create or replace function public.admin_check_slug_available(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;
  if p_slug is null or p_slug !~ '^[a-z0-9-]{3,64}$' then
    raise exception '[bad_slug] slug: 3–64 символа, строчная латиница, цифры и дефис.';
  end if;

  return jsonb_build_object(
    'slug', p_slug,
    'available', not exists (select 1 from public.tasks t where t.slug = p_slug)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_upsert_task: создать или полностью обновить задачу по slug.
-- Файлы и связи со справочником заменяются целиком.
-- Любое изменение снимает отметку проверки эталона: ответ нужно
-- подтвердить заново (admin_verify_reference).
-- ---------------------------------------------------------------------------
create or replace function public.admin_upsert_task(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid        uuid;
  v_slug       text;
  v_title      text;
  v_statement  text;
  v_status     text;
  v_origin     text;
  v_format     text;
  v_answer     text;
  v_solution   text;
  v_ege        int;
  v_difficulty int;
  v_tags       text[];
  v_ege_list   int[];
  v_task_id    uuid;
  v_created    boolean := false;
  v_file       jsonb;
  v_filename   text;
  v_content    text;
  v_total      bigint := 0;
  v_index      int := 0;
  v_ref        jsonb;
  v_article_id uuid;
  v_relevance  text;
  v_warnings   text[] := '{}';
  v_primary    int := 0;
begin
  v_uid := public.assert_content_admin();

  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception '[bad_payload] Ожидается объект JSON с описанием задачи.';
  end if;

  v_slug      := payload ->> 'slug';
  v_title     := btrim(coalesce(payload ->> 'title', ''));
  v_statement := coalesce(payload ->> 'statement_md', '');
  v_status    := coalesce(payload ->> 'status', 'draft');
  v_origin    := coalesce(payload ->> 'origin', 'human');
  v_format    := payload ->> 'answer_format';
  v_answer    := payload ->> 'answer';
  v_solution  := payload ->> 'reference_solution';

  if v_slug is null or v_slug !~ '^[a-z0-9-]{3,64}$' then
    raise exception '[bad_slug] slug: 3–64 символа, строчная латиница, цифры и дефис.';
  end if;
  if v_title = '' then
    raise exception '[bad_title] Название задачи не может быть пустым.';
  end if;
  if length(v_statement) < 40 then
    raise exception '[short_statement] Условие слишком короткое: нужно не меньше 40 символов.';
  end if;
  if v_status not in ('draft', 'review', 'published') then
    raise exception '[bad_status] Статус: draft, review или published.';
  end if;
  if v_origin not in ('human', 'ai') then
    raise exception '[bad_origin] origin: human или ai.';
  end if;
  if v_format is null or v_format not in ('single', 'pair', 'multi', 'string') then
    raise exception '[bad_answer_format] Формат ответа: single, pair, multi или string.';
  end if;

  begin
    v_ege := (payload ->> 'ege_number')::int;
    v_difficulty := (payload ->> 'difficulty')::int;
  exception
    when others then
      raise exception '[bad_number] ege_number и difficulty должны быть числами.';
  end;

  if v_ege is null or v_ege < 1 or v_ege > 27 then
    raise exception '[bad_ege_number] Номер задания ЕГЭ: от 1 до 27.';
  end if;
  if v_difficulty is null or v_difficulty < 1 or v_difficulty > 3 then
    raise exception '[bad_difficulty] Сложность: 1, 2 или 3.';
  end if;

  if v_answer is null or btrim(v_answer) = '' then
    raise exception '[bad_answer] Ответ не может быть пустым.';
  end if;
  if v_format = 'string' and v_answer ~ E'[\\n\\r]' then
    raise exception '[bad_answer] Строковый ответ должен быть в одну строку.';
  end if;
  if public.normalize_answer(v_answer, v_format) is null then
    raise exception '[bad_answer] Ответ «%» не соответствует формату «%».', v_answer, v_format;
  end if;

  if v_status in ('review', 'published')
     and (v_solution is null or btrim(v_solution) = '') then
    raise exception '[missing_reference_solution] Без эталонного решения задачу нельзя отправить на проверку или опубликовать.';
  end if;

  -- Публикация разрешена только после сверки вывода эталона с ответом.
  if v_status = 'published' then
    raise exception '[not_verified] Публиковать можно только через admin_set_task_status после проверки эталона.';
  end if;

  v_tags := coalesce(
    array(select jsonb_array_elements_text(payload -> 'tags')),
    '{}'::text[]
  );

  insert into public.tasks as t (
    slug, ege_number, title, statement_md, difficulty, answer_format,
    tags, source, status, origin, reference_solution, answer_explanation,
    created_by, reference_verified_at
  )
  values (
    v_slug, v_ege::smallint, v_title, v_statement, v_difficulty::smallint,
    v_format, v_tags, payload ->> 'source', v_status, v_origin, v_solution,
    payload ->> 'answer_explanation', v_uid, null
  )
  on conflict (slug) do update
     set ege_number            = excluded.ege_number,
         title                 = excluded.title,
         statement_md          = excluded.statement_md,
         difficulty            = excluded.difficulty,
         answer_format         = excluded.answer_format,
         tags                  = excluded.tags,
         source                = excluded.source,
         status                = excluded.status,
         origin                = excluded.origin,
         reference_solution    = excluded.reference_solution,
         answer_explanation    = excluded.answer_explanation,
         -- Задача изменилась: эталон нужно проверить заново.
         reference_verified_at = null
  -- xmax = 0 у только что вставленной строки; у обновлённой — id транзакции.
  returning t.id, (t.xmax::text::bigint = 0) into v_task_id, v_created;

  insert into public.task_answers (task_id, answer)
  values (v_task_id, v_answer)
  on conflict (task_id) do update set answer = excluded.answer;

  -- Файлы заменяются целиком.
  delete from public.task_files where task_id = v_task_id;
  for v_file in
    select value from jsonb_array_elements(coalesce(payload -> 'files', '[]'::jsonb))
  loop
    v_filename := v_file ->> 'filename';
    v_content  := coalesce(v_file ->> 'content', '');

    if v_filename is null
       or v_filename !~ '^[A-Za-z0-9_.-]{1,64}$'
       or v_filename ~ '\.\.' then
      raise exception '[bad_filename] Недопустимое имя файла «%»: только латиница, цифры, точка, дефис и подчёркивание, без путей.',
        coalesce(v_filename, '');
    end if;
    if octet_length(v_content) > 4194304 then
      raise exception '[file_too_large] Файл «%» больше 4 МБ.', v_filename;
    end if;

    v_total := v_total + octet_length(v_content);
    if v_total > 8388608 then
      raise exception '[files_too_large] Суммарный размер файлов задачи больше 8 МБ.';
    end if;

    insert into public.task_files (task_id, filename, content, sort_order)
    values (v_task_id, v_filename, v_content, v_index);
    v_index := v_index + 1;
  end loop;

  -- Связи со справочником пересобираются.
  delete from public.task_references where task_id = v_task_id;
  v_index := 0;
  for v_ref in
    select value from jsonb_array_elements(coalesce(payload -> 'references', '[]'::jsonb))
  loop
    select a.id into v_article_id
      from public.reference_articles a
     where a.slug = v_ref ->> 'slug';
    if v_article_id is null then
      raise exception '[article_not_found] Статья справочника «%» не найдена.',
        coalesce(v_ref ->> 'slug', '');
    end if;

    v_relevance := coalesce(v_ref ->> 'relevance', 'related');
    if v_relevance not in ('primary', 'related') then
      raise exception '[bad_relevance] relevance: primary или related.';
    end if;
    if v_relevance = 'primary' then
      v_primary := v_primary + 1;
    end if;

    insert into public.task_references (task_id, article_id, relevance, sort_order)
    values (v_task_id, v_article_id, v_relevance, v_index);
    v_index := v_index + 1;
  end loop;

  if v_primary = 0 then
    v_warnings := v_warnings
      || 'Нет ни одной статьи справочника с relevance = primary.'::text;
  end if;
  if coalesce(btrim(payload ->> 'answer_explanation'), '') = '' then
    v_warnings := v_warnings
      || 'Не заполнен разбор ответа (answer_explanation).'::text;
  end if;

  perform public.write_audit(
    v_uid,
    case when v_created then 'create_task' else 'update_task' end,
    'task',
    v_slug,
    jsonb_build_object('status', v_status, 'files', v_index)
  );

  return jsonb_build_object(
    'task_id',  v_task_id,
    'slug',     v_slug,
    'created',  v_created,
    'status',   v_status,
    'warnings', to_jsonb(v_warnings)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_upsert_article: статья справочника, идемпотентно по slug.
-- ---------------------------------------------------------------------------
create or replace function public.admin_upsert_article(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid      uuid;
  v_slug     text;
  v_title    text;
  v_summary  text;
  v_content  text;
  v_level    int;
  v_minutes  int;
  v_ege      smallint[];
  v_tags     text[];
  v_id       uuid;
  v_created  boolean := false;
begin
  v_uid := public.assert_content_admin();

  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception '[bad_payload] Ожидается объект JSON с описанием статьи.';
  end if;

  v_slug    := payload ->> 'slug';
  v_title   := btrim(coalesce(payload ->> 'title', ''));
  v_summary := btrim(coalesce(payload ->> 'summary', ''));
  v_content := coalesce(payload ->> 'content_md', '');
  v_level   := coalesce((payload ->> 'level')::int, 1);
  v_minutes := coalesce((payload ->> 'reading_minutes')::int, 5);

  if v_slug is null or v_slug !~ '^[a-z0-9-]{3,64}$' then
    raise exception '[bad_slug] slug: 3–64 символа, строчная латиница, цифры и дефис.';
  end if;
  if v_title = '' then
    raise exception '[bad_title] Заголовок статьи не может быть пустым.';
  end if;
  if v_summary = '' then
    raise exception '[bad_summary] Нужно одно предложение-описание для карточки.';
  end if;
  if length(v_content) < 200 then
    raise exception '[short_content] Статья слишком короткая: нужно не меньше 200 символов.';
  end if;
  if v_level < 1 or v_level > 3 then
    raise exception '[bad_level] Уровень: 1, 2 или 3.';
  end if;
  if v_minutes < 1 then
    raise exception '[bad_reading_minutes] Время чтения должно быть положительным.';
  end if;

  v_ege := coalesce(
    array(select (jsonb_array_elements_text(payload -> 'ege_numbers'))::smallint),
    '{}'::smallint[]
  );
  v_tags := coalesce(
    array(select jsonb_array_elements_text(payload -> 'tags')),
    '{}'::text[]
  );

  insert into public.reference_articles as a (
    slug, title, summary, content_md, ege_numbers, tags, level,
    reading_minutes, is_published
  )
  values (
    v_slug, v_title, v_summary, v_content, v_ege, v_tags, v_level::smallint,
    v_minutes::smallint, coalesce((payload ->> 'is_published')::boolean, false)
  )
  on conflict (slug) do update
     set title           = excluded.title,
         summary         = excluded.summary,
         content_md      = excluded.content_md,
         ege_numbers     = excluded.ege_numbers,
         tags            = excluded.tags,
         level           = excluded.level,
         reading_minutes = excluded.reading_minutes,
         is_published    = excluded.is_published
  returning a.id, (a.xmax::text::bigint = 0) into v_id, v_created;

  perform public.write_audit(
    v_uid,
    case when v_created then 'create_article' else 'update_article' end,
    'article',
    v_slug
  );

  return jsonb_build_object(
    'article_id', v_id,
    'slug',       v_slug,
    'created',    v_created
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_verify_reference: сверка вывода эталона с сохранённым ответом.
-- Клиент (админка или агент) запускает reference_solution и присылает вывод;
-- сравнение и отметка о проверке — на стороне базы.
-- ---------------------------------------------------------------------------
create or replace function public.admin_verify_reference(
  p_slug   text,
  p_output text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid     uuid;
  v_task_id uuid;
  v_format  text;
  v_answer  text;
  v_matches boolean;
begin
  v_uid := public.assert_content_admin();

  select t.id, t.answer_format, ta.answer
    into v_task_id, v_format, v_answer
    from public.tasks t
    left join public.task_answers ta on ta.task_id = t.id
   where t.slug = p_slug;

  if v_task_id is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(p_slug, '');
  end if;

  v_matches := coalesce(
    public.normalize_answer(p_output, v_format) = public.normalize_answer(v_answer, v_format),
    false
  );

  update public.tasks
     set reference_verified_at = case when v_matches then now() else null end
   where id = v_task_id;

  perform public.write_audit(
    v_uid, 'verify_reference', 'task', p_slug,
    jsonb_build_object('matches', v_matches)
  );

  return jsonb_build_object('slug', p_slug, 'matches', v_matches);
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_set_task_status: смена статуса задачи.
-- Публикация — только после успешной проверки эталона.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_task_status(
  p_slug   text,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid      uuid;
  v_task_id  uuid;
  v_solution text;
  v_verified timestamptz;
begin
  v_uid := public.assert_content_admin();

  if p_status not in ('draft', 'review', 'published') then
    raise exception '[bad_status] Статус: draft, review или published.';
  end if;

  select t.id, t.reference_solution, t.reference_verified_at
    into v_task_id, v_solution, v_verified
    from public.tasks t
   where t.slug = p_slug;

  if v_task_id is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(p_slug, '');
  end if;

  if p_status in ('review', 'published')
     and (v_solution is null or btrim(v_solution) = '') then
    raise exception '[missing_reference_solution] У задачи нет эталонного решения.';
  end if;
  if p_status = 'published' and v_verified is null then
    raise exception '[not_verified] Сначала проверьте эталон: его вывод должен совпасть с ответом.';
  end if;

  update public.tasks set status = p_status where id = v_task_id;

  perform public.write_audit(
    v_uid, 'set_status', 'task', p_slug, jsonb_build_object('status', p_status)
  );

  return jsonb_build_object('slug', p_slug, 'status', p_status);
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_delete_task: удаление задачи вместе с файлами, ответом и связями.
-- ---------------------------------------------------------------------------
create or replace function public.admin_delete_task(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid     uuid;
  v_task_id uuid;
begin
  v_uid := public.assert_content_admin();

  select t.id into v_task_id from public.tasks t where t.slug = p_slug;
  if v_task_id is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(p_slug, '');
  end if;

  -- Файлы, ответ и связи уходят каскадом (on delete cascade).
  delete from public.tasks where id = v_task_id;

  perform public.write_audit(v_uid, 'delete_task', 'task', p_slug);

  return jsonb_build_object('slug', p_slug, 'deleted', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_list_tasks: список задач для админки и агента.
-- Фильтры: status, ege_number, origin, search, limit, offset.
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_tasks(filters jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_status text;
  v_origin text;
  v_ege    int;
  v_search text;
  v_limit  int;
  v_offset int;
  v_total  bigint;
  v_items  jsonb;
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  filters  := coalesce(filters, '{}'::jsonb);
  v_status := filters ->> 'status';
  v_origin := filters ->> 'origin';
  v_ege    := (filters ->> 'ege_number')::int;
  v_search := nullif(btrim(coalesce(filters ->> 'search', '')), '');
  v_limit  := least(coalesce((filters ->> 'limit')::int, 100), 500);
  v_offset := greatest(coalesce((filters ->> 'offset')::int, 0), 0);

  select count(*)
    into v_total
    from public.tasks t
   where (v_status is null or t.status = v_status)
     and (v_origin is null or t.origin = v_origin)
     and (v_ege is null or t.ege_number = v_ege)
     and (v_search is null
          or t.title ilike '%' || v_search || '%'
          or t.slug ilike '%' || v_search || '%');

  select coalesce(jsonb_agg(item order by item ->> 'updated_at' desc), '[]'::jsonb)
    into v_items
    from (
      select jsonb_build_object(
               'slug',            t.slug,
               'title',           t.title,
               'ege_number',      t.ege_number,
               'difficulty',      t.difficulty,
               'status',          t.status,
               'origin',          t.origin,
               'has_reference',   t.reference_solution is not null
                                    and btrim(t.reference_solution) <> '',
               'verified',        t.reference_verified_at is not null,
               'files_count',     (select count(*) from public.task_files f
                                    where f.task_id = t.id),
               'articles_count',  (select count(*) from public.task_references r
                                    where r.task_id = t.id),
               'attempts',        (select count(*) from public.submissions s
                                    where s.task_id = t.id),
               'updated_at',      t.updated_at
             ) as item
        from public.tasks t
       where (v_status is null or t.status = v_status)
         and (v_origin is null or t.origin = v_origin)
         and (v_ege is null or t.ege_number = v_ege)
         and (v_search is null
              or t.title ilike '%' || v_search || '%'
              or t.slug ilike '%' || v_search || '%')
       order by t.updated_at desc
       limit v_limit offset v_offset
    ) sub;

  return jsonb_build_object(
    'total', v_total,
    'limit', v_limit,
    'offset', v_offset,
    'items', v_items,
    'awaiting_review', (select count(*) from public.tasks t where t.status = 'review')
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_get_task: задача целиком — с эталоном, ответом, файлами и связями.
-- ---------------------------------------------------------------------------
create or replace function public.admin_get_task(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_task jsonb;
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  select jsonb_build_object(
           'id',                    t.id,
           'slug',                  t.slug,
           'ege_number',            t.ege_number,
           'title',                 t.title,
           'statement_md',          t.statement_md,
           'difficulty',            t.difficulty,
           'answer_format',         t.answer_format,
           'tags',                  to_jsonb(t.tags),
           'source',                t.source,
           'status',                t.status,
           'origin',                t.origin,
           'reference_solution',    t.reference_solution,
           'answer_explanation',    t.answer_explanation,
           'answer',                (select ta.answer from public.task_answers ta
                                      where ta.task_id = t.id),
           'reference_verified_at', t.reference_verified_at,
           'created_at',            t.created_at,
           'updated_at',            t.updated_at,
           'files', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'filename',   f.filename,
                      'content',    f.content,
                      'size_bytes', f.size_bytes
                    ) order by f.sort_order)
               from public.task_files f
              where f.task_id = t.id), '[]'::jsonb),
           'references', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'slug',      a.slug,
                      'title',     a.title,
                      'relevance', r.relevance
                    ) order by r.sort_order)
               from public.task_references r
               join public.reference_articles a on a.id = r.article_id
              where r.task_id = t.id), '[]'::jsonb)
         )
    into v_task
    from public.tasks t
   where t.slug = p_slug;

  if v_task is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(p_slug, '');
  end if;

  return v_task;
end;
$$;

-- ---------------------------------------------------------------------------
-- Права на выполнение: роль проверяется внутри функций, anon не пускаем.
-- ---------------------------------------------------------------------------
revoke execute on function public.assert_content_admin()                 from public, anon;
revoke execute on function public.write_audit(uuid, text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.admin_check_slug_available(text)       from public, anon;
revoke execute on function public.admin_upsert_task(jsonb)               from public, anon;
revoke execute on function public.admin_upsert_article(jsonb)            from public, anon;
revoke execute on function public.admin_verify_reference(text, text)     from public, anon;
revoke execute on function public.admin_set_task_status(text, text)      from public, anon;
revoke execute on function public.admin_delete_task(text)                from public, anon;
revoke execute on function public.admin_list_tasks(jsonb)                from public, anon;
revoke execute on function public.admin_get_task(text)                   from public, anon;

grant execute on function public.admin_check_slug_available(text)   to authenticated;
grant execute on function public.admin_upsert_task(jsonb)           to authenticated;
grant execute on function public.admin_upsert_article(jsonb)        to authenticated;
grant execute on function public.admin_verify_reference(text, text) to authenticated;
grant execute on function public.admin_set_task_status(text, text)  to authenticated;
grant execute on function public.admin_delete_task(text)            to authenticated;
grant execute on function public.admin_list_tasks(jsonb)            to authenticated;
grant execute on function public.admin_get_task(text)               to authenticated;
