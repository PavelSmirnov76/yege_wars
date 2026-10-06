-- =============================================================================
-- RLS-ТЕСТЫ (локальный прогон на «голом» PostgreSQL 17)
--
-- Запускается от суперпользователя ПОСЛЕ shim_local.sql и всех миграций:
--   psql -v ON_ERROR_STOP=1 -f rls_tests.sql
--
-- Каждый успешный шаг печатает 'OK: …', любой провал — raise exception,
-- на котором psql останавливается. В самом конце — 'RLS TESTS PASSED'.
--
-- Соглашения:
--   * прямые insert/update/select от суперпользователя — тестовый сетап,
--     RLS для суперпользователя не действует;
--   * tests.login(uuid) / tests.logout() — эмуляция залогиненного пользователя
--     (роль authenticated + request.jwt.claims.sub);
--   * ожидаемые ошибки ловятся в под-блоках begin/exception; собственные
--     сообщения о провале начинаются с 'ТЕСТ ПРОВАЛЕН' и не «проглатываются».
-- =============================================================================

set client_min_messages = notice;

-- =============================================================================
-- (а) Регистрация
-- =============================================================================

-- Корректная регистрация: триггер создаёт профиль со student-ролью
do $$
declare
  v_alice    uuid;
  v_username text;
  v_role     text;
begin
  v_alice := tests.signup('alice');

  select username, role
    into v_username, v_role
    from public.profiles
   where id = v_alice;

  if v_username is distinct from 'alice' then
    raise exception 'ТЕСТ ПРОВАЛЕН (а): в профиле username = %, ожидался alice', coalesce(v_username, '<нет профиля>');
  end if;
  if v_role is distinct from 'student' then
    raise exception 'ТЕСТ ПРОВАЛЕН (а): в профиле role = %, ожидалась student', coalesce(v_role, '<null>');
  end if;

  raise notice 'OK: (а) signup создаёт профиль триггером (username совпал, role = student)';
end
$$;

-- Невалидные и повторные username отклоняются
do $$
begin
  -- короче 3 символов
  begin
    perform tests.signup('ab');
    raise exception 'ТЕСТ ПРОВАЛЕН (а): username короче 3 символов прошёл регистрацию';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (а) короткий username отклонён (%)', sqlerrm;
  end;

  -- недопустимые символы
  begin
    perform tests.signup('bad name!');
    raise exception 'ТЕСТ ПРОВАЛЕН (а): username с недопустимыми символами прошёл регистрацию';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (а) username с недопустимыми символами отклонён (%)', sqlerrm;
  end;

  -- повторный username
  begin
    perform tests.signup('alice');
    raise exception 'ТЕСТ ПРОВАЛЕН (а): повторный username прошёл регистрацию';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (а) повторный username отклонён (%)', sqlerrm;
  end;
end
$$;

-- Закрытая регистрация: [registration_closed]
do $$
begin
  update public.app_settings set value = 'false'::jsonb where key = 'registration_open';

  begin
    perform tests.signup('dave');
    raise exception 'ТЕСТ ПРОВАЛЕН (а): регистрация закрыта, но signup прошёл';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[registration_closed]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (а): ожидалась ошибка [registration_closed], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (а) при закрытой регистрации signup падает с [registration_closed]';
  end;

  -- вернуть как было
  update public.app_settings set value = 'true'::jsonb where key = 'registration_open';
end
$$;

-- is_registration_open() доступна роли anon
do $$
begin
  perform set_config('role', 'anon', false);
  if public.is_registration_open() is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (а): is_registration_open() под anon вернула не true';
  end if;
  perform set_config('role', 'none', false);
  raise notice 'OK: (а) is_registration_open() доступна anon и возвращает true';
end
$$;

-- =============================================================================
-- Сетап: остальные пользователи, роль админа, задачи и эталонные ответы
-- =============================================================================
do $$
declare
  v_admin uuid;
begin
  perform tests.signup('bob');
  perform tests.signup('carol');
  v_admin := tests.signup('boss');

  -- роль админа выдаётся напрямую от суперпользователя — тестовый сетап
  update public.profiles set role = 'admin' where id = v_admin;

  raise notice 'OK: (сетап) созданы студенты bob, carol и админ boss';
end
$$;

do $$
begin
  insert into public.tasks (slug, ege_number, title, statement_md, difficulty, answer_format, status)
  values
    ('t-pair',   2,  'Пара чисел',    'Найдите пару чисел.',      1, 'pair',   'published'),
    ('t-other',  2,  'Ещё одна пара', 'Найдите другую пару.',     2, 'pair',   'published'),
    ('t-single', 5,  'Одно число',    'Найдите число.',           1, 'single', 'published'),
    ('t-string', 24, 'Строка',        'Найдите строку.',          3, 'string', 'published'),
    ('t-unpub',  27, 'Черновик',      'Неопубликованная задача.', 1, 'single', 'draft');

  insert into public.task_answers (task_id, answer)
  select t.id, a.answer
    from public.tasks t
    join (values
      ('t-pair',   '12 7'),
      ('t-other',  '3 4'),
      ('t-single', '12'),
      ('t-string', 'AbC'),
      ('t-unpub',  '5')
    ) as a(slug, answer) on a.slug = t.slug;

  raise notice 'OK: (сетап) задачи и эталонные ответы созданы';
end
$$;

-- =============================================================================
-- (б) task_answers: под authenticated любой select — permission denied (42501)
-- =============================================================================
do $$
declare
  v_alice uuid;
  v_admin uuid;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_admin from public.profiles where username = 'boss';

  perform tests.login(v_alice);
  begin
    perform 1 from public.task_answers;
    raise exception 'ТЕСТ ПРОВАЛЕН (б): студент прочитал task_answers напрямую';
  exception when insufficient_privilege then
    raise notice 'OK: (б) select из task_answers под студентом — permission denied';
  end;
  perform tests.logout();

  perform tests.login(v_admin);
  begin
    perform 1 from public.task_answers;
    raise exception 'ТЕСТ ПРОВАЛЕН (б): админ прочитал task_answers напрямую (доступ только через функцию)';
  exception when insufficient_privilege then
    raise notice 'OK: (б) select из task_answers под админом — permission denied';
  end;
  perform tests.logout();
end
$$;

-- =============================================================================
-- (в) tasks: студент видит только опубликованные, админ — все
-- =============================================================================
do $$
declare
  v_alice     uuid;
  v_admin     uuid;
  v_unpub     uuid;
  v_total     bigint;
  v_published bigint;
  v_cnt       bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_admin from public.profiles where username = 'boss';
  select id into v_unpub from public.tasks where slug = 't-unpub';
  select count(*) into v_total     from public.tasks;
  select count(*) into v_published from public.tasks where status = 'published';

  perform tests.login(v_alice);
  select count(*) into v_cnt from public.tasks;
  if v_cnt <> v_published then
    raise exception 'ТЕСТ ПРОВАЛЕН (в): студент видит % задач, ожидалось % (только опубликованные)', v_cnt, v_published;
  end if;
  select count(*) into v_cnt from public.tasks where id = v_unpub;
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (в): студенту видна неопубликованная задача';
  end if;
  perform tests.logout();

  perform tests.login(v_admin);
  select count(*) into v_cnt from public.tasks;
  if v_cnt <> v_total then
    raise exception 'ТЕСТ ПРОВАЛЕН (в): админ видит % задач, ожидалось % (все)', v_cnt, v_total;
  end if;
  perform tests.logout();

  raise notice 'OK: (в) студент видит только опубликованные задачи, админ — все';
end
$$;

-- =============================================================================
-- (г) Прямой insert/update в submissions под authenticated — permission denied
-- =============================================================================
do $$
declare
  v_alice uuid;
  v_task  uuid;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_task  from public.tasks where slug = 't-single';

  perform tests.login(v_alice);

  begin
    insert into public.submissions (user_id, task_id, code, answer, is_correct)
    values (v_alice, v_task, 'print(12)', '12', true);
    raise exception 'ТЕСТ ПРОВАЛЕН (г): прямой insert в submissions прошёл';
  exception when insufficient_privilege then
    raise notice 'OK: (г) прямой insert в submissions — permission denied';
  end;

  begin
    update public.submissions set answer = 'x' where user_id = v_alice;
    raise exception 'ТЕСТ ПРОВАЛЕН (г): прямой update submissions прошёл';
  exception when insufficient_privilege then
    raise notice 'OK: (г) прямой update submissions — permission denied';
  end;

  perform tests.logout();
end
$$;

-- =============================================================================
-- (д) submit_solution: корректность и нормализация ответов
-- Каждый блок — отдельная транзакция, чтобы created_at попыток различались.
-- =============================================================================

