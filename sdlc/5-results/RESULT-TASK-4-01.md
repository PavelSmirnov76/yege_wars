# RESULT-TASK-4-01: Метки среза «задачи и решение» и недостающие тесты

## Задание

[TASK-4](../4-tasks/TASK-4-LABELS-PROBLEMS.md).

## Коммит работы

`3798858` — «TASK-4: метки среза «задачи и решение» и недостающие тесты»,
ветка `task/TASK-4`, после «да» владельца на СТОПе 1 (Обсуждение, п. 2).
Индексы в этом коммите собраны без сдачи; сдача и индексы с ней — отдельным
коммитом.

```
379885869d87dc4d47b28eb80da62972f02ef628
TASK-4: метки среза «задачи и решение» и недостающие тесты

 lib/core/download/web_file_download.dart           |   2 +
 lib/core/markdown/code_block.dart                  |   2 +
 lib/core/python_runtime/pyodide_runtime.dart       |   2 +
 lib/core/python_runtime/python_runtime.dart        |   2 +
 .../editor/data/preferences_draft_storage.dart     |   2 +
 lib/features/editor/domain/draft_storage.dart      |   2 +
 lib/features/editor/editor_providers.dart          |   2 +
 .../presentation/controllers/run_controller.dart   |   2 +
 .../editor/presentation/widgets/code_editor.dart   |   2 +
 .../editor/presentation/widgets/console_view.dart  |   2 +
 .../editor/presentation/widgets/editor_panel.dart  |   4 +-
 .../widgets/python_editing_controller.dart         |   2 +
 .../presentation/widgets/reference_error_view.dart |   2 +
 .../supabase_submissions_remote_data_source.dart   |   2 +
 .../repositories/submissions_repository_impl.dart  |   2 +
 lib/features/submissions/domain/answer_rules.dart  |   2 +
 .../domain/use_cases/submit_answer_use_case.dart   |   2 +
 .../controllers/submissions_controllers.dart       |   8 ++
 .../presentation/widgets/attempts_list.dart        |   2 +
 .../presentation/widgets/solutions_list.dart       |   2 +
 .../presentation/widgets/submit_panel.dart         |   2 +
 .../presentation/widgets/verdict_banner.dart       |   2 +
 .../supabase_tasks_remote_data_source.dart         |   2 +
 .../data/repositories/tasks_repository_impl.dart   |   2 +
 .../domain/use_cases/get_ege_numbers_use_case.dart |   2 +
 .../tasks/domain/use_cases/get_task_use_case.dart  |   2 +
 .../domain/use_cases/list_catalog_use_case.dart    |   2 +
 .../controllers/catalog_controllers.dart           |   4 +
 .../tasks/presentation/screens/catalog_screen.dart |   2 +
 .../tasks/presentation/screens/task_screen.dart    |   6 +-
 .../presentation/widgets/catalog_filters_bar.dart  |   2 +
 .../presentation/widgets/difficulty_badge.dart     |   2 +
 .../tasks/presentation/widgets/progress_badge.dart |   2 +
 .../tasks/presentation/widgets/task_card.dart      |   2 +
 .../presentation/widgets/task_files_panel.dart     |   2 +
 sdlc/2-specs/use-cases/INDEX.md                    |  18 +--
 sdlc/3-design/design-system/INDEX.md               |  16 +--
 supabase/tests/rls_tests.sql                       | 128 +++++++++++++++++++++
 test/features/editor/editor_panel_test.dart        |  69 ++++++++++-
 test/features/editor/editor_test.dart              |  12 +-
 test/features/submissions/solutions_list_test.dart |  53 ++++++++-
 test/features/submissions/submissions_test.dart    |  16 +--
 test/features/submissions/submit_panel_test.dart   | 118 +++++++++++++++++--
 .../supabase_tasks_remote_data_source_test.dart    |   7 +-
 .../tasks/data/tasks_repository_impl_test.dart     |  15 +--
 .../tasks/presentation/catalog_screen_test.dart    |  27 +++--
 .../tasks/presentation/task_screen_test.dart       |  25 +++-
 web/pyodide_worker.js                              |   2 +
 48 files changed, 518 insertions(+), 72 deletions(-)
```

## Выполнено

Worktree `~/projects/yege_wars-TASK-4`, ветка `task/TASK-4`. Исходное
состояние сверено: `flutter test` — `00:13 +291: All tests passed!`;
`run_local.sh` — `RLS OK`.

### 1.1. Метки тестов Dart

Метка — в начале описания у 50 существующих тестов, тела не менялись. Десять
длинных описаний разбиты на соседние литералы, как в TASK-1, чтобы
`dart format` не сдвигал тело; у части тестов форматтер перенёс параметр
замыкания `tester` на новые строки. В диффе старых тестов — только строки
заголовков.

Без метки оставлены:

- тесты справки (срез «справочник»): `task_screen_test.dart` — «без ручных
  связей справка показывает статью по теме», «из справки к задаче можно
  перейти в статью»; `tasks_repository_impl_test.dart` — «справка по темам:
  статьи вторым запросом, ручные — следом», «без тем со статьями второй запрос
  не уходит»; `task_help_rules_test.dart` — все 8;
