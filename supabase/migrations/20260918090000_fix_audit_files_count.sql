-- =============================================================================
-- Исправление: в журнале действий число файлов задачи писалось нулём.
-- Счётчик v_index переиспользовался под связи со справочником, и в audit_log
-- попадало их количество. Теперь файлы считаются отдельно, а в details видно
-- и то, и другое. Логика самой функции не меняется.
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
  v_files      int := 0;
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
  v_files := v_index;

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
    jsonb_build_object(
      'status', v_status, 'files', v_files, 'references', v_index
    )
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