-- single: верный, нормализация '012' = '12', неверный
do $$
declare
  v_alice uuid;
  v_task  uuid;
  v_res   jsonb;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_task  from public.tasks where slug = 't-single';

  perform tests.login(v_alice);

  v_res := public.submit_solution(v_task, 'print(12)', '12');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): верный ответ ''12'' (single) не засчитан';
  end if;
  if (v_res ->> 'submission_id') is null then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): submit_solution не вернул submission_id';
  end if;

  v_res := public.submit_solution(v_task, 'print(12)', '012');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): нормализация single: ''012'' должен равняться ''12''';
  end if;

  v_res := public.submit_solution(v_task, 'print(99)', '99');
  if (v_res ->> 'is_correct')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): неверный ответ ''99'' засчитан';
  end if;

  perform tests.logout();
  raise notice 'OK: (д) single: верный/неверный ответ, нормализация ''012'' = ''12''';
end
$$;

-- pair: лишние пробелы не влияют
do $$
declare
  v_alice uuid;
  v_task  uuid;
  v_res   jsonb;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_task  from public.tasks where slug = 't-pair';

  perform tests.login(v_alice);

  v_res := public.submit_solution(v_task, 'solve()', '  12   7 ');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): нормализация pair: ''  12   7 '' должен равняться ''12 7''';
  end if;

  v_res := public.submit_solution(v_task, 'solve()', '12 7');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): верный ответ ''12 7'' (pair) не засчитан';
  end if;

  perform tests.logout();
  raise notice 'OK: (д) pair: ''  12   7 '' и ''12 7'' эквивалентны';
end
$$;

-- string: регистр значим
do $$
declare
  v_alice uuid;
  v_task  uuid;
  v_res   jsonb;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_task  from public.tasks where slug = 't-string';

  perform tests.login(v_alice);

  v_res := public.submit_solution(v_task, 'solve()', 'abc');
  if (v_res ->> 'is_correct')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): для string регистр должен быть значим (''abc'' <> ''AbC'')';
  end if;

  v_res := public.submit_solution(v_task, 'solve()', 'AbC');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (д): верный ответ ''AbC'' (string) не засчитан';
  end if;

  perform tests.logout();
  raise notice 'OK: (д) string: регистр значим';
end
$$;

-- =============================================================================
-- (е) Rate limit: при лимите 3 четвёртая отправка подряд — [rate_limit]
-- =============================================================================
do $$
declare
  v_carol uuid;
  v_task  uuid;
  i       int;
begin
  select id into v_carol from public.profiles where username = 'carol';
  select id into v_task  from public.tasks where slug = 't-single';

  update public.app_settings set value = '3'::jsonb where key = 'submissions_per_minute';

  perform tests.login(v_carol);

  -- три отправки проходят (правильность ответа не важна, важен счётчик)
  for i in 1..3 loop
    perform public.submit_solution(v_task, 'try ' || i, '7');
  end loop;

  -- четвёртая — отклоняется
  begin
    perform public.submit_solution(v_task, 'try 4', '7');
    raise exception 'ТЕСТ ПРОВАЛЕН (е): четвёртая отправка при лимите 3 прошла';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[rate_limit]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (е): ожидалась ошибка [rate_limit], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (е) rate limit: четвёртая отправка подряд отклонена с [rate_limit]';
  end;

  perform tests.logout();

  -- вернуть лимит по умолчанию
  update public.app_settings set value = '10'::jsonb where key = 'submissions_per_minute';
end
$$;

-- =============================================================================
-- (ж) Изоляция попыток между студентами
-- Блоки разнесены по транзакциям, чтобы created_at попыток Боба различались
-- (это же использует проверка хронологии в (и)).
-- =============================================================================

-- Боб: неверная попытка по t-pair
do $$
declare
  v_bob  uuid;
  v_pair uuid;
  v_res  jsonb;
begin
  select id into v_bob  from public.profiles where username = 'bob';
  select id into v_pair from public.tasks where slug = 't-pair';

  perform tests.login(v_bob);
  v_res := public.submit_solution(v_pair, 'guess', '1 2');
  if (v_res ->> 'is_correct')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): неверный ответ Боба засчитан';
  end if;
  perform tests.logout();
end
$$;

-- Боб: верные попытки по t-pair и t-other
do $$
declare
  v_bob   uuid;
  v_pair  uuid;
  v_other uuid;
  v_res   jsonb;
begin
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_pair  from public.tasks where slug = 't-pair';
  select id into v_other from public.tasks where slug = 't-other';

  perform tests.login(v_bob);

  v_res := public.submit_solution(v_pair, 'sol1', '12 7');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): верный ответ Боба по t-pair не засчитан';
  end if;

  v_res := public.submit_solution(v_other, 'sol-other', '3 4');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): верный ответ Боба по t-other не засчитан';
  end if;

  perform tests.logout();
end
$$;

-- До публикации Алиса не видит попыток Боба вообще
do $$
declare
  v_alice uuid;
  v_bob   uuid;
  v_cnt   bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_bob   from public.profiles where username = 'bob';

  perform tests.login(v_alice);
  select count(*) into v_cnt from public.submissions where user_id = v_bob;
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): до публикации Алиса видит % попыток Боба', v_cnt;
  end if;
  perform tests.logout();

  raise notice 'OK: (ж) до публикации чужие попытки не видны';
end
$$;

-- Боб: вторая верная по t-pair (останется неопубликованной),
-- затем сам публикует первую верную по t-pair и попытку по t-other
do $$
declare
  v_bob       uuid;
  v_pair      uuid;
  v_other     uuid;
  v_res       jsonb;
  v_pub_pair  uuid;
  v_pub_other uuid;
begin
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_pair  from public.tasks where slug = 't-pair';
  select id into v_other from public.tasks where slug = 't-other';

  perform tests.login(v_bob);
  v_res := public.submit_solution(v_pair, 'sol2', '12 7');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): вторая верная попытка Боба не засчитана';
  end if;
  perform tests.logout();

  -- id первой (самой ранней) верной попытки по каждой задаче — от суперпользователя
  select id into v_pub_pair
    from public.submissions
   where user_id = v_bob and task_id = v_pair and is_correct
   order by created_at
   limit 1;
  select id into v_pub_other
    from public.submissions
   where user_id = v_bob and task_id = v_other and is_correct
   order by created_at
   limit 1;

  perform tests.login(v_bob);
  perform public.set_solution_published(v_pub_pair, true);
  perform public.set_solution_published(v_pub_other, true);
  perform tests.logout();

  raise notice 'OK: (ж) Боб опубликовал по одной верной попытке (t-pair и t-other)';
end
$$;

-- Алиса (решила t-pair, но не t-other) видит РОВНО опубликованную попытку
-- Боба по t-pair; неопубликованные и попытки по другим задачам — нет
do $$
declare
  v_alice    uuid;
  v_bob      uuid;
  v_pair     uuid;
  v_other    uuid;
  v_pub_pair uuid;
  v_id       uuid;
  v_pub      boolean;
  v_cnt      bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_pair  from public.tasks where slug = 't-pair';
  select id into v_other from public.tasks where slug = 't-other';
  select id into v_pub_pair
    from public.submissions
   where user_id = v_bob and task_id = v_pair and is_correct
   order by created_at
   limit 1;

  perform tests.login(v_alice);

  select count(*) into v_cnt from public.submissions where user_id = v_bob;
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): Алиса видит % попыток Боба, ожидалась ровно 1 (опубликованная по t-pair)', v_cnt;
  end if;

  select id, is_published into v_id, v_pub
    from public.submissions
   where user_id = v_bob and task_id = v_pair;
  if v_id is distinct from v_pub_pair or v_pub is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): Алисе видна не та попытка Боба по t-pair (или она не опубликована)';
  end if;

  select count(*) into v_cnt
    from public.submissions
   where user_id = v_bob and task_id = v_other;
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (ж): Алисе видна попытка Боба по t-other, которую Алиса не решала';
  end if;

  perform tests.logout();
  raise notice 'OK: (ж) после публикации видны ровно опубликованные попытки по решённой задаче';
end
$$;

-- =============================================================================
-- (з) set_solution_published
-- =============================================================================
do $$
declare
  v_alice         uuid;
  v_bob           uuid;
  v_single        uuid;
  v_pair          uuid;
  v_bob_sub       uuid;
  v_alice_wrong   uuid;
  v_alice_correct uuid;
  v_pub_at        timestamptz;
begin
  select id into v_alice  from public.profiles where username = 'alice';
  select id into v_bob    from public.profiles where username = 'bob';
  select id into v_single from public.tasks where slug = 't-single';
  select id into v_pair   from public.tasks where slug = 't-pair';

  -- попытки для проверок — от суперпользователя
  select id into v_bob_sub
    from public.submissions
   where user_id = v_bob and task_id = v_pair and is_correct
   order by created_at
   limit 1;
  select id into v_alice_wrong
    from public.submissions
   where user_id = v_alice and task_id = v_single and not is_correct
   order by created_at
   limit 1;
  select id into v_alice_correct
    from public.submissions
   where user_id = v_alice and task_id = v_single and is_correct
   order by created_at
   limit 1;

  perform tests.login(v_alice);

  -- чужая попытка
  begin
    perform public.set_solution_published(v_bob_sub, true);
    raise exception 'ТЕСТ ПРОВАЛЕН (з): Алиса опубликовала чужую попытку';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[not_owner]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (з): ожидалась ошибка [not_owner], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (з) публикация чужой попытки — [not_owner]';
  end;

  -- своя, но неверная
  begin
    perform public.set_solution_published(v_alice_wrong, true);
    raise exception 'ТЕСТ ПРОВАЛЕН (з): опубликована неверная попытка';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[not_correct]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (з): ожидалась ошибка [not_correct], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (з) публикация своей неверной попытки — [not_correct]';
  end;

  -- своя верная: публикация
  perform public.set_solution_published(v_alice_correct, true);
  select published_at into v_pub_at from public.submissions where id = v_alice_correct;
  if v_pub_at is null then
    raise exception 'ТЕСТ ПРОВАЛЕН (з): после публикации published_at пуст';
  end if;
  raise notice 'OK: (з) публикация своей верной попытки: published_at заполнен';

  -- снятие публикации
  perform public.set_solution_published(v_alice_correct, false);
  select published_at into v_pub_at from public.submissions where id = v_alice_correct;
  if v_pub_at is not null then
    raise exception 'ТЕСТ ПРОВАЛЕН (з): после снятия публикации published_at не очищен';
  end if;
  raise notice 'OK: (з) снятие публикации: published_at очищен';

  perform tests.logout();
end
$$;

-- =============================================================================
-- (и) admin_* функции
-- =============================================================================

-- Под студентом — [forbidden]
do $$
declare
  v_alice uuid;
  v_pair  uuid;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_pair  from public.tasks where slug = 't-pair';

  perform tests.login(v_alice);

  begin
    perform 1 from public.admin_list_students();
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_list_students доступна студенту';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[forbidden]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (и): ожидалась ошибка [forbidden], получено: %', sqlerrm;
    end if;
  end;

  begin
    perform public.admin_get_task_answer(v_pair);
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_get_task_answer доступна студенту';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[forbidden]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (и): ожидалась ошибка [forbidden], получено: %', sqlerrm;
    end if;
  end;

  perform tests.logout();
  raise notice 'OK: (и) admin_* функции под студентом падают с [forbidden]';
end
$$;

-- Сетап: у админа должны быть собственные попытки (для проверки исключения)
do $$
declare
  v_admin  uuid;
  v_single uuid;
  v_res    jsonb;
begin
  select id into v_admin  from public.profiles where username = 'boss';
  select id into v_single from public.tasks where slug = 't-single';

  perform tests.login(v_admin);
  v_res := public.submit_solution(v_single, 'admin solve', '12');
  if (v_res ->> 'is_correct')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): верный ответ админа не засчитан';
  end if;
  perform tests.logout();
end
$$;

-- Под админом
do $$
declare
  v_admin  uuid;
  v_bob    uuid;
  v_pair   uuid;
  v_answer text;
  v_cnt    bigint;
  v_prev   timestamptz;
  v_found  boolean;
  r        record;
begin
  select id into v_admin from public.profiles where username = 'boss';
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_pair  from public.tasks where slug = 't-pair';

  perform tests.login(v_admin);

  -- admin_list_students: без админов, студенты на месте
  select count(*) into v_cnt from public.admin_list_students() s where s.user_id = v_admin;
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_list_students содержит админа';
  end if;
  select count(*) into v_cnt from public.admin_list_students();
  if v_cnt < 3 then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_list_students вернула % строк, ожидалось минимум 3 студента', v_cnt;
  end if;
  raise notice 'OK: (и) admin_list_students не содержит админов';

  -- admin_get_task_answer возвращает эталон
  v_answer := public.admin_get_task_answer(v_pair);
  if v_answer is distinct from '12 7' then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_get_task_answer вернула %, ожидалось ''12 7''', coalesce(v_answer, '<null>');
  end if;
  raise notice 'OK: (и) admin_get_task_answer возвращает эталонный ответ';

  -- admin_task_attempts: все попытки Боба по t-pair в хронологическом порядке
  v_prev := null;
  v_cnt  := 0;
  for r in select * from public.admin_task_attempts(v_bob, v_pair) loop
    v_cnt := v_cnt + 1;
    if v_prev is not null and r.created_at < v_prev then
      raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_task_attempts вернула попытки не в хронологическом порядке';
    end if;
    v_prev := r.created_at;
  end loop;
  if v_cnt <> 3 then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_task_attempts вернула % попыток Боба по t-pair, ожидалось 3', v_cnt;
  end if;
  raise notice 'OK: (и) admin_task_attempts: 3 попытки в хронологическом порядке';

  -- admin_recent_submissions: попыток самого админа нет
  select count(*) into v_cnt from public.admin_recent_submissions() s where s.user_id = v_admin;
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): admin_recent_submissions содержит попытки самого админа';
  end if;
  raise notice 'OK: (и) admin_recent_submissions не содержит попыток админа';

  -- фильтр p_is_correct
  v_found := false;
  for r in select * from public.admin_recent_submissions(p_is_correct => false) loop
    v_found := true;
    if r.is_correct then
      raise exception 'ТЕСТ ПРОВАЛЕН (и): фильтр p_is_correct = false вернул верную попытку';
    end if;
  end loop;
  if not v_found then
    raise exception 'ТЕСТ ПРОВАЛЕН (и): фильтр p_is_correct = false не вернул ни одной строки';
  end if;
  raise notice 'OK: (и) admin_recent_submissions уважает фильтр p_is_correct';

  perform tests.logout();