- тесты отдельных функций: `filePreview` (4), `fileSizeLabel` (2),
  `egeGroupLabel` (`ege_group_label_test.dart`, 2), `runStatusLabel` (3),
  `AnswerRules.fromOutput` и `AnswerFormat.fromValue` (`answer_rules_test.dart`,
  8), `attemptTimeLabel` («время попытки выводится коротко»);
- тесты устройства: `task_dto_test.dart` (7), `python_highlighter_test.dart`
  (11), «RunResult успешен только запуск, завершившийся сам», группа
  `PythonEditingController` (2), группа `SubmissionsRepositoryImpl` (5 — разбор
  ответа базы, DTO и вызов RPC), «обрыв связи превращается в сетевую ошибку»
  (`tasks_repository_impl_test.dart`, маппер ошибок);
- тесты без пути UC: «очистка убирает прошлый вывод» (у `RunController.clear`
  нет кнопки, находка 14 прохода 5), «сброс убирает вердикт», «подсказка под
  полем зависит от формата ответа», «у табличной задачи подсказка про таблицу
  по строкам» (подсказка формата есть в FIG-12, в путях UC её нет).

Какие тесты слоя данных получили метку — Обсуждение, п. 3; тесты, где
проверяется и путь, и справка, — п. 4.

### 1.2. Метки RLS-тестов

Метка — строкой-комментарием `-- UC-n-P-nn: что проверяется` перед проверкой,
как в TASK-1. Размечено 24 существующие проверки:

| Раздел | Метки |
|---|---|
| (б) `task_answers` | UC-23-P-01 — под учеником и под администратором |
| (в) видимость задач | UC-14-P-01, UC-15-P-02 |
| (г) прямая запись в `submissions` | UC-24-P-01 — insert и update |
| (д) `submit_solution` | single — UC-19-P-01, UC-19-P-02; pair — UC-19-P-01; string — UC-19-P-01, UC-19-P-02 |
| (е) лимит отправок | UC-19-P-04 |
| (ж) чужие попытки | UC-22-P-01 — до публикации не видны; UC-22-P-01 — видна ровно опубликованная по решённой задаче; UC-22-P-02 — по нерешённой не видна |
| (з) `set_solution_published` | UC-20-P-04 — `[not_owner]` и `[not_correct]`; UC-20-P-01 — публикация; UC-20-P-02 — снятие |
| (м) `get_task_stats` | UC-14-P-01 |
| (н) закрытые колонки и `tasks_public` | UC-23-P-01 — `reference_solution` и `answer_explanation`; UC-14-P-01, UC-15-P-02 — `tasks_public`; UC-15-P-02 — файл неопубликованной задачи не виден; UC-15-P-01 — файл опубликованной виден |
| (п) матрица прав | UC-23-P-01, UC-24-P-01 |

Без метки в этих разделах: блоки сетапа (ж) — попытки Боба и его публикация;
(п) — права на `task_articles` (срез «справочник»).

### 1.3. Недостающие тесты

Ровно минимум задания; сверх него тестов нет (Обсуждение, п. 1).

