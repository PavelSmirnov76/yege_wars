# Отчёт: порядок сортировки в запросах клиента

Задание — [PROMPT_SORT_ORDER.md](PROMPT_SORT_ORDER.md).

## 1. Состояние

2026-10-07: пункты 1–4 задания сделаны, полный набор проверок зелёный,
каталог проверен на боевой (только чтение). Схема БД, миграции и боевая
база не менялись. Закоммичено по подтверждению пользователя.

- **Явный порядок**: у каждого `order()` в `lib/` задан `ascending`.
  По возрастанию идут каталог (`ege_number`, затем `title`), файлы задачи
  (`sort_order`), номера для фильтра (`ege_number`) и статьи справочника
  (`level`, затем `title`). Попытки, решения, ручные связи и статьи по
  темам не трогались — там порядок уже был задан явно.
- **Тесты на адрес запроса**: настоящий `SupabaseClient` поверх
  `MockClient` (`RecordingSupabaseClient`), по тесту на каждый из
  четырёх запросов. Без правки в `lib/` все четыре падают
  (`…desc.nullslast` вместо `…asc.nullslast`).
- **На боевой** каталог начинается с номера 2: опубликованных задач
  номера 1 нет (см. раздел 5). Номера не убывают, названия внутри номера
  идут в порядке правила сортировки базы.
- `docs/STATE.md` — раздел «Порядок сортировки в запросах клиента»,
  пункт из «Чего ещё нет» убран.

## 2. Журнал решений

| Дата | Вопрос | Варианты | Ответ пользователя |
|---|---|---|---|
| 2026-10-07 | Коммитить ли работу (на СТОПе) | да, коммит / нет, пока не коммитить | Да, коммит |

Других вопросов пользователю по ходу работы не было.

## 3. Изменённые файлы

Новые:

- `test/helpers/recording_supabase_client.dart` — `RecordingSupabaseClient`:
  настоящий `SupabaseClient`, запросы запоминаются, ответ — `[]`.
- `test/features/tasks/data/supabase_tasks_remote_data_source_test.dart` —
  каталог, файлы задачи, номера для фильтра (3 теста).
- `test/features/reference/data/supabase_reference_remote_data_source_test.dart`
  — список статей (1 тест).
- `docs/SORT_ORDER_REPORT.md` (этот файл).

Изменённые:

- `lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart`
  — `fetchTasks`, `fetchFiles`, `fetchEgeNumbers`: `ascending: true`.
- `lib/features/reference/data/datasources/supabase_reference_remote_data_source.dart`
  — `fetchArticles`: `ascending: true`.
- `docs/STATE.md`.

## 4. Проверки

Полный набор из задания, 2026-10-07, выводы дословно:

```text
$ flutter gen-l10n
Because l10n.yaml exists, the options defined there will be used instead.
To use the command line arguments, delete the l10n.yaml file in the Flutter project.

$ dart run build_runner build --delete-conflicting-outputs
  Built with build_runner/aot in 4s; wrote 12 outputs.

$ flutter analyze --fatal-infos --fatal-warnings
Analyzing yege_wars...
No issues found! (ran in 2.7s)

$ dart run custom_lint
Analyzing...

No issues found!

$ flutter test
00:09 +271: All tests passed!

$ find lib test ... | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 189 files (0 changed) in 0.18 seconds.
exit=0

$ grep -rn -A2 '\.order(' lib --include='*.dart' | grep -v '\.g\.dart'
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:62:        .order(TaskColumns.egeNumber, ascending: true)
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:63:        .order(TaskColumns.title, ascending: true);
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-64-  }
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-65-
--
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:81:      .order(TaskFileColumns.sortOrder, ascending: true);
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-82-
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-83-  @override
--
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:89:      .order(TaskReferenceColumns.sortOrder, ascending: true);
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-90-
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-91-  // Встроить reference_articles в выборку из представления нельзя: у
--
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:102:          .order(TaskArticleColumns.sortOrder, ascending: true);
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-103-
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-104-  @override
--
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart:129:      .order(TaskColumns.egeNumber, ascending: true);
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-130-
lib/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart-131-  @override
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart:51:        .order(SubmissionColumns.createdAt, ascending: false);
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart-52-  }
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart-53-
--
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart:69:    return query.order(SubmissionColumns.createdAt, ascending: false);
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart-70-  }
lib/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart-71-
lib/features/reference/data/datasources/supabase_reference_remote_data_source.dart:65:        .order(ArticleColumns.level, ascending: true)
lib/features/reference/data/datasources/supabase_reference_remote_data_source.dart:66:        .order(ArticleColumns.title, ascending: true);
lib/features/reference/data/datasources/supabase_reference_remote_data_source.dart-67-  }
lib/features/reference/data/datasources/supabase_reference_remote_data_source.dart-68-
```

Тестов 271 (было 267): +4 теста на адрес запроса. Старые не менялись.

