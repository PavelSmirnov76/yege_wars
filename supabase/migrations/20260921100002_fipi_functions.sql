-- =============================================================================
-- ИМПОРТ БАНКА ФИПИ, миграция 3/3: Content API под новую схему.
--
-- Что меняется в admin_upsert_task:
--   * origin принимает fipi;
--   * ege_number стал необязательным — у 457 заданий банка номера нет;
--   * ответ можно не присылать вовсе, пока задача в черновике: в банке ФИПИ
--     ответов нет ни у одного задания. Присланный пустой ответ по-прежнему
--     отклоняется — это ошибка заполнения, а не «ответа ещё нет»;
--   * появился массив themes: темы задания задаются через API, иначе править
--     импортированную задачу было бы нечем;
--   * предупреждение о главной статье не выводится, если справка задаче
--     и так полагается по теме.
-- =============================================================================

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
  v_has_answer boolean;
  v_solution   text;
  v_ege        int;
  v_ege_src    text;
  v_difficulty int;
  v_tags       text[];
  v_task_id    uuid;
  v_created    boolean := false;
  v_file       jsonb;
  v_filename   text;
  v_content    text;
  v_total      bigint := 0;
  v_index      int := 0;
  v_theme      text;
  v_themes     int := 0;
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

  v_slug       := payload ->> 'slug';
  v_title      := btrim(coalesce(payload ->> 'title', ''));
  v_statement  := coalesce(payload ->> 'statement_md', '');
  v_status     := coalesce(payload ->> 'status', 'draft');
  v_origin     := coalesce(payload ->> 'origin', 'human');
  v_format     := payload ->> 'answer_format';
  v_has_answer := payload ? 'answer';
  v_answer     := payload ->> 'answer';
  v_solution   := payload ->> 'reference_solution';
  v_ege_src    := payload ->> 'ege_number_source';

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
  if v_origin not in ('human', 'ai', 'fipi') then
    raise exception '[bad_origin] origin: human, ai или fipi.';
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

  -- Номер задания необязателен: часть банка к актуальной структуре КИМ
  -- не отнесена. Но если номер прислан, он должен быть настоящим.
  if v_ege is not null and (v_ege < 1 or v_ege > 27) then
    raise exception '[bad_ege_number] Номер задания ЕГЭ: от 1 до 27.';
  end if;
  if v_ege_src is not null and v_ege_src not in ('fipi-spec-2026', 'manual') then
    raise exception '[bad_number_source] ege_number_source: fipi-spec-2026 или manual.';
  end if;
  if v_difficulty is null or v_difficulty < 1 or v_difficulty > 3 then
    raise exception '[bad_difficulty] Сложность: 1, 2 или 3.';
  end if;

  -- Ответ можно не присылать: у заданий банка ФИПИ его нет. Но задача без
  -- ответа остаётся черновиком — проверить решение ученика нечем.
  if v_has_answer then
    if v_answer is null or btrim(v_answer) = '' then
      raise exception '[bad_answer] Ответ не может быть пустым.';
    end if;
    if v_format = 'string' and v_answer ~ E'[\\n\\r]' then
      raise exception '[bad_answer] Строковый ответ должен быть в одну строку.';
    end if;
    if public.normalize_answer(v_answer, v_format) is null then
      raise exception '[bad_answer] Ответ «%» не соответствует формату «%».', v_answer, v_format;
    end if;
  elsif v_status <> 'draft' then
    raise exception '[bad_answer] Без ответа задачу можно сохранить только черновиком.';
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
    slug, ege_number, ege_number_source, title, statement_md, difficulty,
    answer_format, tags, source, status, origin, reference_solution,
    answer_explanation, created_by, reference_verified_at
  )
  values (
    v_slug, v_ege::smallint, v_ege_src, v_title, v_statement,
    v_difficulty::smallint, v_format, v_tags, payload ->> 'source', v_status,
    v_origin, v_solution, payload ->> 'answer_explanation', v_uid, null
  )
  on conflict (slug) do update
     set ege_number            = excluded.ege_number,
         ege_number_source     = excluded.ege_number_source,
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

  if v_has_answer then
    insert into public.task_answers (task_id, answer)
    values (v_task_id, v_answer)
    on conflict (task_id) do update set answer = excluded.answer;
  else
    delete from public.task_answers where task_id = v_task_id;
  end if;

  -- Темы заменяются целиком. Если ни одной не прислали, задача получит
  -- служебную тему none — за этим следит отложенный триггер.
  delete from public.task_themes where task_id = v_task_id;
  v_index := 0;
  for v_theme in
    select value from jsonb_array_elements_text(coalesce(payload -> 'themes', '[]'::jsonb))
  loop
    if not exists (select 1 from public.themes th where th.code = v_theme) then
      raise exception '[theme_not_found] Тема «%» не найдена в кодификаторе.', v_theme;
    end if;
    insert into public.task_themes (task_id, theme_code, sort_order)
    values (v_task_id, v_theme, v_index)
    on conflict (task_id, theme_code) do update set sort_order = excluded.sort_order;
    v_index := v_index + 1;
    v_themes := v_themes + 1;
  end loop;

  -- Файлы заменяются целиком.
  delete from public.task_files where task_id = v_task_id;
  v_index := 0;
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

  -- Ручная связь нужна только там, где по теме статьи не полагается:
  -- обычную справку задача получает через task_articles.
  if v_primary = 0
     and not exists (select 1 from public.task_articles ta where ta.task_id = v_task_id)
  then
    v_warnings := v_warnings
      || 'У задачи нет ни статьи по теме, ни связи с relevance = primary.'::text;
  end if;
  if coalesce(btrim(payload ->> 'answer_explanation'), '') = '' then
    v_warnings := v_warnings
      || 'Не заполнен разбор ответа (answer_explanation).'::text;
  end if;
  if not v_has_answer then
    v_warnings := v_warnings
      || 'Ответа нет: опубликовать задачу нельзя, пока он не появится.'::text;
  end if;

  perform public.write_audit(
    v_uid,
    case when v_created then 'create_task' else 'update_task' end,
    'task',
    v_slug,
    jsonb_build_object('status', v_status, 'files', v_index, 'themes', v_themes)
  );

  return jsonb_build_object(
    'task_id',  v_task_id,
    'slug',     v_slug,
    'created',  v_created,
    'status',   v_status,
    'themes',   v_themes,
    'warnings', to_jsonb(v_warnings)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_get_task: к задаче добавляются её темы и справка, выведенная по темам.
-- ---------------------------------------------------------------------------
create or replace function public.admin_get_task(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_result jsonb;
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  select jsonb_build_object(
           'id',                     t.id,
           'slug',                   t.slug,
           'ege_number',             t.ege_number,
           'ege_number_source',      t.ege_number_source,
           'title',                  t.title,
           'statement_md',           t.statement_md,
           'difficulty',             t.difficulty,
           'answer_format',          t.answer_format,
           'tags',                   to_jsonb(t.tags),
           'source',                 t.source,
           'status',                 t.status,
           'origin',                 t.origin,
           'fipi_id',                t.fipi_id,
           'fipi_short_id',          t.fipi_short_id,
           'parent_task_id',         t.parent_task_id,
           'condition_incomplete',   t.condition_incomplete,
           'duplicate_of',           t.duplicate_of,
           'reference_solution',     t.reference_solution,
           'answer_explanation',     t.answer_explanation,
           'reference_verified_at',  t.reference_verified_at,
           'created_at',             t.created_at,
           'updated_at',             t.updated_at,
           'answer',                 ta.answer,
           'themes', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'code',  th.code,
                      'title', th.title,
                      'level', th.level
                    ) order by tt.sort_order, th.code)
               from public.task_themes tt
               join public.themes th on th.code = tt.theme_code
              where tt.task_id = t.id
           ), '[]'::jsonb),
           'files', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'filename',     f.filename,
                      'content',      f.content,
                      'size_bytes',   f.size_bytes,
                      'kind',         f.kind,
                      'storage_path', f.storage_path
                    ) order by f.sort_order, f.filename)
               from public.task_files f
              where f.task_id = t.id
           ), '[]'::jsonb),
           'articles', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'slug',       ta2.slug,
                      'title',      ta2.title,
                      'theme_code', ta2.theme_code
                    ) order by ta2.sort_order, ta2.slug)
               from public.task_articles ta2
              where ta2.task_id = t.id
           ), '[]'::jsonb),
           'references', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'slug',      a.slug,
                      'title',     a.title,
                      'relevance', r.relevance
                    ) order by r.sort_order, a.slug)
               from public.task_references r
               join public.reference_articles a on a.id = r.article_id
              where r.task_id = t.id
           ), '[]'::jsonb)
         )
    into v_result
    from public.tasks t
    left join public.task_answers ta on ta.task_id = t.id
   where t.slug = p_slug;

  if v_result is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(p_slug, '');
  end if;

  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_upsert_article: у статьи появляется тема кодификатора.
-- Связь один к одному: тему держит уникальная колонка theme_code.
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
  v_theme    text;
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
  v_theme   := payload ->> 'theme_code';
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
  if v_theme is not null
     and not exists (select 1 from public.themes th where th.code = v_theme)
  then
    raise exception '[theme_not_found] Тема «%» не найдена в кодификаторе.', v_theme;
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
    slug, title, summary, content_md, theme_code, ege_numbers, tags, level,
    reading_minutes, is_published
  )
  values (
    v_slug, v_title, v_summary, v_content, v_theme, v_ege, v_tags,
    v_level::smallint, v_minutes::smallint,
    coalesce((payload ->> 'is_published')::boolean, false)
  )
  on conflict (slug) do update
     set title           = excluded.title,
         summary         = excluded.summary,
         content_md      = excluded.content_md,
         theme_code      = excluded.theme_code,
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
    v_slug,
    jsonb_build_object('theme_code', v_theme)
  );

  return jsonb_build_object(
    'article_id', v_id,
    'slug',       v_slug,
    'theme_code', v_theme,
    'created',    v_created
  );
end;
$$;
