-- =============================================================================
-- ЭТАП 2, миграция 3/3: функции (RPC).
-- Все функции: security definer, set search_path = public, extensions;
-- проверки auth.uid()/роли — внутри каждой функции.
-- Тексты ошибок показываются в UI и начинаются с кода в квадратных скобках.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- is_admin: является ли текущий пользователь администратором.
-- (Впервые объявлена в миграции RLS — здесь пересоздаётся без изменений.)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- normalize_answer: приведение ответа к каноническому виду для сравнения.
-- Общее: trim + схлопывание любых пробельных последовательностей (включая
-- переводы строк) в один пробел.
-- single/pair/multi: каждый токен обязан быть числом; он канонизируется через
-- numeric (уходят ведущие нули, '-0' -> '0', поддерживаются отрицательные).
-- Количество токенов: single — ровно 1, pair — ровно 2, multi — 1 и более.
-- string: регистр и содержимое сохраняются.
-- Если формат числовой, а токен не число — возвращается null: такой ответ
-- заведомо неверный, но это НЕ ошибка выполнения.
-- ---------------------------------------------------------------------------
create or replace function public.normalize_answer(p_answer text, p_format text)
returns text
language plpgsql
immutable
security definer
set search_path = public, extensions
as $$
declare
  v_text   text;
  v_tokens text[];
  v_token  text;
  v_canon  text[];
  v_num    text;
begin
  if p_answer is null then
    return null;
  end if;

  -- Края обрезаем, все пробельные последовательности схлопываем в один пробел.
  v_text := regexp_replace(btrim(p_answer), '\s+', ' ', 'g');

  -- Строковый формат: возвращаем как есть (регистр сохраняется).
  if p_format = 'string' then
    return v_text;
  end if;

  if p_format not in ('single', 'pair', 'multi') then
    -- Неизвестный формат: ответ несравним.
    return null;
  end if;

  if v_text = '' then
    return null;
  end if;

  v_tokens := string_to_array(v_text, ' ');

  if p_format = 'single' and array_length(v_tokens, 1) <> 1 then
    return null;
  end if;
  if p_format = 'pair' and array_length(v_tokens, 1) <> 2 then
    return null;
  end if;
  -- multi: один и более токенов — уже гарантировано (v_text не пуст).

  v_canon := '{}';
  foreach v_token in array v_tokens loop
    -- Токен обязан быть числом: целым или десятичным, возможно отрицательным.
    if v_token !~ '^-?\d+(\.\d+)?$' then
      return null;
    end if;
    -- Канонический вид через numeric: '007' -> '7', '-0' -> '0'.
    v_num := v_token::numeric::text;
    -- Убираем незначащие нули дробной части: '1.50' -> '1.5', '2.0' -> '2'.
    if position('.' in v_num) > 0 then
      v_num := regexp_replace(v_num, '0+$', '');
      v_num := regexp_replace(v_num, '\.$', '');
    end if;
    v_canon := v_canon || v_num;
  end loop;

  return array_to_string(v_canon, ' ');
end;
$$;