Новые тесты на коде до правки (правка `lib/` временно убрана через
`git stash`, затем возвращена) — все четыре падают:

```text
  Expected: 'ege_number.asc.nullslast,title.asc.nullslast'
    Actual: 'ege_number.desc.nullslast,title.desc.nullslast'
  Expected: 'sort_order.asc.nullslast'
    Actual: 'sort_order.desc.nullslast'
  Expected: 'ege_number.asc.nullslast'
    Actual: 'ege_number.desc.nullslast'
  Expected: 'level.asc.nullslast,title.asc.nullslast'
    Actual: 'level.desc.nullslast,title.desc.nullslast'
00:00 +0 -4: Some tests failed.
```

### Каталог на боевой (только чтение)

Как проверялось: временный тест `test/zz_prod_probe_test.dart` (удалён
после прогона, в коммит не идёт) собирает `SupabaseClient` с токеном
сервисного аккаунта из `tools/content_client.py` (`ContentClient().token`)
и HTTP-клиентом, который пропускает только GET и печатает путь и запрос
без хоста и заголовков. Через него вызываются настоящие
`SupabaseTasksRemoteDataSource.fetchTasks(const TaskFilter())`,
`fetchEgeNumbers()` и `SupabaseReferenceRemoteDataSource.fetchArticles`.
Печатаются номера и первые буквы названий. Значения переменных окружения
не выводились.

Строки «номер N: позиция …» — пары соседних названий, которые Dart
по кодам символов (`String.compareTo`) считает обратным порядком:
сколько символов у названий общих и какие символы идут дальше. Вторая
сверка — по модели правила сортировки базы: знаки раньше цифр, цифры
раньше букв, латиница раньше кириллицы, `ё` сразу после `е`, регистр не
учитывается.

```text
GET /rest/v1/tasks_public?select=id%2Cslug%2Cege_number%2Ctitle%2Cdifficulty%2Ctags&order=ege_number.asc.nullslast%2Ctitle.asc.nullslast -> 200
задач: 140, первая — номер 2, последняя — номер 26
номера не убывают: true
номер 2: позиция 2, Л > Л, общий префикс 41 симв., дальше U+00ac против U+0078
номер 2: позиция 5, М > М, общий префикс 42 симв., дальше U+00ac против U+0078
2: Л Л Л М М М М М М С
3: Н Н
4: Д Д Д Д П П
5: Н Н
6: И И
7: А А А В В В В В Г Д Д Д Д И К К Л М М М М О О О О О П П С С С С С С С С С У Ц
8: В В В В В В В В В В В
9: В В Д Д Д Д Д П
10: В В
11: Н П
12: И И
13: В
номер 14: позиция 3, З > З, общий префикс 36 симв., дальше U+005e против U+0034
номер 14: позиция 14, О > О, общий префикс 30 симв., дальше U+0451 против U+0438
14: В З З З З З З З З З З З О О О О С У
15: Д Д О О
16: А А А Н Н Н
19: Д
22: В В П
23: И И И
24: З О Ц
25: В З И Н Н О П П П П П Р У У
26: Т
названия внутри номера по алфавиту (сравнение по кодам): false
названия внутри номера по алфавиту (знаки < цифры < буквы, ё после е): true
GET /rest/v1/tasks_public?select=ege_number&order=ege_number.asc.nullslast -> 200
номера для фильтра: 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 19 22 23 24 25 26
GET /rest/v1/reference_articles?select=slug%2Ctitle%2Csummary%2Clevel%2Creading_minutes%2Cege_numbers%2Ctags&order=level.asc.nullslast%2Ctitle.asc.nullslast -> 200
статей: 45
уровни: 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3
первые буквы: 1 4 4 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 4 4 1 1 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3 3 4 4
00:00 +1: All tests passed!
```

Итог: каталог по возрастанию номеров, внутри номера — по алфавиту
в смысле правила сортировки базы. Четыре пары, которые Dart по кодам
считает обратным порядком, расходятся на символах `¬` (U+00AC) против
`x`, `^` (U+005E) против `4` и `ё` (U+0451) против `и`. База ставит знаки
раньше цифр и букв, а `ё` — сразу после `е`, то есть раньше `и`.
Статьи справочника идут по уровню 1 → 3, внутри уровня — по названию
(названия статей начинаются с номера раздела кодификатора).

## 5. Отступления от задания и найдено вне задания

### Отступления

- **Каталог на боевой начинается с номера 2, а не 1.** Опубликованных
  задач номера 1 нет: список номеров для фильтра на боевой —
  `2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 19 22 23 24 25 26`. Ожидание
  задания («первая задача — номера 1») на текущих данных не выполнимо.
  В коде это не исправляется: каталог начинается с наименьшего
  опубликованного номера.
- **Проверка на боевой шире заданной**: кроме каталога прочитаны список
  номеров для фильтра (подтверждает, что номера 1 нет) и список статей
  справочника. Всё — GET через тот же временный тест.
