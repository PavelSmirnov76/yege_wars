-- =============================================================================
-- Проверки импорта банка ФИПИ. Запускается из supabase/tests/run_import_check.sh
-- на временной базе, куда уже применены миграции и залита выгрузка.
--
-- Ожидаемые значения взяты из задания на импорт (раздел «Приёмка») и не
-- подгоняются под факт. Два числа приходят из выгрузки параметрами psql:
--   :files_on_disk — сколько вложений из tasks.json лежит в каталоге выгрузки;
--   :kim24         — сколько заданий выгрузка относит к номеру 24.
-- =============================================================================

\set ON_ERROR_STOP on

create temp table import_checks (
  ord      int  primary key,
  label    text not null,
  expected text not null,
  actual   text not null
);

insert into import_checks (ord, label, expected, actual) values
  (1, 'Заданий с origin = fipi', '2475',
      (select count(*)::text from public.tasks where origin = 'fipi')),

  (2, 'Тем в кодификаторе (45 ФИПИ + none)', '46',
      (select count(*)::text from public.themes)),

  -- В задании ожидается 7056 — столько связей в выгрузке. Плюс к ним
  -- 15 служебных: правило «у задания всегда есть тема» требует поставить
  -- none заданиям, которым ФИПИ не проставил КЭС.
  (3, 'Связей задание-тема всего (7056 из выгрузки + 15 служебных)', '7071',
      (select count(*)::text from public.task_themes)),

  (4, 'Связей задание-тема из выгрузки (тема не none)', '7056',
      (select count(*)::text from public.task_themes
        where theme_code <> 'none')),

  (5, 'Заданий без единой темы', '0',
      (select count(*)::text from public.tasks t
        where not exists (select 1 from public.task_themes tt
                           where tt.task_id = t.id))),

  (6, 'Тем ФИПИ без статьи справочника', '0',
      (select count(*)::text from public.themes th
        where th.code <> 'none'
          and not exists (select 1 from public.reference_articles a
                           where a.theme_code = th.code))),

  (7, 'Статей справочника с темой', '45',
      (select count(*)::text from public.reference_articles
        where theme_code is not null)),

  (8, 'От темы к заданиям: тема 3.13', '178',
      (select count(*)::text from public.task_themes
        where theme_code = '3.13')),

  (9, 'Заданий с темой, но без справки в task_articles', '0',
      (select count(*)::text from public.tasks t
        where exists (select 1 from public.task_themes tt
                       where tt.task_id = t.id and tt.theme_code <> 'none')
          and not exists (select 1 from public.task_articles ta
                           where ta.task_id = t.id))),

  (10, 'Заданий с номером КИМ', '2018',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number is not null)),

  (11, 'Заданий без номера КИМ', '457',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number is null)),

  (12, 'Номеров вне диапазона 1-27', '0',
       (select count(*)::text from public.tasks
         where ege_number is not null and ege_number not between 1 and 27)),

  (13, 'Заданий с источником номера fipi-spec-2026', '2018',
       (select count(*)::text from public.tasks
         where ege_number_source = 'fipi-spec-2026')),

  (14, 'Фильтр по номеру: заданий с номером 24', :'kim24',
       (select count(*)::text from public.tasks where ege_number = 24)),

  (15, 'Заданий с parent_task_id', '85',
       (select count(*)::text from public.tasks
         where parent_task_id is not null)),

  (16, 'Битых ссылок parent_task_id', '0',
       (select count(*)::text from public.tasks t
         where t.parent_task_id is not null
           and not exists (select 1 from public.tasks p
                            where p.id = t.parent_task_id))),

  (17, 'Заданий, помеченных дублем', '2',
       (select count(*)::text from public.tasks
         where duplicate_of is not null)),

  (18, 'Заданий с неполным условием', '3',
       (select count(*)::text from public.tasks
         where condition_incomplete)),

  (19, 'Вложений в task_files', '1571',
       (select count(*)::text from public.task_files)),

  (20, 'Заданий с вложениями', '668',
       (select count(distinct task_id)::text from public.task_files)),

  (21, 'Вложений без адреса в Storage', '0',
       (select count(*)::text from public.task_files
         where storage_path is null or storage_bucket is null)),

  (22, 'Вложений из выгрузки, лежащих на диске', '1571', :'files_on_disk'),

  (23, 'Опубликованных задач', '0',
       (select count(*)::text from public.tasks where status = 'published')),

  (24, 'Импортированных задач с ответом', '0',
       (select count(*)::text from public.task_answers ta
         join public.tasks t on t.id = ta.task_id
        where t.origin = 'fipi')),

  (25, 'Задач вне статуса draft среди импортированных', '0',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and status <> 'draft')),

  (26, 'Опубликованных статей справочника', '45',
       (select count(*)::text from public.reference_articles
         where is_published));

\pset format aligned
\pset border 2
\pset null ''

select ord            as "№",
       label          as "Пункт",
       expected       as "Ожидалось",
       actual         as "Получилось",
       case when expected = actual then 'OK' else 'РАСХОЖДЕНИЕ' end as "Итог"
  from import_checks
 order by ord;

do $$
declare
  v_bad int;
  v_row record;
begin
  select count(*) into v_bad from import_checks where expected <> actual;
  if v_bad = 0 then
    return;
  end if;
  for v_row in select * from import_checks where expected <> actual order by ord
  loop
    raise warning 'РАСХОЖДЕНИЕ п.%: % — ожидалось %, получилось %',
      v_row.ord, v_row.label, v_row.expected, v_row.actual;
  end loop;
  raise exception 'Расхождений: %', v_bad;
end;
$$;