| Путь | Где | Что проверяет |
|---|---|---|
| [UC-15-P-03](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-03) | `task_screen_test.dart` | `NetworkFailure` при загрузке задачи — текст сбоя, кнопка «Повторить», страницы задачи нет |
| [UC-17-P-01](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-01) | `editor_panel_test.dart` | во время запуска среда сообщает `loading` — «Загружаю Python — это разовая загрузка, потерпите», «Запустить» доступна, «Стоп» нет |
| [UC-17-P-04](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-04) | `editor_panel_test.dart` | исход `timedOut` — «Не уложилось в отведённое время», текст ошибок результата в консоли |
| [UC-19-P-02](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-02) | `rls_tests.sql`, (у) | опубликованная задача без эталона: два разных ответа — оба неверны, записаны 2 неверные попытки |
| [UC-19-P-05](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-05) | `rls_tests.sql`, (у) | неопубликованная и несуществующая задача — `[task_not_found]`; по неопубликованной попыток нет |
| [UC-19-P-06](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-06) | `submit_panel_test.dart` | `NetworkFailure` при отправке — текст сбоя ниже кнопки «Отправить ответ», вердикта нет |
| [UC-20-P-03](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-03) | `submit_panel_test.dart` | «Не сейчас» — блок «Задача решена!» скрыт, публикация не вызвана |
| [UC-20-P-04](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-04) | `submit_panel_test.dart` | публикация вернула `NetworkFailure` — вызов был, текста сбоя нет, блок скрыт, переключатель выключен до и после |
| [UC-21-P-02](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-02) | `submit_panel_test.dart` | без попыток — «Попыток пока не было» |
| [UC-21-P-03](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-03) | `submit_panel_test.dart` | `myAttempts` в ошибке; заголовок «Мои попытки» есть, «Попыток пока не было», переключателя и текста сбоя нет |
| [UC-22-P-04](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-04) | `solutions_list_test.dart` | `publishedSolutions` в ошибке; в `SolutionsList` индикатор загрузки, текста сбоя и «Пока никто не опубликовал…» нет |
| [UC-24-P-01](../2-specs/use-cases/UC-24-ACTOR-4-EVT-19-ENT-11-ATTEMPT-DENIED-IN-SUBMISSION.md#uc-24-p-01) | `rls_tests.sql`, (у) | прямой delete из `submissions` под учеником — permission denied |

Раздел (у) — новый, в конце `rls_tests.sql` перед итогом. Отправляет в нём
новый ученик `frank`, чтобы не задевать попытки и счётчик частоты остальных;
задача без эталона `t-nokey` — опубликованная, без номера. «Попытки нет» в
UC-19-P-05 проверяется после отказа: ошибку ловит подблок, и её изменения
откатываются, так что отсутствие попытки обеспечено откатом, как и у вызова
через API.

Пути на экране, где сбой молчит, проверены как построено (UC-20-P-04,
UC-21-P-03, UC-22-P-04). Тест UC-22-P-04 открывает вкладку конечным числом
кадров: индикатор крутится бесконечно, и `pumpAndSettle` его не дождётся —
для этого у помощника `openSolutions` появился параметр `settle`. Повторы
упавшего провайдера Riverpod учтены: проверяется, что провайдер в ошибке
(`error` — та же `NetworkFailure`), а экран при этом показывает то, что в пути.

Холостота: каждая из 14 новых проверок запущена с перевёрнутым ожиданием —
все падают; файлы возвращены, `sha256` совпали. Выводы — в «Проверках».

Пути, которые тестом не проверить: нет. Части UC-17, которые живут только в
`PyodideRuntime` и `web/pyodide_worker.js` (обрезка вывода до 20 000 символов,
сообщение таймаута, загрузка Pyodide с зеркал, новая загрузка среды после
«Стоп» и таймаута), Dart-тестами не проверены: они работают только в
браузере, а пути UC-17 по решению постановки проверяются на
`FakePythonRuntime`.

### 1.4. Метки в коде и комментарии

Только doc-комментарии и комментарий в начале `web/pyodide_worker.js`; код не
менялся. Метки `UC-n` — строго по таблице задания «Где реализованы UC в
клиенте» (Обсуждение, п. 5).

| Где | Метка |
|---|---|
| `CatalogScreen`, `CatalogFiltersBar`, `TaskFilterController`, `catalog` (`catalog_controllers.dart`), `ListCatalogUseCase`, `GetEgeNumbersUseCase`, `TasksRepositoryImpl`, `SupabaseTasksRemoteDataSource` | `UC-14` |
| `TaskScreen`, `TaskFilesPanel`, `GetTaskUseCase`, `downloadTextFile` (`lib/core/download/web_file_download.dart`) | `UC-15` |
| `EditorPanel` | `UC-16`, `UC-17` |
| `DraftStorage`, `PreferencesDraftStorage`, `taskDraft` (`editor_providers.dart`) | `UC-16` |
| `RunController`, `PythonRuntime`, `PyodideRuntime`, `web/pyodide_worker.js` | `UC-17` |
| `AnswerRules` | `UC-18` |
| `SubmitPanel` | `UC-18`, `UC-19`, `UC-20` |
| `SubmitController`, `SubmitAnswerUseCase`, `SubmissionsRepositoryImpl`, `SupabaseSubmissionsRemoteDataSource` | `UC-19` |
| `AttemptsList` | `UC-20`, `UC-21` |
| `PublishController` | `UC-20` |
| `myAttempts` | `UC-21` |
| `SolutionsList`, `publishedSolutions` | `UC-22` |
| `TaskCard` | `COMP-5` |
| `DifficultyBadge` | `COMP-6` |
| `ProgressBadge` | `COMP-7` |
| `CodeEditor`, `PythonEditingController` | `COMP-8` |
| `ConsoleView` | `COMP-9` |
| `VerdictBanner` | `COMP-10` |
| `CodeBlock` (`lib/core/markdown/code_block.dart`) | `COMP-11` |
| `ReferenceErrorView` | `COMP-12` |

Формулировки — `/// Реализует UC-n.` и `/// Воплощает COMP-n.` отдельным
абзацем в конце doc-комментария, как в TASK-1.

Устаревшие фразы заменены:

- `TaskScreen`: было «Редактор кода, запуск и отправка ответа появятся на
  следующих этапах; место под них уже выделено правой колонкой на широком
  экране»; стало «Редактор кода с запуском и отправкой ответа и решения
  других — тоже здесь: на широком экране справа от условия, на узком —
  вкладками».
- `EditorPanel`: было «Отправка ответа появится на следующем этапе»; стало
  «Под консолью — отправка ответа, [SubmitPanel]».

UC-23 и UC-24 реализованы только в базе, метки у них — только в тестах; в
индексе «Где реализован» у них «не покрыто», как решено при постановке.

### Путь → тесты с его меткой

Таблицу собрали те же разборщики, что использует `sdlc_tool run`
(`parse_flutter_events`, `flutter_rows`, `sql_rows`), по JSON-отчёту
итогового `flutter test` и по `rls_tests.sql`. Все 33 пути среза — с
тестами, все строки — `success`; SQL-строки получают вердикт `rls`. Сам
`run` не запускался.

| Путь | Тесты с меткой |
|---|---|
| [UC-14-P-01](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-01) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `listCatalog UC-14-P-01: собирает карточки, прогресс и статистику`<br>`test/features/tasks/data/tasks_repository_impl_test.dart`: `listCatalog UC-14-P-01: задача без моих попыток — не начата`<br>`test/features/tasks/data/supabase_tasks_remote_data_source_test.dart`: `UC-14-P-01: каталог идёт по номеру, затем по названию — по возрастанию`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-01: показывает задачи с группировкой по номеру`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-01: задача без номера КИМ попадает в группу «Без номера»`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-01: показывает статус и статистику`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-01: нажатие на карточку открывает задачу`<br>`supabase/tests/rls_tests.sql`: `UC-14-P-01, UC-15-P-02: студенту видны только опубликованные задачи, неопубликованная — нет`<br>`supabase/tests/rls_tests.sql`: `UC-14-P-01: доля решивших в каталоге считается только по ученикам`<br>`supabase/tests/rls_tests.sql`: `UC-14-P-01, UC-15-P-02: tasks_public отдаёт опубликованную задачу и не отдаёт черновик` |
| [UC-14-P-02](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-02) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `listCatalog UC-14-P-02: отбор по прогрессу выполняется на клиенте`<br>`test/features/tasks/data/tasks_repository_impl_test.dart`: `listCatalog UC-14-P-02: фильтр уходит в datasource без изменений`<br>`test/features/tasks/data/tasks_repository_impl_test.dart`: `UC-14-P-02: номера заданий приходят без повторов и по порядку`<br>`test/features/tasks/data/supabase_tasks_remote_data_source_test.dart`: `UC-14-P-02: номера для фильтра идут по возрастанию`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-02: фильтр по сложности уходит в запрос`<br>`test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-02: фильтр по состоянию решения уходит в запрос` |
| [UC-14-P-03](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-03) | `test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-03: пустой каталог объясняет себя` |
| [UC-14-P-04](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-04) | `test/features/tasks/presentation/catalog_screen_test.dart`: `UC-14-P-04: ошибка каталога показывается с повтором` |
| [UC-15-P-01](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-01) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `getTask UC-15-P-01: собирает условие, файлы и справку`<br>`test/features/tasks/data/supabase_tasks_remote_data_source_test.dart`: `UC-15-P-01: файлы задачи идут по sort_order по возрастанию`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-01: показывает условие и подсказку про справку`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-01: на узком экране условие, справка и файлы — вкладки`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-01: файл разворачивается и показывает первые строки`<br>`supabase/tests/rls_tests.sql`: `UC-15-P-01: файл опубликованной задачи ученику виден` |
| [UC-15-P-02](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-02) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `getTask UC-15-P-02: неизвестная задача — понятная ошибка`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-02: ошибка загрузки показывается с повтором`<br>`supabase/tests/rls_tests.sql`: `UC-14-P-01, UC-15-P-02: студенту видны только опубликованные задачи, неопубликованная — нет`<br>`supabase/tests/rls_tests.sql`: `UC-14-P-01, UC-15-P-02: tasks_public отдаёт опубликованную задачу и не отдаёт черновик`<br>`supabase/tests/rls_tests.sql`: `UC-15-P-02: файл неопубликованной задачи ученику не виден` |
| [UC-15-P-03](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-03) | `test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-03: сбой связи показывается сообщением с повтором` |
| [UC-16-P-01](../2-specs/use-cases/UC-16-ACTOR-4-EVT-13-ENT-8-DRAFT-SAVED-IN-EDITOR.md#uc-16-p-01) | `test/features/editor/editor_test.dart`: `PreferencesDraftStorage UC-16-P-01: сохраняет и читает черновик задачи`<br>`test/features/editor/editor_test.dart`: `PreferencesDraftStorage UC-16-P-01: пустой черновик удаляется`<br>`test/features/editor/editor_panel_test.dart`: `UC-16-P-01: черновик подставляется и сохраняется` |
| [UC-17-P-01](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-01) | `test/features/editor/editor_panel_test.dart`: `UC-17-P-01: запуск передаёт код и файлы задачи`<br>`test/features/editor/editor_test.dart`: `RunController UC-17-P-01: запуск передаёт код, ввод и файлы задачи`<br>`test/features/editor/editor_test.dart`: `RunController UC-17-P-01: состояние среды приходит из потока`<br>`test/features/editor/editor_panel_test.dart`: `UC-17-P-01, UC-17-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет`<br>`test/features/editor/editor_panel_test.dart`: `UC-17-P-01: пока грузится среда, «Запустить» доступна, а «Стоп» — нет` |
| [UC-17-P-02](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-02) | `test/features/editor/editor_panel_test.dart`: `UC-17-P-02: ошибка программы показывается в консоли` |
| [UC-17-P-03](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-03) | `test/features/editor/editor_test.dart`: `RunController UC-17-P-03: «Стоп» доходит до среды`<br>`test/features/editor/editor_panel_test.dart`: `UC-17-P-01, UC-17-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет` |
| [UC-17-P-04](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-04) | `test/features/editor/editor_panel_test.dart`: `UC-17-P-04: таймаут — сообщение в консоли и своя строка состояния` |
| [UC-17-P-05](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-05) | `test/features/editor/editor_test.dart`: `RunController UC-17-P-05: ошибка среды попадает в состояние` |
| [UC-18-P-01](../2-specs/use-cases/UC-18-ACTOR-4-EVT-15-ENT-9-ANSWER-FILLED-IN-SUBMISSION.md#uc-18-p-01) | `test/features/submissions/submit_panel_test.dart`: `UC-18-P-01: ответ подставляется из вывода программы`<br>`test/features/submissions/submit_panel_test.dart`: `UC-18-P-01: для multi из вывода берётся вся таблица одной строкой`<br>`test/features/submissions/submit_panel_test.dart`: `UC-18-P-01: для остальных форматов из вывода берётся последняя строка` |
| [UC-19-P-01](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-01) | `test/features/submissions/submit_panel_test.dart`: `UC-19-P-01, UC-20-P-01: верный ответ показывает вердикт и предлагает публикацию`<br>`test/features/submissions/submissions_test.dart`: `SubmitAnswerUseCase UC-19-P-01: непустой ответ уходит в репозиторий`<br>`test/features/submissions/submissions_test.dart`: `SubmitAnswerUseCase UC-19-P-01: ответ уходит без пробельных краёв, включая переводы строк`<br>`test/features/submissions/submissions_test.dart`: `SubmitController UC-19-P-01: успешная отправка кладёт вердикт в состояние`<br>`test/features/submissions/submit_panel_test.dart`: `UC-19-P-01: ответ уходит без пробельных краёв`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-01, UC-19-P-02: single — верный ответ засчитан, '012' равен '12', неверный не засчитан`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-01: pair — лишние пробелы не влияют на верный ответ`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-01, UC-19-P-02: string — посимвольно с учётом регистра, другой регистр не засчитан` |
| [UC-19-P-02](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-02) | `test/features/submissions/submit_panel_test.dart`: `UC-19-P-02: неверный ответ публиковать не предлагают`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-01, UC-19-P-02: single — верный ответ засчитан, '012' равен '12', неверный не засчитан`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-01, UC-19-P-02: string — посимвольно с учётом регистра, другой регистр не засчитан`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-02: задача без эталонного ответа — любой ответ неверен, попытка записана` |
| [UC-19-P-03](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-03) | `test/features/submissions/submissions_test.dart`: `SubmitAnswerUseCase UC-19-P-03: пустой ответ до сервера не доходит`<br>`test/features/submissions/submissions_test.dart`: `SubmitAnswerUseCase UC-19-P-03: ответ из одних переводов строк считается пустым` |
| [UC-19-P-04](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-04) | `test/features/submissions/submissions_test.dart`: `SubmitController UC-19-P-04: ошибка отправки видна в состоянии`<br>`test/features/submissions/submit_panel_test.dart`: `UC-19-P-04: ошибка отправки показывается текстом из базы`<br>`supabase/tests/rls_tests.sql`: `UC-19-P-04: отправка сверх лимита за минуту — [rate_limit]` |
| [UC-19-P-05](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-05) | `supabase/tests/rls_tests.sql`: `UC-19-P-05: неопубликованная и несуществующая задача — [task_not_found], попытки нет` |
| [UC-19-P-06](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-06) | `test/features/submissions/submit_panel_test.dart`: `UC-19-P-06: сбой связи при отправке — текст под кнопкой, вердикта нет` |
| [UC-20-P-01](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-01) | `test/features/submissions/submit_panel_test.dart`: `UC-19-P-01, UC-20-P-01: верный ответ показывает вердикт и предлагает публикацию`<br>`test/features/submissions/submissions_test.dart`: `SubmitController UC-20-P-01: публикация зовёт репозиторий`<br>`supabase/tests/rls_tests.sql`: `UC-20-P-01: публикация своей верной попытки — время публикации записано` |
| [UC-20-P-02](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-02) | `supabase/tests/rls_tests.sql`: `UC-20-P-02: снятие с публикации — время публикации снято` |
| [UC-20-P-03](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-03) | `test/features/submissions/submit_panel_test.dart`: `UC-20-P-03: «Не сейчас» скрывает блок и не публикует` |
| [UC-20-P-04](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-04) | `test/features/submissions/submit_panel_test.dart`: `UC-20-P-04: публикация не прошла — сообщения нет, блок скрыт, переключатель прежний`<br>`supabase/tests/rls_tests.sql`: `UC-20-P-04: публикация чужой попытки — [not_owner]`<br>`supabase/tests/rls_tests.sql`: `UC-20-P-04: публикация своей неверной попытки — [not_correct]` |
| [UC-21-P-01](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-01) | `test/features/submissions/submit_panel_test.dart`: `UC-21-P-01: мои попытки показываются с вердиктом` |
| [UC-21-P-02](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-02) | `test/features/submissions/submit_panel_test.dart`: `UC-21-P-02: без попыток — «Попыток пока не было»` |
| [UC-21-P-03](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-03) | `test/features/submissions/submit_panel_test.dart`: `UC-21-P-03: сбой загрузки попыток — ни списка, ни сообщения` |
| [UC-22-P-01](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-01) | `test/features/submissions/solutions_list_test.dart`: `UC-22-P-01: после верного ответа видны чужие решения`<br>`supabase/tests/rls_tests.sql`: `UC-22-P-01: решившему задачу неопубликованные попытки других не видны`<br>`supabase/tests/rls_tests.sql`: `UC-22-P-01: решившему видна ровно опубликованная попытка другого по этой задаче` |
| [UC-22-P-02](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-02) | `test/features/submissions/solutions_list_test.dart`: `UC-22-P-02: без своего верного ответа решения закрыты`<br>`supabase/tests/rls_tests.sql`: `UC-22-P-02: опубликованная попытка другого по задаче, которую ученик не решил, не видна` |
| [UC-22-P-03](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-03) | `test/features/submissions/solutions_list_test.dart`: `UC-22-P-03: решивший видит пустое состояние, если решений нет` |
| [UC-22-P-04](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-04) | `test/features/submissions/solutions_list_test.dart`: `UC-22-P-04: сбой загрузки решений — индикатор загрузки без сообщения` |
| [UC-23-P-01](../2-specs/use-cases/UC-23-ACTOR-4-EVT-18-ENT-10-ANSWER-KEY-DENIED-IN-SUBMISSION.md#uc-23-p-01) | `supabase/tests/rls_tests.sql`: `UC-23-P-01: select из task_answers под студентом — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-23-P-01: select из task_answers под админом — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-23-P-01: select reference_solution под студентом — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-23-P-01: select answer_explanation под студентом — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-23-P-01: у клиентских ролей нет прав на task_answers и колонки эталона и разбора в tasks` |
| [UC-24-P-01](../2-specs/use-cases/UC-24-ACTOR-4-EVT-19-ENT-11-ATTEMPT-DENIED-IN-SUBMISSION.md#uc-24-p-01) | `supabase/tests/rls_tests.sql`: `UC-24-P-01: прямой insert в submissions — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-24-P-01: прямой update submissions — permission denied`<br>`supabase/tests/rls_tests.sql`: `UC-24-P-01: у клиентских ролей на submissions только select — ни insert, ни update, ни delete`<br>`supabase/tests/rls_tests.sql`: `UC-24-P-01: прямой delete из submissions — permission denied` |

## Не выполнено

- `python3 -m sdlc_tool run` не запускался: по заданию его прогоняет
  постановщик при приёмке.
- Части путей, у которых есть тест с меткой, но не всё в пути проверено, —
  без новых тестов по решению владельца (Обсуждение, п. 1); перечень — в
  «Найдено вне задания», п. 1.

## Проверки

Итоговое состояние — рабочее дерево перед коммитом `3798858`, вошло в него
без изменений:

- `flutter pub get`, `flutter gen-l10n`,
  `dart run build_runner build --delete-conflicting-outputs` — код 0;
  последняя строка: `Built with build_runner/aot in 4s; wrote 16 outputs.`
- `flutter analyze --fatal-infos --fatal-warnings`:
  `No issues found! (ran in 5.0s)`
- `dart run custom_lint`: `No issues found!`
- `flutter test`: `00:09 +300: All tests passed!` — 291 прежних и 9 новых
- `find lib test … | xargs -0 dart format --output=none --set-exit-if-changed`:
  `Formatted 190 files (0 changed) in 0.18 seconds.`, код 0
- `bash supabase/tests/run_local.sh`, строки размеченных и новых проверок и
  конец:

```
NOTICE:  OK: (б) select из task_answers под студентом — permission denied
NOTICE:  OK: (б) select из task_answers под админом — permission denied
NOTICE:  OK: (в) студент видит только опубликованные задачи, админ — все
NOTICE:  OK: (г) прямой insert в submissions — permission denied
NOTICE:  OK: (г) прямой update submissions — permission denied
NOTICE:  OK: (д) single: верный/неверный ответ, нормализация '012' = '12'
NOTICE:  OK: (д) pair: '  12   7 ' и '12 7' эквивалентны
NOTICE:  OK: (д) string: регистр значим
NOTICE:  OK: (е) rate limit: четвёртая отправка подряд отклонена с [rate_limit]
NOTICE:  OK: (ж) до публикации чужие попытки не видны
NOTICE:  OK: (ж) Боб опубликовал по одной верной попытке (t-pair и t-other)
NOTICE:  OK: (ж) после публикации видны ровно опубликованные попытки по решённой задаче
NOTICE:  OK: (з) публикация чужой попытки — [not_owner]
NOTICE:  OK: (з) публикация своей неверной попытки — [not_correct]
NOTICE:  OK: (з) публикация своей верной попытки: published_at заполнен
NOTICE:  OK: (з) снятие публикации: published_at очищен
NOTICE:  OK: (м) get_task_stats: solved_percent считается только по студентам
NOTICE:  OK: (у) сетап: ученик frank и задача без эталона
NOTICE:  OK: (у) задача без эталона: любой ответ неверен, попытки записаны
NOTICE:  OK: (у) неопубликованная и несуществующая задача — [task_not_found], попытки нет
NOTICE:  OK: (у) прямой delete из submissions — permission denied
NOTICE:  RLS TESTS PASSED
RLS OK
```

- `python3 -m sdlc_tool views`, затем `python3 -m sdlc_tool check`:
  `Итог: 0 ошибок, 6 предупреждений` — все 6 о ссылках TASK-1 и
  RESULT-TASK-1-01 на похороненные UC-11-P-01…UC-11-P-03, как в исходном
  состоянии.
- В `lib/` изменены только строки `///`: добавлено 81 (78 — метки, 3 — новые
  фразы `TaskScreen` и `EditorPanel`), удалено 3 (устаревшие фразы), других
  изменённых строк 0. В `web/pyodide_worker.js` добавлено 2 строки
  комментария. `git diff --stat supabase/migrations` — пусто.