end
$$;

-- =============================================================================
-- (к) get_user_progress
-- Ожидаемые данные Алисы: №2 — решена 1 из 2 (t-pair, но не t-other);
-- №5 — решена 1 из 1 (t-single).
-- =============================================================================
do $$
declare
  v_alice  uuid;
  v_bob    uuid;
  v_admin  uuid;
  v_solved bigint;
  v_total  bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_admin from public.profiles where username = 'boss';

  -- студент о себе
  perform tests.login(v_alice);

  select p.solved, p.total into v_solved, v_total
    from public.get_user_progress(v_alice) p
   where p.ege_number = 2;
  if v_solved is distinct from 1 or v_total is distinct from 2 then
    raise exception 'ТЕСТ ПРОВАЛЕН (к): прогресс Алисы по №2: solved = %, total = %, ожидалось 1 из 2', v_solved, v_total;
  end if;

  select p.solved, p.total into v_solved, v_total
    from public.get_user_progress(v_alice) p
   where p.ege_number = 5;
  if v_solved is distinct from 1 or v_total is distinct from 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (к): прогресс Алисы по №5: solved = %, total = %, ожидалось 1 из 1', v_solved, v_total;
  end if;
  raise notice 'OK: (к) get_user_progress о себе: числа соответствуют данным';

  -- студент о чужом — [forbidden]
  begin
    perform 1 from public.get_user_progress(v_bob);
    raise exception 'ТЕСТ ПРОВАЛЕН (к): студент получил прогресс другого студента';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[forbidden]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (к): ожидалась ошибка [forbidden], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (к) get_user_progress о чужом — [forbidden]';
  end;

  perform tests.logout();

  -- админ о любом
  perform tests.login(v_admin);
  select p.solved, p.total into v_solved, v_total
    from public.get_user_progress(v_alice) p
   where p.ege_number = 2;
  if v_solved is distinct from 1 or v_total is distinct from 2 then
    raise exception 'ТЕСТ ПРОВАЛЕН (к): админ видит прогресс Алисы по №2: solved = %, total = %, ожидалось 1 из 2', v_solved, v_total;
  end if;
  perform tests.logout();
  raise notice 'OK: (к) get_user_progress: админ видит прогресс любого студента';
end
$$;

-- =============================================================================
-- (л) admin_reset_password
-- =============================================================================
do $$
declare
  v_alice uuid;
  v_bob   uuid;
  v_admin uuid;
  v_old   text;
  v_new   text;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_bob   from public.profiles where username = 'bob';
  select id into v_admin from public.profiles where username = 'boss';

  -- под студентом — [forbidden]
  perform tests.login(v_alice);
  begin
    perform public.admin_reset_password(v_bob, 'correct-horse-battery');
    raise exception 'ТЕСТ ПРОВАЛЕН (л): студент сменил чужой пароль';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[forbidden]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (л): ожидалась ошибка [forbidden], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (л) admin_reset_password под студентом — [forbidden]';
  end;
  perform tests.logout();

  -- запомнить старый хэш (от суперпользователя)
  select encrypted_password into v_old from auth.users where id = v_bob;

  perform tests.login(v_admin);

  -- нормальный пароль — проходит
  perform public.admin_reset_password(v_bob, 'newStrongPass123');

  -- короткий пароль — [weak_password]
  begin
    perform public.admin_reset_password(v_bob, '123');
    raise exception 'ТЕСТ ПРОВАЛЕН (л): короткий пароль принят';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[weak_password]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (л): ожидалась ошибка [weak_password], получено: %', sqlerrm;
    end if;
    raise notice 'OK: (л) короткий пароль — [weak_password]';
  end;

  perform tests.logout();

  -- хэш действительно изменился
  select encrypted_password into v_new from auth.users where id = v_bob;
  if v_new is null or v_new is not distinct from v_old then
    raise exception 'ТЕСТ ПРОВАЛЕН (л): encrypted_password не изменился после admin_reset_password';
  end if;
  raise notice 'OK: (л) admin_reset_password под админом: encrypted_password изменился';
