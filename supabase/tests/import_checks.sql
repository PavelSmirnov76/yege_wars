-- =============================================================================
-- Проверки импорта банка ФИПИ. Запускается из supabase/tests/run_import_check.sh
-- на временной базе, куда уже применены миграции и залита выгрузка, и так же
-- на боевой базе после заливки.
--
-- Проверка верна на любой базе, а не только на пустой. Пункты, которые
-- сверяют число с выгрузкой, считают только банк: задания с origin = 'fipi'
-- и их связи, статьи справочника с темой (их же удаляет и заново заливает
-- импорт). Инварианты («нарушений 0») считают всю базу там, где правило
-- действует для любой задачи. Что считает пункт — в колонке «Охват».
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
  scope    text not null,
  expected text not null,
  actual   text not null
);

insert into import_checks (ord, label, scope, expected, actual) values
  (1, 'Заданий с origin = fipi', 'банк', '2475',
      (select count(*)::text from public.tasks where origin = 'fipi')),

  (2, 'Тем в кодификаторе (45 ФИПИ + none)', 'вся база', '46',
      (select count(*)::text from public.themes)),

  -- В задании ожидается 7056 — столько связей в выгрузке. Плюс к ним
  -- 15 служебных: правило «у задания всегда есть тема» требует поставить
  -- none заданиям, которым ФИПИ не проставил КЭС.
  (3, 'Связей задание-тема всего (7056 из выгрузки + 15 служебных)', 'банк', '7071',
      (select count(*)::text from public.task_themes tt
         join public.tasks t on t.id = tt.task_id
        where t.origin = 'fipi')),

  (4, 'Связей задание-тема из выгрузки (тема не none)', 'банк', '7056',
      (select count(*)::text from public.task_themes tt
         join public.tasks t on t.id = tt.task_id
        where t.origin = 'fipi' and tt.theme_code <> 'none')),

  (5, 'Заданий без единой темы', 'вся база', '0',
      (select count(*)::text from public.tasks t
        where not exists (select 1 from public.task_themes tt
                           where tt.task_id = t.id))),

  (6, 'Тем ФИПИ без статьи справочника', 'вся база', '0',
      (select count(*)::text from public.themes th
        where th.code <> 'none'
          and not exists (select 1 from public.reference_articles a
                           where a.theme_code = th.code))),

  (7, 'Статей справочника с темой', 'банк', '45',
      (select count(*)::text from public.reference_articles
        where theme_code is not null)),

  (8, 'От темы к заданиям: тема 3.13', 'банк', '178',
      (select count(*)::text from public.task_themes tt
         join public.tasks t on t.id = tt.task_id
        where t.origin = 'fipi' and tt.theme_code = '3.13')),

  (9, 'Заданий с темой, но без справки в task_articles', 'вся база', '0',
      (select count(*)::text from public.tasks t
        where exists (select 1 from public.task_themes tt
                       where tt.task_id = t.id and tt.theme_code <> 'none')
          and not exists (select 1 from public.task_articles ta
                           where ta.task_id = t.id))),

  (10, 'Заданий с номером КИМ', 'банк', '2018',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number is not null)),

  (11, 'Заданий без номера КИМ', 'банк', '457',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number is null)),

  (12, 'Номеров вне диапазона 1-27', 'вся база', '0',
       (select count(*)::text from public.tasks
         where ege_number is not null and ege_number not between 1 and 27)),

  (13, 'Заданий с источником номера fipi-spec-2026', 'банк', '2018',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number_source = 'fipi-spec-2026')),

  (14, 'Фильтр по номеру: заданий с номером 24', 'банк', :'kim24',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and ege_number = 24)),

  (15, 'Заданий с parent_task_id', 'банк', '85',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and parent_task_id is not null)),

  (16, 'Битых ссылок parent_task_id', 'вся база', '0',
       (select count(*)::text from public.tasks t
         where t.parent_task_id is not null
           and not exists (select 1 from public.tasks p
                            where p.id = t.parent_task_id))),

  (17, 'Заданий, помеченных дублем', 'банк', '2',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and duplicate_of is not null)),

  (18, 'Заданий с неполным условием', 'банк', '3',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and condition_incomplete)),

  (19, 'Вложений в task_files', 'банк', '1571',
       (select count(*)::text from public.task_files f
         join public.tasks t on t.id = f.task_id
        where t.origin = 'fipi')),

  (20, 'Заданий с вложениями', 'банк', '668',
       (select count(distinct f.task_id)::text from public.task_files f
         join public.tasks t on t.id = f.task_id
        where t.origin = 'fipi')),

  -- Не инвариант: файлы задач проекта лежат в task_files.content,
  -- без адреса в Storage.
  (21, 'Вложений без адреса в Storage', 'банк', '0',
       (select count(*)::text from public.task_files f
         join public.tasks t on t.id = f.task_id
        where t.origin = 'fipi'
          and (f.storage_path is null or f.storage_bucket is null))),

  (22, 'Вложений из выгрузки, лежащих на диске', 'банк', '1571', :'files_on_disk'),

  (23, 'Опубликованных задач', 'банк', '0',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and status = 'published')),

  (24, 'Импортированных задач с ответом', 'банк', '0',
       (select count(*)::text from public.task_answers ta
         join public.tasks t on t.id = ta.task_id
        where t.origin = 'fipi')),

  (25, 'Задач вне статуса draft среди импортированных', 'банк', '0',
       (select count(*)::text from public.tasks
         where origin = 'fipi' and status <> 'draft')),

  -- Статьи банка — те, что с темой: именно их импорт удаляет и заливает
  -- заново (tools/import_fipi_bank.py).
  (26, 'Опубликованных статей справочника', 'банк', '45',
       (select count(*)::text from public.reference_articles
         where theme_code is not null and is_published));

\pset format aligned
\pset border 2
\pset null ''

select ord            as "№",
       label          as "Пункт",
       scope          as "Охват",
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