- Индексы: «Где реализован» заполнено у UC-14 (7 файлов), UC-15 (4), UC-16
  (4), UC-17 (5), UC-18 (2), UC-19 (5), UC-20 (3), UC-21 (2), UC-22 (2), у
  COMP-5…COMP-12 (у COMP-8 — 2 файла, у остальных — по 1); у UC-23 и UC-24 —
  «не покрыто».

Холостота новых проверок — ожидание перевёрнуто, запуск, файл возвращён. По
одной порче за запуск: Dart — `flutter test <файл> --plain-name <тест>`, SQL —
`run_local.sh`.

| Путь | Что перевёрнуто | Вывод |
|---|---|---|
| UC-15-P-03 | текст сбоя `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Нет соединения с сервером. Проверьте` / `Some tests failed.` |
| UC-17-P-01 | «Стоп» `onPressed` `isNull` → `isNotNull` | `Expected: not null` / `Actual: <null>` / `Some tests failed.` |
| UC-17-P-04 | «Не уложилось…» `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Не уложилось в отведённое время": [` / `Some tests failed.` |
| UC-19-P-06 | текст сбоя `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Нет соединения с сервером. Проверьте` / `Some tests failed.` |
| UC-20-P-03 | `lastPublishedId` `isNull` → `isNotNull` | `Expected: not null` / `Actual: <null>` / `Some tests failed.` |
| UC-20-P-04 | переключатель после сбоя `isFalse` → `isTrue` | `Expected: true` / `Actual: <false>` / `Some tests failed.` |
| UC-21-P-02 | «Попыток пока не было» `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Попыток пока не было": [` / `Some tests failed.` |
| UC-21-P-03 | «Попыток пока не было» `findsNothing` → `findsOneWidget` | `Expected: exactly one matching candidate` / `Actual: _TextWidgetFinder:<Found 0 widgets with text "Попыток пока не было": []>` / `Some tests failed.` |
| UC-22-P-04 | индикатор `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _DescendantWidgetFinder:<Found 1 widget with type "CircularProgressIndicator" descending` / `Some tests failed.` |
| UC-19-P-02 | `is_correct is not false` → `is not true` | `rls_tests.sql:2521: ERROR:  ТЕСТ ПРОВАЛЕН (у): у задачи без эталона ответ засчитан: {"is_correct": false, "submission_id": "…"}` |
| UC-19-P-02 | `v_cnt <> 2` → `v_cnt = 2` | `rls_tests.sql:2521: ERROR:  ТЕСТ ПРОВАЛЕН (у): у задачи без эталона записано неверных попыток: 2, ожидалось 2` |
| UC-19-P-05 | `sqlerrm not like '[task_not_found]%'` → `like` | `rls_tests.sql:2556: ERROR:  ТЕСТ ПРОВАЛЕН (у): ожидалась ошибка [task_not_found], получено: [task_not_found] Задача не найдена или недоступна.` |
| UC-19-P-05 | `v_cnt <> 0` → `v_cnt = 0` | `rls_tests.sql:2556: ERROR:  ТЕСТ ПРОВАЛЕН (у): по неопубликованной задаче записано попыток: 0` |
| UC-24-P-01 | ожидается, что delete проходит: `OK` и `ТЕСТ ПРОВАЛЕН` поменяны местами | `rls_tests.sql:2574: ERROR:  ТЕСТ ПРОВАЛЕН (у): прямой delete из submissions — permission denied` |