end
$$;

-- =============================================================================
-- (м) get_task_stats: статистика считается только по студентам
-- По t-other пока отправлял только Боб (решил): attempted = 1, solved = 1.
-- Попытка админа не должна изменить ни одно из чисел.
-- =============================================================================
do $$
declare
  v_admin uuid;
  v_other uuid;
  v_att1  bigint;
  v_solv1 bigint;
  v_pct1  numeric;
  v_att2  bigint;
  v_solv2 bigint;
  v_pct2  numeric;
  v_res   jsonb;
begin
  select id into v_admin from public.profiles where username = 'boss';
  select id into v_other from public.tasks where slug = 't-other';

  perform tests.login(v_admin);

  select s.attempted_students, s.solved_students, s.solved_percent
    into v_att1, v_solv1, v_pct1
    from public.get_task_stats() s
   where s.task_id = v_other;

  if v_att1 is distinct from 1 or v_solv1 is distinct from 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (м): статистика t-other: attempted = %, solved = %, ожидалось 1 и 1 (только Боб)', v_att1, v_solv1;
  end if;

  -- неверная попытка админа
  v_res := public.submit_solution(v_other, 'admin try', '9 9');
  if (v_res ->> 'is_correct')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (м): неверный ответ админа засчитан';
  end if;

  select s.attempted_students, s.solved_students, s.solved_percent
    into v_att2, v_solv2, v_pct2
    from public.get_task_stats() s
   where s.task_id = v_other;

  if v_att2 is distinct from v_att1
     or v_solv2 is distinct from v_solv1
     or v_pct2 is distinct from v_pct1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (м): попытка админа изменила статистику: attempted % -> %, solved % -> %, percent % -> %',
      v_att1, v_att2, v_solv1, v_solv2, v_pct1, v_pct2;
  end if;

  perform tests.logout();
  raise notice 'OK: (м) get_task_stats: solved_percent считается только по студентам';
end
$$;

-- =============================================================================
-- (н) Content API: контент создаётся только через admin_* RPC
-- =============================================================================

-- Статья справочника и задача через API; проверка полей и идемпотентности
do $$
declare
  v_admin uuid;
  v_res   jsonb;
  v_task  jsonb;
  v_cnt   bigint;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  v_res := public.admin_upsert_article(jsonb_build_object(
    'slug',            'file-reading',
    'title',           'Чтение файлов в Python',
    'summary',         'Как открыть файл и пройти его построчно.',
    'content_md',      repeat('Статья про чтение файлов и обработку строк. ', 10),
    'ege_numbers',     jsonb_build_array(17, 24),
    'tags',            jsonb_build_array('files'),
    'level',           1,
    'reading_minutes', 6,
    'is_published',    true
  ));
  if (v_res ->> 'created')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): статья справочника не создана';
  end if;

  v_res := public.admin_upsert_task(jsonb_build_object(
    'slug',               'ege24-demo-01',
    'ege_number',         24,
    'title',              'Демонстрационная задача 24',
    'statement_md',       'Найдите наибольшую длину подпоследовательности в файле 24.txt.',
    'difficulty',         2,
    'answer_format',      'single',
    'answer',             '1523',
    'reference_solution', 'print(1523)',
    'answer_explanation', 'Скользящее окно',
    'status',             'review',
    'origin',             'ai',
    'tags',               jsonb_build_array('strings'),
    'files',              jsonb_build_array(
                            jsonb_build_object('filename', '24.txt', 'content', 'ABCABC')
                          ),
    'references',         jsonb_build_array(
                            jsonb_build_object('slug', 'file-reading', 'relevance', 'primary')
                          )
  ));
  if (v_res ->> 'created')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): задача не создана';
  end if;

  v_task := public.admin_get_task('ege24-demo-01');
  if v_task ->> 'answer' is distinct from '1523'
     or jsonb_array_length(v_task -> 'files') <> 1
     or jsonb_array_length(v_task -> 'references') <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): admin_get_task вернул не всё: %', v_task;
  end if;

  -- Повторный вызов обновляет ту же задачу, а не создаёт вторую
  v_res := public.admin_upsert_task(jsonb_build_object(
    'slug',               'ege24-demo-01',
    'ege_number',         24,
    'title',              'Демонстрационная задача 24 (правка)',
    'statement_md',       'Найдите наибольшую длину подпоследовательности в файле 24.txt.',
    'difficulty',         2,
    'answer_format',      'single',
    'answer',             '1523',
    'reference_solution', 'print(1523)',
    'status',             'review',
    'files',              jsonb_build_array(
                            jsonb_build_object('filename', '24.txt', 'content', 'ABCABCABC')
                          )
  ));
  if (v_res ->> 'created')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): повторный upsert создал новую задачу';
  end if;

  select count(*) into v_cnt from public.tasks where slug = 'ege24-demo-01';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): после повторного upsert задач с тем же slug: %', v_cnt;
  end if;

  -- Файлы заменяются целиком, а не накапливаются
  select count(*) into v_cnt
    from public.task_files f
    join public.tasks t on t.id = f.task_id
   where t.slug = 'ege24-demo-01';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): файлов после замены %, ожидался 1', v_cnt;
  end if;

  -- Связи со справочником пересобраны: в повторном вызове их не было
  select count(*) into v_cnt
    from public.task_references r
    join public.tasks t on t.id = r.task_id
   where t.slug = 'ege24-demo-01';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): связи со справочником не пересобраны (осталось %)', v_cnt;
  end if;

  perform tests.logout();
  raise notice 'OK: (н) admin_upsert_task создаёт и идемпотентно обновляет задачу целиком';
end
$$;

-- Валидация payload: каждая ошибка отклоняется с понятным кодом
do $$
declare
  v_admin uuid;
  v_base  jsonb;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  v_base := jsonb_build_object(
    'slug',               'ege24-bad-01',
    'ege_number',         24,
    'title',              'Проверка валидации',
    'statement_md',       'Условие достаточной длины для прохождения проверки минимума.',
    'difficulty',         2,
    'answer_format',      'single',
    'answer',             '42',
    'reference_solution', 'print(42)',
    'status',             'draft'
  );

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('ege_number', 42));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принят ege_number вне диапазона';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) ege_number вне диапазона отклонён (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('answer', '   '));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принят пустой ответ';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) пустой ответ отклонён (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('answer', 'не число'));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): ответ не по формату single принят';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) ответ не по формату отклонён (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('statement_md', 'Коротко'));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принято слишком короткое условие';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) короткое условие отклонено (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object(
      'status', 'review', 'reference_solution', null));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): review без эталонного решения принят';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) review без эталона отклонён (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('files', jsonb_build_array(
      jsonb_build_object('filename', '../etc/passwd', 'content', 'x'))));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принято имя файла с путём';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) имя файла с путём отклонено (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('files', jsonb_build_array(
      jsonb_build_object('filename', 'big.txt', 'content', repeat('x', 4194305)))));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принят файл больше 4 МБ';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) файл больше 4 МБ отклонён (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task(v_base || jsonb_build_object('references', jsonb_build_array(
      jsonb_build_object('slug', 'no-such-article', 'relevance', 'primary'))));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): принята ссылка на несуществующую статью';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) ссылка на несуществующую статью отклонена (%)', sqlerrm;
  end;

  perform tests.logout();
end
$$;

-- Транзакционность: ошибка в файлах не оставляет ни задачи, ни ответа
do $$
declare
  v_admin uuid;
  v_cnt   bigint;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  begin
    perform public.admin_upsert_task(jsonb_build_object(
      'slug',               'ege24-atomic-01',
      'ege_number',         24,
      'title',              'Атомарность',
      'statement_md',       'Условие достаточной длины для прохождения проверки минимума.',
      'difficulty',         1,
      'answer_format',      'single',
      'answer',             '7',
      'reference_solution', 'print(7)',
      'status',             'draft',
      'files',              jsonb_build_array(
                              jsonb_build_object('filename', 'ok.txt', 'content', 'данные'),
                              jsonb_build_object('filename', 'bad name.txt', 'content', 'x')
                            )
    ));
    raise exception 'ТЕСТ ПРОВАЛЕН (н): задача с битым именем файла создалась';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) вызов с битым файлом отклонён (%)', sqlerrm;
  end;

  -- Проверяем от суперпользователя: task_answers закрыта даже админу
  perform tests.logout();

  select count(*) into v_cnt from public.tasks where slug = 'ege24-atomic-01';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): после ошибки осталась задача';
  end if;

  select count(*) into v_cnt
    from public.task_answers ta
    join public.tasks t on t.id = ta.task_id
   where t.slug = 'ege24-atomic-01';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): после ошибки остался эталонный ответ';
  end if;
  raise notice 'OK: (н) при ошибке в одном файле не создаётся ни задачи, ни ответа';
