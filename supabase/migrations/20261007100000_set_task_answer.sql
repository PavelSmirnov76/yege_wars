-- =============================================================================
-- admin_set_task_answer: ответ, формат и эталон задачи — и больше ничего.
--
-- admin_upsert_task для задач банка ФИПИ не годится: файлы он заменяет
-- целиком и принимает их только с content, без адреса в Storage, поэтому
-- стёр бы ссылки на вложения. Кроме того, он перезаписывает все поля задачи.
--
-- Эта функция меняет только answer_format, reference_solution,
-- answer_explanation и ответ в task_answers. Файлы, темы, связи со
-- справочником, условие, номер и прочее остаются как были. Годится для задачи
-- любого происхождения, не только банка.
--
-- Ответ сменился — эталон нужно сверить заново: отметка сверки снимается.
-- Опубликованная задача уходит в review, потому что публиковать без сверки
-- нельзя. Черновик остаётся черновиком.
-- =============================================================================

create or replace function public.admin_set_task_answer(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid      uuid;
  v_slug     text;
  v_format   text;
  v_answer   text;
  v_solution text;
  v_task_id  uuid;
  v_status   text;
begin
  v_uid := public.assert_content_admin();

  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception '[bad_payload] Ожидается объект JSON с ответом задачи.';
  end if;

  v_slug     := payload ->> 'slug';
  v_format   := payload ->> 'answer_format';
  v_answer   := payload ->> 'answer';
  v_solution := payload ->> 'reference_solution';

  select t.id into v_task_id
    from public.tasks t
   where t.slug = v_slug
     for update;

  if v_task_id is null then
    raise exception '[not_found] Задача «%» не найдена.', coalesce(v_slug, '');
  end if;

  -- Проверки те же, что у admin_upsert_task для этих полей. Сам ответ
  -- в текст ошибки не попадает: сообщение уходит в журналы клиента.
  if v_format is null or v_format not in ('single', 'pair', 'multi', 'string') then
    raise exception '[bad_answer_format] Формат ответа: single, pair, multi или string.';
  end if;
  if v_answer is null or btrim(v_answer) = '' then
    raise exception '[bad_answer] Ответ не может быть пустым.';
  end if;
  if v_format = 'string' and v_answer ~ E'[\\n\\r]' then
    raise exception '[bad_answer] Строковый ответ должен быть в одну строку.';
  end if;
  if public.normalize_answer(v_answer, v_format) is null then
    raise exception '[bad_answer] Ответ не соответствует формату «%».', v_format;
  end if;
  if v_solution is null or btrim(v_solution) = '' then
    raise exception '[missing_reference_solution] Без эталонного решения ответ задаче не задаётся: сверять его не с чем.';
  end if;

  update public.tasks t
     set answer_format         = v_format,
         reference_solution    = v_solution,
         -- Нет ключа — разбор не меняется; явный null его стирает.
         answer_explanation    = case
                                   when payload ? 'answer_explanation'
                                     then payload ->> 'answer_explanation'
                                   else t.answer_explanation
                                 end,
         -- Ответ изменился: эталон нужно сверить заново.
         reference_verified_at = null,
         status                = case
                                   when t.status = 'published' then 'review'
                                   else t.status
                                 end
   where t.id = v_task_id
  returning t.status into v_status;

  insert into public.task_answers (task_id, answer)
  values (v_task_id, v_answer)
  on conflict (task_id) do update set answer = excluded.answer;

  perform public.write_audit(
    v_uid, 'set_answer', 'task', v_slug,
    jsonb_build_object('status', v_status, 'answer_format', v_format)
  );

  return jsonb_build_object(
    'slug',          v_slug,
    'status',        v_status,
    'answer_format', v_format
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Права: роль проверяется внутри функции, anon не пускаем. Supabase выдаёт
-- новым функциям EXECUTE всем ролям — лишнее снимается здесь же (см.
-- 20261006100000 и тест (п) в rls_tests.sql).
-- ---------------------------------------------------------------------------
revoke execute on function public.admin_set_task_answer(jsonb) from public, anon;
grant execute on function public.admin_set_task_answer(jsonb) to authenticated;