Код выхода: `flutter test` — 1, `run_local.sh` — 3 (psql с `ON_ERROR_STOP`).
После всех переворотов: `файлы возвращены как были: True`.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — нет.

По ходу:

1. 2026-10-08. Вопрос: какие непроверенные части путей с метками дописать
   тестами сверх минимума задания? Варианты, можно несколько: каталог и
   страница задачи (UC-14-P-02, UC-14-P-03, UC-15-P-01); запуск (UC-17-P-01,
   UC-17-P-03, UC-17-P-05); отправка и публикация (UC-19-P-01, UC-19-P-03,
   UC-20-P-01, UC-20-P-02, UC-21-P-01); база (UC-20-P-02, UC-23-P-01). Ответ
   владельца: «если этого нет в задаче, то лишнего делать не нужно, агент
   приемки разберется и если что, вернем задачу тебе в доработку». Сверх
   минимума 1.3 тестов нет.
2. 2026-10-08, СТОП 1. Вопрос: коммитить работу в `task/TASK-4`? Варианты:
   коммитить; не коммитить. Выбрано: **коммитить**.

Выбор исполнителя там, где задание его не предписывало:

3. Тесты слоя данных. Метку получили тесты репозитория и datasource задач,
   которые проверяют утверждение пути: порядок каталога и файлов в запросе,
   прогресс и доля решивших в карточке, отбор по состоянию решения на
   клиенте, список номеров для чипов, «не найдена» у неизвестной задачи. Без
   метки — разбор DTO, маппер ошибок и тесты `SubmissionsRepositoryImpl`: они
   проверяют, как устроен слой, а не утверждение пути.