end
$$;

-- Публикация только после совпадения вывода эталона с ответом
do $$
declare
  v_admin  uuid;
  v_res    jsonb;
  v_status text;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  begin
    perform public.admin_set_task_status('ege24-demo-01', 'published');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): задача опубликована без проверки эталона';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) публикация без проверки эталона отклонена (%)', sqlerrm;
  end;

  -- Вывод эталона не совпал с ответом: отметки о проверке нет
  v_res := public.admin_verify_reference('ege24-demo-01', '999');
  if (v_res ->> 'matches')::boolean is not false then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): неверный вывод эталона признан совпавшим';
  end if;

  begin
    perform public.admin_set_task_status('ege24-demo-01', 'published');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): задача с неверным эталоном опубликована';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) после неудачной сверки публикация запрещена (%)', sqlerrm;
  end;

  -- Совпало (сравнение нормализованное: лишние пробелы не мешают)
  v_res := public.admin_verify_reference('ege24-demo-01', ' 1523 ');
  if (v_res ->> 'matches')::boolean is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): верный вывод эталона не признан совпавшим';
  end if;

  perform public.admin_set_task_status('ege24-demo-01', 'published');
  select status into v_status from public.tasks where slug = 'ege24-demo-01';
  if v_status is distinct from 'published' then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): статус после публикации = %', v_status;
  end if;

  perform tests.logout();
  raise notice 'OK: (н) публикация возможна только после сверки вывода эталона с ответом';
end
$$;

-- Ученик не получает эталон, разбор и черновики ни одним путём
do $$
declare
  v_alice uuid;
  v_cnt   bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  perform tests.login(v_alice);

  begin
    perform reference_solution from public.tasks where slug = 'ege24-demo-01';
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент прочитал reference_solution напрямую';
  exception when insufficient_privilege then
    raise notice 'OK: (н) select reference_solution под студентом — permission denied';
  end;

  begin
    perform answer_explanation from public.tasks where slug = 'ege24-demo-01';
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент прочитал answer_explanation напрямую';
  exception when insufficient_privilege then
    raise notice 'OK: (н) select answer_explanation под студентом — permission denied';
  end;

  -- Представление для учеников отдаёт только опубликованные задачи
  select count(*) into v_cnt from public.tasks_public where slug = 't-unpub';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): черновик виден в tasks_public';
  end if;
  select count(*) into v_cnt from public.tasks_public where slug = 'ege24-demo-01';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): опубликованная задача не видна в tasks_public';
  end if;

  -- Админские RPC под студентом
  begin
    perform public.admin_get_task('ege24-demo-01');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент получил задачу через admin_get_task';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) admin_get_task под студентом — отказ (%)', sqlerrm;
  end;

  begin
    perform public.admin_list_tasks('{}'::jsonb);
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент получил список через admin_list_tasks';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) admin_list_tasks под студентом — отказ (%)', sqlerrm;
  end;

  begin
    perform public.admin_upsert_task('{"slug":"hack-01"}'::jsonb);
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент создал задачу через admin_upsert_task';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) admin_upsert_task под студентом — отказ (%)', sqlerrm;
  end;

  begin
    perform public.admin_delete_task('ege24-demo-01');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент удалил задачу';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) admin_delete_task под студентом — отказ (%)', sqlerrm;
  end;

  perform tests.logout();
end
$$;

-- Файлы и справочник: что видно ученику и что закрыто на запись
do $$
declare
  v_alice uuid;
  v_admin uuid;
  v_task  uuid;
  v_cnt   bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  select id into v_admin from public.profiles where username = 'boss';
  select id into v_task  from public.tasks where slug = 't-unpub';

  -- Файл к черновику — от имени супер-пользователя (тестовый сетап)
  insert into public.task_files (task_id, filename, content)
  values (v_task, 'hidden.txt', 'секрет')
  on conflict (task_id, filename) do nothing;

  perform tests.login(v_alice);

  select count(*) into v_cnt from public.task_files f
   where f.filename = 'hidden.txt';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студенту виден файл неопубликованной задачи';
  end if;

  select count(*) into v_cnt from public.task_files f
    join public.tasks t on t.id = f.task_id
   where t.slug = 'ege24-demo-01';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студенту не виден файл опубликованной задачи (%)', v_cnt;
  end if;

  begin
    insert into public.task_files (task_id, filename, content)
    values (v_task, 'mine.txt', 'x');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент записал файл задачи напрямую';
  exception when insufficient_privilege then
    raise notice 'OK: (н) прямая запись в task_files под студентом — permission denied';
  end;

  select count(*) into v_cnt from public.reference_articles where slug = 'file-reading';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студенту не видна опубликованная статья';
  end if;

  begin
    perform public.admin_upsert_article('{"slug":"hack-article"}'::jsonb);
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студент создал статью';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) admin_upsert_article под студентом — отказ (%)', sqlerrm;
  end;

  begin
    perform 1 from public.audit_log;
    if found then
      raise exception 'ТЕСТ ПРОВАЛЕН (н): студент читает журнал действий';
    end if;
    raise notice 'OK: (н) журнал действий студенту пуст (политика RLS)';
  exception when insufficient_privilege then
    raise notice 'OK: (н) audit_log под студентом — permission denied';
  end;

  perform tests.logout();

  -- Неопубликованная статья студенту не видна
  perform tests.login(v_admin);
  perform public.admin_upsert_article(jsonb_build_object(
    'slug',       'draft-article',
    'title',      'Черновик статьи',
    'summary',    'Ещё не опубликована.',
    'content_md', repeat('Черновик статьи справочника. ', 10)
  ));
  perform tests.logout();

  perform tests.login(v_alice);
  select count(*) into v_cnt from public.reference_articles where slug = 'draft-article';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): студенту видна неопубликованная статья';
  end if;
  perform tests.logout();

  raise notice 'OK: (н) файлы и статьи видны ученику только для опубликованного контента';
end
$$;

-- Журнал действий и ограничение частоты записи
do $$
declare
  v_admin uuid;
  v_cnt   bigint;
begin
  select id into v_admin from public.profiles where username = 'boss';

  select count(*) into v_cnt
    from public.audit_log
   where actor_id = v_admin and entity_slug = 'ege24-demo-01';
  if v_cnt = 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (н): действия над задачей не попали в журнал';
  end if;

  -- Временно ужимаем лимит до одной записи в минуту
  update public.app_settings set value = '1'::jsonb
   where key = 'content_writes_per_minute';

  perform tests.login(v_admin);
  begin
    perform public.admin_set_task_status('ege24-demo-01', 'draft');
    raise exception 'ТЕСТ ПРОВАЛЕН (н): лимит частоты записи не сработал';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (н) лимит частоты записи сработал (%)', sqlerrm;
  end;
  perform tests.logout();

  update public.app_settings set value = '60'::jsonb
   where key = 'content_writes_per_minute';

  raise notice 'OK: (н) действия пишутся в audit_log, частота записи ограничена';
end
$$;

-- =============================================================================
-- (о) Темы кодификатора: связь с заданиями и справка через темы
-- =============================================================================

-- Подготовка: тема, статья по теме и две задачи — с темой и без темы.
do $$
declare
  v_admin uuid;
begin
  select id into v_admin from public.profiles where username = 'boss';

  -- Раздел делает несколько записей подряд, поэтому лимит частоты снимаем.
  update public.app_settings set value = '1000'::jsonb
   where key = 'content_writes_per_minute';

  insert into public.themes (code, title, section_code, section_title, level, sort_order)
  values ('9.9', 'Тестовая тема', '9', 'Тестовый раздел', 'УУ', 1)
  on conflict (code) do nothing;

  perform tests.login(v_admin);

  perform public.admin_upsert_article(jsonb_build_object(
    'slug',         'kes-9-9',
    'title',        'Статья тестовой темы',
    'summary',      'Одна тема — одна статья.',
    'content_md',   repeat('Содержимое статьи тестовой темы. ', 10),
    'theme_code',   '9.9',
    'is_published', true
  ));

  -- Задача банка: без номера, без ответа, происхождение fipi.
  perform public.admin_upsert_task(jsonb_build_object(
    'slug',          'fipi-test01',
    'title',         'Задание банка без номера и ответа',
    'statement_md',  'Условие достаточной длины для прохождения проверки минимума.',
    'difficulty',    3,
    'answer_format', 'string',
    'origin',        'fipi',
    'themes',        jsonb_build_array('9.9')
  ));

  -- Задача, которой тему не задали вовсе.
  perform public.admin_upsert_task(jsonb_build_object(
    'slug',          'fipi-test02',
    'title',         'Задание без темы',
    'statement_md',  'Условие достаточной длины для прохождения проверки минимума.',
    'difficulty',    1,
    'answer_format', 'single',
    'origin',        'fipi'
  ));

  perform tests.logout();