-- ---------------------------------------------------------------------------
-- is_registration_open: открыта ли регистрация. Доступна anon и authenticated,
-- чтобы экран регистрации мог показать состояние до входа.
-- ---------------------------------------------------------------------------
create or replace function public.is_registration_open()
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select coalesce(
    (select (value #>> '{}')::boolean
       from public.app_settings
      where key = 'registration_open'),
    true
  );
$$;

-- ---------------------------------------------------------------------------
-- submit_solution: отправка решения. Проверяет доступность задачи и rate
-- limit, сравнивает ответ с эталоном и записывает попытку.
-- ---------------------------------------------------------------------------
create or replace function public.submit_solution(p_task_id uuid, p_code text, p_answer text)
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

  select t.answer_format, t.is_published
    into v_format, v_task_published
    from public.tasks t
   where t.id = p_task_id;

  -- Неопубликованную задачу может решать только админ; существование
  -- скрытой задачи студенту не раскрываем.
  if not found or not (v_task_published or public.is_admin()) then
    raise exception '[task_not_found] Задача не найдена или недоступна.';
  end if;

  -- Rate limit: не больше N отправок за последнюю минуту.
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

  -- Эталонный ответ; если его нет или ответ не разобран, null -> false.
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

-- ---------------------------------------------------------------------------
-- set_solution_published: публикация/снятие с публикации своего решения.
-- ---------------------------------------------------------------------------
create or replace function public.set_solution_published(p_submission_id uuid, p_published boolean)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid;
  v_row public.submissions%rowtype;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception '[not_authenticated] Требуется войти в систему.';
  end if;

  if p_published is null then
    raise exception '[bad_argument] Не указано, публиковать решение или снять с публикации.';
  end if;

  select *
    into v_row
    from public.submissions s
   where s.id = p_submission_id;

  if not found then
    raise exception '[not_found] Попытка не найдена.';
  end if;

  if v_row.user_id <> v_uid then
    raise exception '[not_owner] Публиковать можно только свои решения.';
  end if;

  if p_published and not v_row.is_correct then
    raise exception '[not_correct] Опубликовать можно только верное решение.';
  end if;

  update public.submissions
     set is_published = p_published,
         published_at = case when p_published then now() else null end
   where id = p_submission_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- get_user_progress: прогресс пользователя по номерам ЕГЭ.
-- Свой прогресс видит каждый, чужой — только админ.
-- total — опубликованные задачи номера, solved — задачи с верной попыткой.
-- Выводятся только номера, где есть опубликованные задачи (total > 0).
-- ---------------------------------------------------------------------------
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
   where t.is_published
   group by t.ege_number
   order by t.ege_number;
end;
$$;

-- ---------------------------------------------------------------------------
-- get_task_stats: статистика по опубликованным задачам.
-- Учитываются только попытки студентов (role = 'student').
-- solved_percent — доля решивших среди пытавшихся, 0 при отсутствии попыток.
-- ---------------------------------------------------------------------------
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
   where t.is_published
   group by t.id
   order by t.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_get_task_answer: эталонный ответ задачи (только админ).
-- ---------------------------------------------------------------------------
create or replace function public.admin_get_task_answer(p_task_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  if not exists (select 1 from public.tasks t where t.id = p_task_id) then
    raise exception '[task_not_found] Задача не найдена.';
  end if;

  -- null, если эталон ещё не задан.
  return (
    select ta.answer
      from public.task_answers ta
     where ta.task_id = p_task_id
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_reset_password: сброс пароля пользователя (только админ).
-- ---------------------------------------------------------------------------
create or replace function public.admin_reset_password(p_user_id uuid, p_new_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  if p_new_password is null or length(p_new_password) < 8 then
    raise exception '[weak_password] Пароль должен содержать не менее 8 символов.';
  end if;

  update auth.users
     set encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
   where id = p_user_id;

  if not found then
    raise exception '[user_not_found] Пользователь не найден.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_set_role: смена роли пользователя (только админ).
-- Снять роль администратора с самого себя нельзя.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_role(p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  if p_role is null or p_role not in ('student', 'admin') then
    raise exception '[bad_role] Недопустимая роль. Разрешены: student, admin.';
  end if;

  if p_user_id = auth.uid() and p_role <> 'admin' then
    raise exception '[self_demote] Нельзя снять роль администратора с самого себя.';
  end if;

  update public.profiles
     set role = p_role
   where id = p_user_id;

  if not found then
    raise exception '[user_not_found] Пользователь не найден.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_list_students: список студентов со сводкой активности (только админ).
-- solved_count — число решённых задач (уникальных), attempts_count — всего
-- попыток, correct_percent — доля верных попыток (0 при отсутствии попыток).
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_students(
  p_search text default null,
  p_limit  int default 100,
  p_offset int default 0
)
returns table (
  user_id         uuid,
  username        text,
  created_at      timestamptz,
  last_activity   timestamptz,
  solved_count    bigint,
  attempts_count  bigint,
  correct_percent numeric
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  return query
  select p.id as user_id,
         p.username,
         p.created_at,
         max(s.created_at) as last_activity,
         count(distinct s.task_id) filter (where s.is_correct) as solved_count,
         count(s.id) as attempts_count,
         case
           when count(s.id) = 0 then 0::numeric
           else round(100.0 * count(s.id) filter (where s.is_correct) / count(s.id), 1)
         end as correct_percent
    from public.profiles p
    left join public.submissions s
      on s.user_id = p.id
   where p.role = 'student'
     and (p_search is null or p.username ilike '%' || p_search || '%')
   group by p.id, p.username, p.created_at
   order by p.username
   limit greatest(coalesce(p_limit, 100), 0)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_student_overview: сводка по одному пользователю (только админ).
-- Возвращает jsonb {"progress": [...], "tasks": [...]} по ВСЕМ задачам,
-- включая неопубликованные.
-- ---------------------------------------------------------------------------
create or replace function public.admin_student_overview(p_user_id uuid)
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

  if not exists (select 1 from public.profiles p where p.id = p_user_id) then
    raise exception '[user_not_found] Пользователь не найден.';
  end if;

  select jsonb_build_object(
    'progress', coalesce(
      (
        select jsonb_agg(
                 jsonb_build_object(
                   'ege_number', x.ege_number,
                   'solved', x.solved,
                   'total', x.total
                 )
                 order by x.ege_number
               )
          from (
            select t.ege_number,
                   count(*) filter (
                     where exists (
                       select 1
                         from public.submissions s
                        where s.task_id = t.id
                          and s.user_id = p_user_id
                          and s.is_correct
                     )
                   ) as solved,
                   count(*) as total
              from public.tasks t
             group by t.ege_number
          ) x
      ),
      '[]'::jsonb
    ),
    'tasks', coalesce(
      (
        select jsonb_agg(
                 jsonb_build_object(
                   'task_id', y.id,
                   'slug', y.slug,
                   'title', y.title,
                   'ege_number', y.ege_number,
                   'status', y.status,
                   'attempts', y.attempts,
                   'last_attempt_at', y.last_attempt_at
                 )
                 order by y.ege_number, y.slug
               )
          from (
            select t.id,
                   t.slug,
                   t.title,
                   t.ege_number,
                   case
                     when coalesce(bool_or(s.is_correct), false) then 'solved'
                     when count(s.id) > 0 then 'tried'
                     else 'none'
                   end as status,
                   count(s.id) as attempts,
                   max(s.created_at) as last_attempt_at
              from public.tasks t
              left join public.submissions s
                on s.task_id = t.id
               and s.user_id = p_user_id
             group by t.id, t.slug, t.title, t.ege_number
          ) y
      ),
      '[]'::jsonb
    )
  )
  into v_result;

  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_task_attempts: все попытки пользователя по задаче (только админ).
-- ---------------------------------------------------------------------------
create or replace function public.admin_task_attempts(p_user_id uuid, p_task_id uuid)
returns table (
  id           uuid,
  code         text,
  answer       text,
  is_correct   boolean,
  is_published boolean,
  published_at timestamptz,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  return query
  select s.id,
         s.code,
         s.answer,
         s.is_correct,
         s.is_published,
         s.published_at,
         s.created_at
    from public.submissions s
   where s.user_id = p_user_id
     and s.task_id = p_task_id
   -- Хронологический порядок: история попыток читается от первой к последней.
   order by s.created_at;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_recent_submissions: лента попыток студентов с фильтрами (только админ).
-- ---------------------------------------------------------------------------
create or replace function public.admin_recent_submissions(
  p_user_id    uuid default null,
  p_ege_number smallint default null,
  p_task_id    uuid default null,
  p_is_correct boolean default null,
  p_from       timestamptz default null,
  p_to         timestamptz default null,
  p_limit      int default 50,
  p_offset     int default 0
)
returns table (
  id           uuid,
  user_id      uuid,
  username     text,
  task_id      uuid,
  task_slug    text,
  task_title   text,
  ege_number   smallint,
  is_correct   boolean,
  is_published boolean,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception '[forbidden] Доступно только администратору.';
  end if;

  return query
  select s.id,
         s.user_id,
         p.username,
         s.task_id,
         t.slug as task_slug,
         t.title as task_title,
         t.ege_number,
         s.is_correct,
         s.is_published,
         s.created_at
    from public.submissions s
    join public.profiles p on p.id = s.user_id
    join public.tasks t on t.id = s.task_id
   where p.role = 'student'
     and (p_user_id is null or s.user_id = p_user_id)
     and (p_ege_number is null or t.ege_number = p_ege_number)
     and (p_task_id is null or s.task_id = p_task_id)
     and (p_is_correct is null or s.is_correct = p_is_correct)
     and (p_from is null or s.created_at >= p_from)
     and (p_to is null or s.created_at <= p_to)
   order by s.created_at desc
   limit greatest(coalesce(p_limit, 50), 0)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- ---------------------------------------------------------------------------
-- Привилегии на выполнение функций.
-- По умолчанию execute выдаётся роли public — отзываем и выдаём явно.
-- Все функции доступны authenticated (admin-проверки внутри самих функций);
-- is_registration_open дополнительно доступна anon.
-- ---------------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.has_solved_task(uuid) to authenticated;
grant execute on function public.normalize_answer(text, text) to authenticated;
grant execute on function public.is_registration_open() to anon, authenticated;
grant execute on function public.submit_solution(uuid, text, text) to authenticated;
grant execute on function public.set_solution_published(uuid, boolean) to authenticated;
grant execute on function public.get_user_progress(uuid) to authenticated;
grant execute on function public.get_task_stats() to authenticated;
grant execute on function public.admin_get_task_answer(uuid) to authenticated;
grant execute on function public.admin_reset_password(uuid, text) to authenticated;
grant execute on function public.admin_set_role(uuid, text) to authenticated;
grant execute on function public.admin_list_students(text, int, int) to authenticated;
grant execute on function public.admin_student_overview(uuid) to authenticated;
grant execute on function public.admin_task_attempts(uuid, uuid) to authenticated;
grant execute on function public.admin_recent_submissions(uuid, smallint, uuid, boolean, timestamptz, timestamptz, int, int) to authenticated;