4. Тесты, где проверяется и путь, и справка: «показывает условие и подсказку
   про справку», «на узком экране условие, справка и файлы — вкладки»
   (`task_screen_test.dart`) и «собирает условие, файлы и справку»
   (`tasks_repository_impl_test.dart`) получили метку UC-15-P-01: они
   проверяют условие и файлы задачи. Тесты только справки — без метки.
5. Метки `UC-n` в коде — только у перечисленных в таблице задания «Где
   реализованы UC в клиенте», с UC из той же строки таблицы; сверх таблицы
   меток нет. Что ещё реализует пути без метки — «Найдено вне задания», п. 2.
6. Формат SQL-метки — `-- UC-n-P-nn: что проверяется`, как в TASK-1: скрипт
   берёт имя строки SQL из текста комментария.
7. У помощника `openSolutions` (`solutions_list_test.dart`) появился параметр
   `settle` (по умолчанию прежнее поведение) — для теста UC-22-P-04 с
   бесконечным индикатором.

## Отступления от задания

Нет.

## Найдено вне задания

1. Части путей с метками, которые тестами не проверены (сверх минимума не
   дописывались — Обсуждение, п. 1):
   - UC-14-P-02: повторное нажатие чипа снимает условие, поиск через 300 мс,
     «Сбросить фильтры», номера не загрузились — чипов нет;
   - UC-14-P-03: «По этим условиям задач нет» при заданных условиях;
   - UC-15-P-01: на экране — «Задание N» и сложность, «Источник: …», размер
     файла, «Файл скопирован в буфер обмена», «У задачи нет файлов с данными»;
   - UC-17-P-01: «Готово за N с» и ввод из поля «Ввод (stdin)» на экране;
     UC-17-P-03: «Остановлено» на экране (на подделке «Стоп» завершает запуск
     исходом `finished`); UC-17-P-05: причина в консоли и повторный запуск;
   - UC-19-P-01: «Отправляю…», код из редактора уходит вместе с ответом,
     «Мои попытки» обновляются; UC-19-P-03 и UC-19-P-05: текст на экране;
   - UC-20-P-01: переключатель включается после публикации; UC-20-P-02:
     выключение переключателя на экране и «другим больше не видно» в базе;
   - UC-21-P-01: время попытки на экране, у неверной попытки нет
     переключателя;
   - UC-23-P-01: отказ администратору в колонках эталона и разбора отдельно
     не проверен (его покрывает только матрица прав (п): роль та же
     `authenticated`); что в `tasks_public` нет этих колонок, не проверено.
2. Код, который реализует пути среза, но метки не получил — его нет в таблице
   задания или строка таблицы называет не все его UC: провайдер `task`
   (`catalog_controllers.dart`, UC-15) и `catalogEgeNumbers` (UC-14-P-02:
   без номеров каталог работает); `TasksRepositoryImpl.getTask` и
   `SupabaseTasksRemoteDataSource.fetchTask`/`fetchFiles` — UC-15, а у классов
   только `UC-14`; `SubmissionsRepositoryImpl` и
   `SupabaseSubmissionsRemoteDataSource` — ещё UC-20…UC-22, а у классов
   только `UC-19`; `runStatusLabel` (строки состояния UC-17).
3. Устаревший doc-комментарий `_TaskSidePanels`
   (`lib/features/tasks/presentation/screens/task_screen.dart`): «Правая
   колонка широкого экрана: место редактора, справка и файлы» — в колонке
   уже сам редактор и решения других. Не менялся: задание называет только
   `TaskScreen` и `EditorPanel`.