end
$$;

-- Проверки: отложенный триггер срабатывает на границе транзакции, поэтому
-- результат смотрим уже следующей командой.
do $$
declare
  v_admin uuid;
  v_task  uuid;
  v_cnt   bigint;
  v_code  text;
begin
  select id into v_admin from public.profiles where username = 'boss';

  select t.id into v_task from public.tasks t where t.slug = 'fipi-test01';
  select count(*) into v_cnt from public.task_themes where task_id = v_task;
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): тема задачи не сохранилась (%)', v_cnt;
  end if;
  raise notice 'OK: (о) admin_upsert_task сохраняет темы задачи';

  if (select ege_number from public.tasks where id = v_task) is not null then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): задача без номера получила номер';
  end if;
  if (select origin from public.tasks where id = v_task) <> 'fipi' then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): origin fipi не сохранился';
  end if;
  if exists (select 1 from public.task_answers where task_id = v_task) then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): у задачи без ответа появился ответ';
  end if;
  raise notice 'OK: (о) задача банка сохраняется без номера и без ответа';

  select count(*) into v_cnt from public.task_articles where task_id = v_task;
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): справка по теме не выводится (%)', v_cnt;
  end if;
  raise notice 'OK: (о) task_articles отдаёт статью задачи по её теме';

  -- Задача, которой тему не задали, получает служебную none.
  select tt.theme_code into v_code
    from public.task_themes tt
    join public.tasks t on t.id = tt.task_id
   where t.slug = 'fipi-test02';
  if v_code is distinct from 'none' then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): задача без темы не получила none (%)', v_code;
  end if;
  raise notice 'OK: (о) задача без темы получает служебную тему none';

  -- Тема, которой нет в кодификаторе, не принимается.
  perform tests.login(v_admin);
  begin
    perform public.admin_upsert_task(jsonb_build_object(
      'slug',          'fipi-test01',
      'title',         'Задание банка без номера и ответа',
      'statement_md',  'Условие достаточной длины для прохождения проверки минимума.',
      'difficulty',    3,
      'answer_format', 'string',
      'origin',        'fipi',
      'themes',        jsonb_build_array('42.42')
    ));
    raise exception 'ТЕСТ ПРОВАЛЕН (о): принята тема вне кодификатора';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (о) тема вне кодификатора отклонена (%)', sqlerrm;
  end;
  perform tests.logout();
end
$$;

-- Снятие последней темы возвращает служебную none.
do $$
declare
  v_task uuid;
begin
  select id into v_task from public.tasks where slug = 'fipi-test01';
  delete from public.task_themes where task_id = v_task;
end
$$;

do $$
declare
  v_code text;
begin
  select tt.theme_code into v_code
    from public.task_themes tt
    join public.tasks t on t.id = tt.task_id
   where t.slug = 'fipi-test01';
  if v_code is distinct from 'none' then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): после снятия тем задача осталась без темы (%)',
      coalesce(v_code, 'нет строк');
  end if;
  raise notice 'OK: (о) последнюю тему снять нельзя — вместо неё встаёт none';

  update public.app_settings set value = '60'::jsonb
   where key = 'content_writes_per_minute';
end
$$;

-- Что видно ученику
do $$
declare
  v_alice uuid;
  v_cnt   bigint;
begin
  select id into v_alice from public.profiles where username = 'alice';
  perform tests.login(v_alice);

  select count(*) into v_cnt from public.themes;
  if v_cnt = 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): кодификатор ученику не виден';
  end if;
  raise notice 'OK: (о) кодификатор тем виден ученику';

  select count(*) into v_cnt
    from public.task_themes tt
    join public.tasks t on t.id = tt.task_id
   where t.slug = 'fipi-test01';
  if v_cnt <> 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (о): ученику видны темы черновика (%)', v_cnt;
  end if;
  raise notice 'OK: (о) темы неопубликованной задачи ученику не видны';

  begin
    insert into public.task_themes (task_id, theme_code)
    select t.id, '9.9' from public.tasks t where t.slug = 'ege24-demo-01';
    raise exception 'ТЕСТ ПРОВАЛЕН (о): ученик записал тему напрямую';
  exception when insufficient_privilege then
    raise notice 'OK: (о) прямая запись в task_themes под учеником — permission denied';
  end;

  perform tests.logout();
end
$$;

-- =============================================================================
-- (п) Права клиентских ролей
--
-- Шим повторяет права по умолчанию Supabase, поэтому лишнее, что миграции
-- забыли снять, здесь видно так же, как на боевой базе.
-- =============================================================================

-- task_articles: ученику только чтение, анониму ничего.
do $$
declare
  v_priv  text;
  v_extra text[] := '{}';
begin
  foreach v_priv in array array[
    'SELECT', 'INSERT', 'UPDATE', 'DELETE',
    'TRUNCATE', 'REFERENCES', 'TRIGGER', 'MAINTAIN'
  ] loop
    if v_priv <> 'SELECT'
       and has_table_privilege('authenticated', 'public.task_articles', v_priv) then
      v_extra := v_extra || ('authenticated ' || v_priv);
    end if;
    if has_table_privilege('anon', 'public.task_articles', v_priv) then
      v_extra := v_extra || ('anon ' || v_priv);
    end if;
  end loop;

  if cardinality(v_extra) > 0 then
    raise exception 'ТЕСТ ПРОВАЛЕН (п): лишние права на task_articles: %',
      array_to_string(v_extra, ', ');
  end if;
  if not has_table_privilege('authenticated', 'public.task_articles', 'SELECT') then
    raise exception 'ТЕСТ ПРОВАЛЕН (п): ученик не может читать task_articles';
  end if;
  raise notice 'OK: (п) task_articles: ученику только select, анониму ничего';
end
$$;

do $$
begin
  perform set_config('role', 'anon', false);
  begin
    perform 1 from public.task_articles limit 1;
    raise exception 'ТЕСТ ПРОВАЛЕН (п): аноним прочитал task_articles';
  exception when insufficient_privilege then
    raise notice 'OK: (п) аноним читает task_articles — permission denied';
  end;
  perform set_config('role', 'none', false);
end
$$;

-- Полная матрица прав anon и authenticated на объекты public. Новая таблица,
-- представление или функция, у которой миграция не сняла выданное Supabase
-- по умолчанию, этот тест не пройдёт.
do $$
declare
  v_extra   text;
  v_missing text;