- **Во временном тесте снята подмена `HttpClient`**
  (`HttpOverrides.global = null`): тестовый биндинг Flutter отвечает на
  любой настоящий HTTP-запрос кодом 400, без этого запросы на боевую не
  уходили. Это касалось только удалённого временного теста.
- **Комментарий в коде**: в `fetchTasks` и в `fetchArticles` справочника
  одна строка о том, что `order()` в `postgrest` по умолчанию сортирует
  по убыванию, — чтобы явный `ascending: true` не убрали как лишний.
- **`STATE.md`**: кроме нового раздела и удалённого пункта в «Чего ещё
  нет» исправлена фраза в разделе «Ответ по формату и справка по темам»
  («Остальные запросы клиента этого не учитывают») — она стала неверной.

### Найдено вне задания

- **Порядок названий — правило сортировки базы, а не кодов символов.**
  Сервер сортирует `title` правилом сортировки (collation) базы: знаки
  раньше цифр и букв, `ё` рядом с `е`. Сравнение строк в Dart идёт по
  кодам символов, поэтому сортировка на клиенте дала бы другой порядок
  в номерах 2 и 14. Сейчас клиент не пересортировывает — расхождения нет.
  Какое именно правило стоит в базе, не запрашивалось (вывод — по
  результату сверки выше).
- **`MockClient` и `postgrest`**: `postgrest` читает метод из
  `response.request` и падает на `null`, а `MockClient` берёт `request`
  из возвращённого `Response`. В `RecordingSupabaseClient` запрос
  передаётся в ответ явно (с комментарием).

## 6. Коммит

Хэш `60b6db3630764955c37791b225d8fdd154125863`, заголовок «Явный порядок сортировки в запросах клиента».

```text
60b6db3630764955c37791b225d8fdd154125863
Явный порядок сортировки в запросах клиента

 CLAUDE.md                                          |   4 +-
 docs/PROMPT_SORT_ORDER.md                          | 148 +++++++++++++
 docs/SORT_ORDER_REPORT.md                          | 238 +++++++++++++++++++++
 docs/STATE.md                                      |  32 ++-
 .../supabase_reference_remote_data_source.dart     |   5 +-
 .../supabase_tasks_remote_data_source.dart         |   9 +-
 ...supabase_reference_remote_data_source_test.dart |  29 +++
 .../supabase_tasks_remote_data_source_test.dart    |  49 +++++
 test/helpers/recording_supabase_client.dart        |  40 ++++
 9 files changed, 543 insertions(+), 11 deletions(-)
```

## 7. Приёмка

Постановщик, 2026-10-07. Всё проверено самостоятельно, на боевой — только чтением.

| № | Пункт | Как проверено | Итог |
|---|---|---|---|
| 1 | Полный набор проверок | Перезапущен: `analyze` и `custom_lint` — 0 замечаний, `flutter test` — 271 (было 267), все проходят, `dart format` — 0 изменений | OK |
| 2 | Явный `ascending`, тесты на адрес | У всех 9 вызовов `order()` в `lib/` есть явный `ascending`, «новые первыми» у попыток и решений не тронуто. Четыре теста сверяют параметр `order` в адресе, который собирает настоящий `SupabaseClient`, со строкой `…asc.nullslast`. По умолчанию `postgrest` даёт `desc`, поэтому без правки тесты падают. Исполнитель это показал, по коду тестов это следует однозначно | OK |
| 3 | Каталог на боевой | Номера не убывают, названия внутри номера идут по правилу сортировки базы (вывод исполнителя). Начинается каталог с номера 2, а не с 1, как ждал промт. Своим запросом: у опубликованных задач минимальный номер — 2. У всех 13 задач номера 1 с ответом статус `draft`: у каждой картинка с графом, и правило публикации 139 задач их не взяло. Ожидание в промте было неверным, код тут ни при чём | OK |
| 4 | Отчёт, коммит, `STATE.md` | Раздел «Коммит» есть, хэш `60b6db3` совпадает с `git log`. Второй коммит `8219f3b` содержит только отчёт. Журнал решений сверен с транскриптом: был один вопрос, про коммит, задан с вариантами. Промт и `CLAUDE.md` исполнитель не правил, временный тест удалён, в коммиты он не попал | OK |

Ещё проверено: правило сортировки базы — ICU `en-US` (`datlocprovider = i`).
Это подтверждает вывод исполнителя, что `ё` идёт рядом с `е`, а знаки —
раньше цифр и букв.

### Ошибка постановщика

В пункте приёмки 3 и в п. 3 задания я написал: «первая задача — номера 1».
На текущих данных это не проверял. Опубликованных задач номера 1 нет:
все они с картинками и в публикацию не попали. Исполнитель это заметил и
записал, а не стал подгонять. Вывод для постановщика: ожидаемые значения
в «Приёмке» проверять на текущих данных так же, как факты исходного
состояния. Правило добавлено в скил `task-prompt`.