begin
  create temp table privileges_actual on commit drop as
  with roles(role) as (values ('anon'), ('authenticated'))
  -- таблицы и представления
  select c.relname::text as obj, r.role,
         string_agg(p.priv, ',' order by p.priv) as privs
    from pg_class c
   cross join roles r
   cross join unnest(array[
     'SELECT', 'INSERT', 'UPDATE', 'DELETE',
     'TRUNCATE', 'REFERENCES', 'TRIGGER', 'MAINTAIN'
   ]) as p(priv)
   where c.relnamespace = 'public'::regnamespace
     and c.relkind in ('r', 'v', 'm', 'p', 'f')
     and has_table_privilege(r.role, c.oid, p.priv)
   group by 1, 2
  union all
  -- последовательности
  select c.relname::text, r.role,
         string_agg(p.priv, ',' order by p.priv)
    from pg_class c
   cross join roles r
   cross join unnest(array['SELECT', 'UPDATE', 'USAGE']) as p(priv)
   where c.relnamespace = 'public'::regnamespace
     and c.relkind = 'S'
     and has_sequence_privilege(r.role, c.oid, p.priv)
   group by 1, 2
  union all
  -- права на отдельные колонки (grant select (…) on …)
  select c.relname::text, x.grantee::regrole::text,
         format('%s(%s)', x.privilege_type,
                string_agg(a.attname::text, ',' order by a.attname))
    from pg_class c
    join pg_attribute a on a.attrelid = c.oid and a.attacl is not null
   cross join aclexplode(a.attacl) as x
   where c.relnamespace = 'public'::regnamespace
     and x.grantee in ('anon'::regrole, 'authenticated'::regrole)
   group by c.relname, x.grantee, x.privilege_type
  union all
  -- функции
  select format('%s(%s)', p.proname, oidvectortypes(p.proargtypes)), r.role,
         'EXECUTE'
    from pg_proc p
   cross join roles r
   where p.pronamespace = 'public'::regnamespace
     and has_function_privilege(r.role, p.oid, 'EXECUTE');

  create temp table privileges_expected (obj text, role text, privs text)
    on commit drop;
  insert into privileges_expected values
    ('app_settings',       'authenticated', 'SELECT,UPDATE'),
    ('audit_log',          'authenticated', 'SELECT'),
    ('profiles',           'authenticated', 'SELECT'),
    ('reference_articles', 'authenticated', 'SELECT'),
    ('submissions',        'authenticated', 'SELECT'),
    ('task_articles',      'authenticated', 'SELECT'),
    ('task_files',         'authenticated', 'SELECT'),
    ('task_references',    'authenticated', 'SELECT'),
    ('task_themes',        'authenticated', 'SELECT'),
    ('tasks_public',       'authenticated', 'SELECT'),
    ('themes',             'authenticated', 'SELECT'),
    ('tasks',              'authenticated',
     'SELECT(answer_format,created_at,difficulty,ege_number,id,origin,slug,'
     'source,statement_md,status,tags,title,updated_at)'),
    ('is_registration_open()', 'anon',          'EXECUTE'),
    ('is_registration_open()', 'authenticated', 'EXECUTE'),
    ('is_admin()',                              'authenticated', 'EXECUTE'),
    ('is_task_visible(uuid)',                   'authenticated', 'EXECUTE'),
    ('is_article_visible(uuid)',                'authenticated', 'EXECUTE'),
    ('has_solved_task(uuid)',                   'authenticated', 'EXECUTE'),
    ('normalize_answer(text, text)',            'authenticated', 'EXECUTE'),
    ('submit_solution(uuid, text, text)',       'authenticated', 'EXECUTE'),
    ('set_solution_published(uuid, boolean)',   'authenticated', 'EXECUTE'),
    ('get_user_progress(uuid)',                 'authenticated', 'EXECUTE'),
    ('get_task_stats()',                        'authenticated', 'EXECUTE'),
    ('admin_get_task_answer(uuid)',             'authenticated', 'EXECUTE'),
    ('admin_reset_password(uuid, text)',        'authenticated', 'EXECUTE'),
    ('admin_set_role(uuid, text)',              'authenticated', 'EXECUTE'),
    ('admin_list_students(text, integer, integer)', 'authenticated', 'EXECUTE'),
    ('admin_student_overview(uuid)',            'authenticated', 'EXECUTE'),
    ('admin_task_attempts(uuid, uuid)',         'authenticated', 'EXECUTE'),
    ('admin_recent_submissions(uuid, smallint, uuid, boolean, '
     'timestamp with time zone, timestamp with time zone, integer, integer)',
                                                'authenticated', 'EXECUTE'),
    ('admin_check_slug_available(text)',        'authenticated', 'EXECUTE'),
    ('admin_upsert_task(jsonb)',                'authenticated', 'EXECUTE'),
    ('admin_upsert_article(jsonb)',             'authenticated', 'EXECUTE'),
    ('admin_verify_reference(text, text)',      'authenticated', 'EXECUTE'),
    ('admin_set_task_status(text, text)',       'authenticated', 'EXECUTE'),
    ('admin_delete_task(text)',                 'authenticated', 'EXECUTE'),
    ('admin_list_tasks(jsonb)',                 'authenticated', 'EXECUTE'),
    ('admin_get_task(text)',                    'authenticated', 'EXECUTE'),
    ('admin_set_task_answer(jsonb)',            'authenticated', 'EXECUTE');

  select string_agg(format('%s %s: %s', d.role, d.obj, d.privs), '; '
                    order by d.obj, d.role)
    into v_extra
    from (select * from privileges_actual
          except
          select * from privileges_expected) d;

  select string_agg(format('%s %s: %s', d.role, d.obj, d.privs), '; '
                    order by d.obj, d.role)
    into v_missing
    from (select * from privileges_expected
          except
          select * from privileges_actual) d;

  if v_extra is not null or v_missing is not null then
    raise exception 'ТЕСТ ПРОВАЛЕН (п): матрица прав разошлась. Сверх ожидаемого: %. Не хватает: %',
      coalesce(v_extra, 'ничего'), coalesce(v_missing, 'ничего');
  end if;
  raise notice 'OK: (п) права anon и authenticated на public совпадают с задуманными';
end
$$;

-- =============================================================================
-- (р) admin_set_task_answer: ответ, формат и эталон без остального
-- =============================================================================

-- Подготовка: черновик банка с вложением в Storage, картинкой и двумя темами
-- и опубликованная задача со сверенным эталоном.
do $$
declare
  v_task uuid;
begin
  -- Раздел делает несколько записей подряд, поэтому лимит частоты снимаем.
  update public.app_settings set value = '1000'::jsonb
   where key = 'content_writes_per_minute';

  insert into public.themes (code, title, section_code, section_title, level, sort_order)
  values ('9.8', 'Ещё одна тестовая тема', '9', 'Тестовый раздел', 'УУ', 2)
  on conflict (code) do nothing;

  insert into public.tasks (
    slug, ege_number, title, statement_md, difficulty, answer_format,
    status, origin, fipi_id, fipi_short_id, reference_solution,
    answer_explanation, reference_verified_at
  )
  values (
    'fipi-ans001', 17, 'Задание банка с вложением',
    'Условие задания банка: файл с числами лежит в архиве.', 2, 'string',
    'draft', 'fipi', 'ANS001TESTANS001TESTANS001TEST00', 'ANS001',
    'print(1)', 'Старый разбор', now()
  )
  returning id into v_task;

  insert into public.task_files (
    task_id, filename, storage_bucket, storage_path, size_bytes, kind, sort_order
  )
  values
    (v_task, 'ans001_1.zip', 'task-assets', 'files/ans001_1.zip', 1234, 'file', 0),
    (v_task, 'ans001_1.png', 'task-assets', 'images/ans001_1.png', 567, 'image', 1);

  insert into public.task_themes (task_id, theme_code, sort_order)
  values (v_task, '9.8', 0), (v_task, '9.9', 1);

  insert into public.tasks (
    slug, ege_number, title, statement_md, difficulty, answer_format,
    status, origin, reference_solution, reference_verified_at
  )
  values (
    'ans-published', 5, 'Опубликованная задача',
    'Условие опубликованной задачи достаточной длины.', 1, 'single',
    'published', 'human', 'print(5)', now()
  )
  returning id into v_task;

  insert into public.task_answers (task_id, answer) values (v_task, '5');
  insert into public.task_themes (task_id, theme_code) values (v_task, '9.9');

  raise notice 'OK: (р) сетап: черновик банка с вложениями и темами, опубликованная задача';
end
$$;

-- Ученику — [forbidden], анониму — permission denied.
do $$
declare
  v_alice uuid;
begin
  select id into v_alice from public.profiles where username = 'alice';
  perform tests.login(v_alice);
  begin
    perform public.admin_set_task_answer(jsonb_build_object(
      'slug', 'fipi-ans001', 'answer_format', 'single', 'answer', '1',
      'reference_solution', 'print(1)'));
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ученик задал ответ задаче';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    if sqlerrm not like '[forbidden]%' then
      raise exception 'ТЕСТ ПРОВАЛЕН (р): ученику отказано не тем кодом: %', sqlerrm;
    end if;
    raise notice 'OK: (р) admin_set_task_answer под учеником — [forbidden]';
  end;
  perform tests.logout();

  perform set_config('role', 'anon', false);
  begin
    perform public.admin_set_task_answer('{}'::jsonb);
    raise exception 'ТЕСТ ПРОВАЛЕН (р): аноним вызвал admin_set_task_answer';
  exception when insufficient_privilege then
    raise notice 'OK: (р) admin_set_task_answer под анонимом — permission denied';
  end;
  perform set_config('role', 'none', false);
end
$$;

-- Администратор задаёт ответ: меняются только ответ, формат, эталон, разбор
-- и отметка сверки. Снимок задачи до и после — от суперпользователя.
create temp table set_answer_before as
select (to_jsonb(t) - array['answer_format', 'reference_solution',
                            'answer_explanation', 'reference_verified_at',
                            'updated_at']) as task_row,
       (select jsonb_agg(jsonb_build_object(
                 'filename', f.filename, 'storage_bucket', f.storage_bucket,
                 'storage_path', f.storage_path, 'size_bytes', f.size_bytes,
                 'kind', f.kind, 'sort_order', f.sort_order)
               order by f.filename)
          from public.task_files f where f.task_id = t.id) as files,
       (select jsonb_agg(jsonb_build_object(
                 'theme_code', tt.theme_code, 'sort_order', tt.sort_order)
               order by tt.theme_code)
          from public.task_themes tt where tt.task_id = t.id) as themes
  from public.tasks t
 where t.slug = 'fipi-ans001';

do $$
declare
  v_admin uuid;
  v_res   jsonb;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  v_res := public.admin_set_task_answer(jsonb_build_object(
    'slug',               'fipi-ans001',
    'answer_format',      'multi',
    'answer',             '10 20 30 40',
    'reference_solution', 'print(10, 20, 30, 40)',
    'answer_explanation', 'Новый разбор'
  ));
  if v_res is distinct from jsonb_build_object(
       'slug', 'fipi-ans001', 'status', 'draft', 'answer_format', 'multi') then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): неожиданный ответ функции: %', v_res;
  end if;

  perform tests.logout();
  raise notice 'OK: (р) admin_set_task_answer вернул slug, статус и формат';
end
$$;

do $$
declare
  v_task  public.tasks;
  v_ans   text;
  v_cnt   bigint;
  v_files jsonb;
  v_thems jsonb;
begin
  select * into v_task from public.tasks where slug = 'fipi-ans001';
  select answer into v_ans from public.task_answers where task_id = v_task.id;

  if v_ans is distinct from '10 20 30 40' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ответ не записан';
  end if;
  if v_task.answer_format <> 'multi'
     or v_task.reference_solution <> 'print(10, 20, 30, 40)'
     or v_task.answer_explanation <> 'Новый разбор' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): формат, эталон или разбор не записаны';
  end if;
  if v_task.reference_verified_at is not null then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): отметка сверки эталона не сброшена';
  end if;
  if v_task.status <> 'draft' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): черновик сменил статус на %', v_task.status;
  end if;
  raise notice 'OK: (р) ответ, формат, эталон и разбор записаны, сверка сброшена, черновик — draft';

  select count(*) into v_cnt
    from public.tasks t, set_answer_before b
   where t.slug = 'fipi-ans001'
     and (to_jsonb(t) - array['answer_format', 'reference_solution',
                              'answer_explanation', 'reference_verified_at',
                              'updated_at']) = b.task_row;
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): изменились поля задачи помимо ответа';
  end if;
  raise notice 'OK: (р) условие, номер, статус и прочие поля задачи не изменились';

  select jsonb_agg(jsonb_build_object(
           'filename', f.filename, 'storage_bucket', f.storage_bucket,
           'storage_path', f.storage_path, 'size_bytes', f.size_bytes,
           'kind', f.kind, 'sort_order', f.sort_order)
         order by f.filename)
    into v_files
    from public.task_files f where f.task_id = v_task.id;
  if v_files is distinct from (select files from set_answer_before)
     or jsonb_array_length(v_files) <> 2 then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): файлы задачи изменились: %', v_files;
  end if;
  raise notice 'OK: (р) файлы задачи те же: число, имена, адреса в Storage';

  select jsonb_agg(jsonb_build_object(
           'theme_code', tt.theme_code, 'sort_order', tt.sort_order)
         order by tt.theme_code)
    into v_thems
    from public.task_themes tt where tt.task_id = v_task.id;
  if v_thems is distinct from (select themes from set_answer_before)
     or jsonb_array_length(v_thems) <> 2 then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): темы задачи изменились: %', v_thems;
  end if;
  raise notice 'OK: (р) темы задачи те же';

  select count(*) into v_cnt
    from public.audit_log
   where action = 'set_answer' and entity_slug = 'fipi-ans001';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): записей set_answer в журнале: %', v_cnt;
  end if;
  raise notice 'OK: (р) вызов записан в audit_log как set_answer';
end
$$;

drop table set_answer_before;

-- Без ключа answer_explanation разбор не меняется; опубликованная задача
-- уходит в review.
do $$
declare
  v_admin uuid;
  v_res   jsonb;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  perform public.admin_set_task_answer(jsonb_build_object(
    'slug', 'fipi-ans001', 'answer_format', 'multi', 'answer', '10 20 30 40',
    'reference_solution', 'print(10, 20, 30, 40)'));

  v_res := public.admin_set_task_answer(jsonb_build_object(
    'slug', 'ans-published', 'answer_format', 'single', 'answer', '6',
    'reference_solution', 'print(6)'));
  if v_res ->> 'status' is distinct from 'review' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): функция вернула статус % вместо review', v_res ->> 'status';
  end if;

  perform tests.logout();

  if (select answer_explanation from public.tasks where slug = 'fipi-ans001')
     is distinct from 'Новый разбор' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): разбор стёрт вызовом без answer_explanation';
  end if;
  raise notice 'OK: (р) без ключа answer_explanation разбор не меняется';

  if (select status from public.tasks where slug = 'ans-published') <> 'review' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): опубликованная задача не ушла в review';
  end if;
  if (select reference_verified_at from public.tasks where slug = 'ans-published')
     is not null then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): у опубликованной задачи не сброшена сверка';
  end if;
  raise notice 'OK: (р) опубликованная задача после смены ответа — review';
end
$$;

-- Ошибки: каждая со своим кодом, ничего не записывается.
do $$
declare
  v_admin uuid;
  v_base  jsonb;
  v_case  record;
begin
  select id into v_admin from public.profiles where username = 'boss';
  perform tests.login(v_admin);

  v_base := jsonb_build_object(
    'slug',               'fipi-ans001',
    'answer_format',      'single',
    'answer',             '77',
    'reference_solution', 'print(77)'
  );

  for v_case in
    select * from (values
      ('bad_payload',                '[]'::jsonb,                                    'payload не объект'),
      ('bad_payload',                'null'::jsonb,                                  'payload — JSON null'),
      ('not_found',                  v_base || '{"slug": "no-such-task"}',           'нет такой задачи'),
      ('not_found',                  v_base - 'slug',                                'нет slug'),
      ('bad_answer_format',          v_base || '{"answer_format": "table"}',         'формат вне списка'),
      ('bad_answer_format',          v_base - 'answer_format',                       'нет формата'),
      ('bad_answer',                 v_base || '{"answer": "   "}',                  'пустой ответ'),
      ('bad_answer',                 v_base - 'answer',                              'нет ответа'),
      ('bad_answer',                 v_base || '{"answer_format": "string", "answer": "a\nb"}', 'строка с переводом строки'),
      ('bad_answer',                 v_base || '{"answer": "сорок два"}',            'не число для single'),
      ('bad_answer',                 v_base || '{"answer_format": "pair", "answer": "1"}', 'одно число для pair'),
      ('missing_reference_solution', v_base || '{"reference_solution": "  "}',       'пустой эталон'),
      ('missing_reference_solution', v_base - 'reference_solution',                  'нет эталона')
    ) as c(code, payload, what)
  loop
    begin
      perform public.admin_set_task_answer(v_case.payload);
      raise exception 'ТЕСТ ПРОВАЛЕН (р): принят вызов «%»', v_case.what;
    exception when others then
      if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
      if sqlerrm not like '[' || v_case.code || ']%' then
        raise exception 'ТЕСТ ПРОВАЛЕН (р): «%» — ожидался [%], получено: %',
          v_case.what, v_case.code, sqlerrm;
      end if;
      raise notice 'OK: (р) % — [%]', v_case.what, v_case.code;
    end;
  end loop;

  perform tests.logout();

  -- Неудачные вызовы ничего не изменили.
  if (select answer from public.task_answers ta
        join public.tasks t on t.id = ta.task_id
       where t.slug = 'fipi-ans001') is distinct from '10 20 30 40'
     or (select answer_format from public.tasks where slug = 'fipi-ans001') <> 'multi' then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): отклонённый вызов изменил задачу';
  end if;
  raise notice 'OK: (р) отклонённые вызовы задачу не меняют';
end
$$;

-- Ученик по-прежнему не видит ни ответа, ни эталона. Задачу публикуем
-- штатно: сверка эталона и смена статуса.
do $$
declare
  v_admin uuid;
  v_alice uuid;
  v_cnt   bigint;
begin
  select id into v_admin from public.profiles where username = 'boss';
  select id into v_alice from public.profiles where username = 'alice';

  perform tests.login(v_admin);
  if (public.admin_verify_reference('fipi-ans001', E'10 20\n30 40') ->> 'matches')::boolean
     is not true then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): вывод эталона не сверился с новым ответом';
  end if;
  perform public.admin_set_task_status('fipi-ans001', 'published');
  perform tests.logout();

  perform tests.login(v_alice);

  select count(*) into v_cnt from public.tasks_public where slug = 'fipi-ans001';
  if v_cnt <> 1 then
    raise exception 'ТЕСТ ПРОВАЛЕН (р): опубликованная задача не видна ученику';
  end if;

  begin
    perform 1 from public.task_answers;
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ученик прочитал task_answers';
  exception when insufficient_privilege then
    raise notice 'OK: (р) task_answers под учеником — permission denied';
  end;

  begin
    perform reference_solution from public.tasks where slug = 'fipi-ans001';
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ученик прочитал reference_solution';
  exception when insufficient_privilege then
    raise notice 'OK: (р) reference_solution под учеником — permission denied';
  end;

  begin
    perform answer_explanation from public.tasks where slug = 'fipi-ans001';
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ученик прочитал answer_explanation';
  exception when insufficient_privilege then
    raise notice 'OK: (р) answer_explanation под учеником — permission denied';
  end;

  begin
    perform public.admin_get_task('fipi-ans001');
    raise exception 'ТЕСТ ПРОВАЛЕН (р): ученик получил задачу через admin_get_task';
  exception when others then
    if sqlerrm like 'ТЕСТ ПРОВАЛЕН%' then raise; end if;
    raise notice 'OK: (р) admin_get_task под учеником — отказ (%)', sqlerrm;
  end;

  perform tests.logout();

  update public.app_settings set value = '60'::jsonb
   where key = 'content_writes_per_minute';
end
$$;

-- =============================================================================
-- Итог
-- =============================================================================
do $$
begin
  raise notice 'RLS TESTS PASSED';
end
$$;
