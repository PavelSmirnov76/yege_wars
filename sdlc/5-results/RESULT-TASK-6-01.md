# RESULT-TASK-6-01: Черновик в базе, «Стоп» во время загрузки Python, сбои загрузки и публикации

## Задание

[TASK-6](../4-tasks/TASK-6-DRAFT-RUN-FAILURES.md).

## Коммит работы

`2837ec0` — «TASK-6: черновик в базе, «Стоп» во время загрузки Python, сбои
загрузки и публикации», ветка `task/TASK-6`, после «да» владельца на СТОПе 2
(«Обсуждение», п. 21). Индексы в этом коммите собраны без сдачи; сдача и
индексы с ней — отдельным коммитом.

```
2837ec0576eacd7970ed40916fe32c536d81a080
TASK-6: черновик в базе, «Стоп» во время загрузки Python, сбои загрузки и публикации

 lib/app/provider_retry.dart                        |  11 +
 lib/core/network/supabase_schema.dart              |  15 +
 lib/core/python_runtime/pyodide_runtime.dart       |   6 +-
 lib/core/python_runtime/python_runtime.dart        |  11 +-
 .../data/datasources/draft_remote_data_source.dart |  11 +
 .../supabase_draft_remote_data_source.dart         |  58 ++++
 .../editor/data/preferences_draft_storage.dart     |  32 --
 .../data/repositories/draft_repository_impl.dart   |  78 +++++
 lib/features/editor/domain/draft_storage.dart      |  13 -
 .../domain/repositories/draft_repository.dart      |  17 +
 .../domain/use_cases/save_draft_use_case.dart      |  21 ++
 lib/features/editor/editor_providers.dart          |  28 +-
 .../presentation/controllers/draft_controller.dart |  91 +++++
 .../presentation/controllers/run_controller.dart   |   6 +-
 .../editor/presentation/widgets/editor_panel.dart  |  69 ++--
 .../supabase_reference_remote_data_source.dart     |   2 +-
 .../repositories/reference_repository_impl.dart    |   2 +-
 .../domain/use_cases/get_article_use_case.dart     |   2 +-
 .../domain/use_cases/list_articles_use_case.dart   |   2 +-
 .../controllers/reference_controllers.dart         |   8 +-
 .../presentation/screens/article_screen.dart       |   2 +-
 .../presentation/screens/reference_screen.dart     |   2 +-
 .../presentation/widgets/article_filters_bar.dart  |   2 +-
 .../controllers/submissions_controllers.dart       |  39 ++-
 .../presentation/widgets/attempts_list.dart        |  33 +-
 .../presentation/widgets/solutions_list.dart       |  10 +-
 .../presentation/widgets/submit_panel.dart         |  43 ++-
 .../tasks/presentation/screens/task_screen.dart    |  72 +++-
 lib/main.dart                                      |   6 +-
 pubspec.lock                                       |   2 +-
 pubspec.yaml                                       |   3 +-
 sdlc/2-specs/use-cases/INDEX.md                    |  14 +-
 supabase/migrations/20261009120000_drafts.sql      |  66 ++++
 supabase/tests/rls_tests.sql                       | 311 ++++++++++++++++-
 test/app/router/app_router_test.dart               |   2 +
 test/core/markdown/app_markdown_test.dart          |   4 +-
 test/features/editor/editor_panel_test.dart        | 374 ++++++++++++++++++---
 test/features/editor/editor_test.dart              | 268 ++++++++++++++-
 .../data/reference_repository_impl_test.dart       |   4 +-
 ...supabase_reference_remote_data_source_test.dart |   2 +-
 .../reference/domain/article_filter_test.dart      |   6 +-
 .../presentation/article_screen_test.dart          |  79 +++--
 .../presentation/reference_screen_test.dart        |  60 ++--
 test/features/submissions/solutions_list_test.dart |  96 ++++--
 test/features/submissions/submissions_test.dart    |   2 +-
 test/features/submissions/submit_panel_test.dart   | 185 ++++++++--
 .../tasks/presentation/task_screen_test.dart       |  71 +++-
 test/helpers/fake_draft_repository.dart            |  54 +++
 test/helpers/fake_python_runtime.dart              |  34 +-
 test/helpers/fake_reference_repository.dart        |   4 +
 test/helpers/fake_submissions_repository.dart      |  25 +-
 test/helpers/pump_app.dart                         |  38 +--
 web/pyodide_worker.js                              |   2 +-
 53 files changed, 1977 insertions(+), 421 deletions(-)
```

## Выполнено

Worktree `~/projects/yege_wars-TASK-6`, ветка `task/TASK-6` на `1d3e435`.
Исходное состояние сверено 2026-10-09: `flutter analyze` —
`No issues found!`; `custom_lint` — `No issues found!`; `flutter test` —
`00:14 +310: All tests passed!`; `dart format` — `Formatted 190 files
(0 changed)`; `run_local.sh` — `RLS TESTS PASSED`, `RLS OK`;
`python3 -m sdlc_tool views`, затем `check` — `Итог: 0 ошибок,
178 предупреждений`, `views` производных файлов не изменил.

СТОП 0: план решений до кода — 2026-10-09, по всем 9 пунктам ответы
владельца («Обсуждение», пп. 1–9). По ходу — дефект публикации и решение
владельца по нему («Обсуждение», п. 10).

### 1.1. База — `drafts`

Миграция `supabase/migrations/20261009120000_drafts.sql` — позже последней
`20261007100000_set_task_answer.sql`; применённые миграции не тронуты.
Устройство — «Обсуждение», п. 1: таблица `public.drafts` по ENT-15,
первичный ключ `(user_id, task_id)`, оба внешних ключа `on delete cascade`,
`updated_at` при перезаписи ставит триггер `touch_updated_at()`; RLS —
`drafts_select`, `drafts_insert`, `drafts_update`, `drafts_delete` для
`authenticated`, без `is_admin()`; `revoke all` у `anon` и `authenticated`,
затем `grant select, insert, update, delete` для `authenticated`. Метка
миграции — `UC-31`.

`supabase/tests/rls_tests.sql`:

- матрица (п): строка `('drafts', 'authenticated',
  'DELETE,INSERT,SELECT,UPDATE')`;
- новый раздел (ф), после (у). Запись — тем же `insert … on conflict
  (user_id, task_id) do update`, что шлёт PostgREST на upsert; пишет alice по
  опубликованной `t-single`.

| Проверка | Метка | Что проверяет |
|---|---|---|
| автор пишет черновик и читает его | UC-31-P-01 | upsert `print(1)`, чтение своей строки |
| автор перезаписывает черновик | UC-31-P-01 | второй upsert отдельной транзакцией: строка одна, код `print(2)`, `updated_at` новее прежнего |
| чужой черновик не виден и не меняется | — | под учеником bob и администратором boss: строки alice не видно; `update` и `delete` с `where` и без `where` — 0 строк; вставка за другого и upsert поверх чужой строки — `insufficient_privilege`; строка alice цела, новой строки нет |
| по невидимой задаче черновик не записать | — | upsert по `t-unpub` и перенос своей строки на `t-unpub` — `insufficient_privilege` |
| аноним не может ничего | — | `select`, `insert`, `update`, `delete` — permission denied |
| автор удаляет свой черновик | UC-31-P-02 | удалена 1 строка, осталось 0 |
| с задачей и пользователем удаляется черновик | — | удаление задачи и пользователя (`auth.users`) удаляет их черновики («Обсуждение», п. 1) |

### 1.2. Клиент — черновик (UC-31)

Устройство — «Обсуждение», пп. 2–4.

- Домен: `DraftRepository` (`load`, `save`, `delete`) —
  `lib/features/editor/domain/repositories/draft_repository.dart`;
  `SaveDraftUseCase` — `lib/features/editor/domain/use_cases/save_draft_use_case.dart`:
  код из одних пробельных символов (`trim().isEmpty`) — `delete`, иначе
  `save`.
- Данные: `DraftRemoteDataSource` и `SupabaseDraftRemoteDataSource`
  (`lib/features/editor/data/datasources/`) — upsert с `user_id` из сессии,
  `onConflict: 'user_id,task_id'`, чтение и удаление по `user_id` и
  `task_id`; без сессии — `AuthSessionMissingException`.
  `DraftRepositoryImpl` (`lib/features/editor/data/repositories/`) — записи
  одной задачи по очереди, загрузка ждёт незаконченной записи той же задачи.
  `SupabaseTables.drafts`, `DraftColumns` — в `supabase_schema.dart`.
- Провайдеры (`editor_providers.dart`): `draftRepositoryProvider` и
  `saveDraftUseCaseProvider` — keepAlive.
- `DraftController` (`lib/features/editor/presentation/controllers/draft_controller.dart`)
  — по id задачи: `build` грузит черновик (нет строки — `''`, сбой — ошибка);
  держит текущий код в памяти страницы; `edit` — запись через
  `draftSaveDelay` 1 с после последней правки; `flush` — запись сразу без
  ожидания; при снятии страницы (`onDispose`) — запись сразу. Пишется только
  код, который отличается от последнего записанного или загруженного; после
  сбоя код остаётся незаписанным.
- `TaskScreen`: страница открыта, когда загружены и задача, и черновик; пока
  нет обоих — индикатор и заголовок «Каталог»; сбой любого — COMP-12 вместо
  страницы, «Повторить» — `invalidate` задачи и черновика. `_TaskBody`
  записывает черновик сразу, когда гаснет `TickerMode` — ветка навигации
  спрятана (переход в другой раздел или по ссылке на статью).
- `EditorPanel`: поле кода создаётся с текущим кодом `DraftController` и
  отдаёт ему каждую правку; «Запустить» и Ctrl/Cmd+Enter сначала зовут
  `flush()`. `SubmitPanel`: «Отправить ответ» и Enter в поле ответа сначала
  зовут `flush()`. Запуск и отправка записи не ждут.
- Удалены `lib/features/editor/domain/draft_storage.dart`,
  `lib/features/editor/data/preferences_draft_storage.dart`,
  `draftStorageProvider` и `taskDraftProvider`. `shared_preferences` — из
  `dependencies` в `dev_dependencies` (`pubspec.lock`: `direct main` →
  `direct dev`); в `lib/` и `web/` нет `shared_preferences`,
  `SharedPreferences`, `localStorage`, `sessionStorage`, `indexedDB`.

### 1.3. Запуск (UC-32)

- `runtimeStateOnReady({required bool isRunPending})` в
  `lib/core/python_runtime/python_runtime.dart`: идёт запуск — `running`,
  нет — `ready`; `PyodideRuntime._onMessage` на `ready` ставит её результат
  (раньше во время запуска состояние оставалось `loading` до конца
  программы).
- `RunState.isBusy` — `loading` или `running`. «Запустить» недоступна, а
  «Стоп» доступна при `isBusy`; Ctrl/Cmd+Enter при `isBusy` ничего не делает.
- «Стоп» во время загрузки — прежний `PyodideRuntime.stop()`: воркер
  убивается, исход `stopped`, строка состояния «Остановлено». Таймаут не
  менялся.

### 1.4. Публикация (UC-33)

- `PublishController.setPublished` возвращает `Failure?` (`null` — вышло),
  `build` — `void`: прежний `state` никто не читал. На время запроса —
  `ref.keepAlive()`: контроллер никто не слушает, и раньше он снимался до
  ответа базы, а список попыток не перезапрашивался («Обсуждение», п. 10).
- Блок «Задача решена!» (`SubmitPanel`): вышло — блок скрывается; сбой — блок
  остаётся, под его кнопками цветом ошибки текст сбоя, нажать можно снова.
- Переключатель «Опубликовано» (`AttemptsList`): сбой — SnackBar с текстом
  сбоя, список не перезапрашивается, переключатель прежний.
- Новых строк l10n нет.

### 1.5. Списки и автоповтор (UC-34…UC-37)

- `noProviderRetry` (`lib/app/provider_retry.dart`) — `retry` у
  `ProviderScope` в `main.dart`, `pumpApp` и `app_router_test.dart`.
- `AttemptsList` и `SolutionsList`: `AsyncError` — COMP-12
  (`ReferenceErrorView`) с текстом сбоя, «Повторить» — `invalidate` своего
  провайдера. `_TaskSolutions` (`TaskScreen`): свои попытки не загрузились —
  COMP-12 в «Решениях», «Повторить» перезапрашивает попытки («Обсуждение»,
  п. 8).

### 1.6. Метки

- Скриптом в scratchpad (метка — голый id, соседи — не буква, не цифра и не
  дефис): 73 замены в 23 файлах — `lib/` 15 в 10, `test/` 46 в 11,
  `web/pyodide_worker.js` 1, `supabase/tests/rls_tests.sql` 11; номера путей
  те же. Ещё вручную, в переписанных файлах: `EditorPanel` (было UC-16 и
  UC-17), `run_controller.dart` (UC-17), `submissions_controllers.dart`
  (UC-20, UC-21, UC-22), `AttemptsList` (UC-20, UC-21), `SolutionsList`
  (UC-22), `SubmitPanel` (UC-20); `draft_storage.dart`,
  `preferences_draft_storage.dart` и прежние `editor_providers.dart` (UC-16)
  удалены или переписаны. Меток на UC-16, 17, 20, 21, 22, 25, 26 в `lib/`,
  `test/`, `web/`, `supabase/` нет: `grep` — 0 строк; `check` их не
  показывает (предупреждения — только записи `sdlc/`).
- Код с метками путей задания:

| UC | Файлы |
|---|---|
| UC-31 | миграция `20261009120000_drafts.sql`; `draft_repository.dart`, `save_draft_use_case.dart`, `supabase_draft_remote_data_source.dart`, `draft_repository_impl.dart`, `draft_controller.dart`, `editor_panel.dart`, `submit_panel.dart`, `task_screen.dart`, `provider_retry.dart` |
| UC-32 | `python_runtime.dart`, `pyodide_runtime.dart`, `run_controller.dart`, `editor_panel.dart`, `web/pyodide_worker.js` |
| UC-33 | `submissions_controllers.dart` (`PublishController`), `attempts_list.dart`, `submit_panel.dart` |
| UC-34 | `submissions_controllers.dart` (`myAttempts`), `attempts_list.dart`, `provider_retry.dart` |
| UC-35 | `submissions_controllers.dart` (`publishedSolutions`), `solutions_list.dart`, `task_screen.dart` (`_TaskSolutions`), `provider_retry.dart` |
| UC-36 | файлы справочника, бывшие UC-25 (6), `provider_retry.dart` |
| UC-37 | файлы справочника, бывшие UC-26 (5), `provider_retry.dart` |

### 1.7. Тесты

`flutter test`: 335 тестов — 310 прежних и 25 новых; 11 прежних
переписаны на новое поведение, остальные — только метки.

Переписаны:

- `editor_panel_test.dart`: «пока грузится среда, «Запустить» доступна, а
  «Стоп» — нет» → UC-32-P-01 «пока грузится среда и пока выполняется
  программа, «Запустить» недоступна, а «Стоп» доступна»; «черновик
  подставляется и сохраняется» → UC-31-P-01 «черновик из базы стоит в поле,
  правка записывается через 1 с после последней»;
- `editor_test.dart`: группа `PreferencesDraftStorage` (2 теста) → группа
  `SaveDraftUseCase` (UC-31-P-01, UC-31-P-02);
- `submit_panel_test.dart`: UC-33-P-04 «публикация не прошла — сообщения
  нет, блок скрыт» → «публикация из блока не прошла — блок остаётся, под
  кнопками текст ошибки, опубликовать можно снова»; UC-34-P-03 «ни списка,
  ни сообщения» → «сразу сообщение и «Повторить» вместо списка»;
- `solutions_list_test.dart`: UC-35-P-04 «индикатор загрузки без
  сообщения» → «сразу сообщение и «Повторить» вместо списка»;
- `reference_screen_test.dart`: UC-36-P-04 «индикатор, пока идут повторы»
  → «сразу сообщение и «Повторить», без автоповторов»; UC-36-P-02 «значения
  фильтров не загрузились…» держался на повторах (список поднимался сам) —
  теперь его поднимает «Повторить», в названии «до перезагрузки страницы»;
- `article_screen_test.dart`: UC-37-P-02 и UC-37-P-03 — сразу, без повторов.

Новые: `editor_panel_test.dart` — 10 (UC-31-P-01 — 6, UC-31-P-02,
UC-31-P-03, UC-32-P-01 «Ctrl+Enter…», UC-32-P-03 «Стоп во время
загрузки»); `editor_test.dart` — 10 (`DraftRepositoryImpl` — 4,
`SupabaseDraftRemoteDataSource` — 4, `runtimeStateOnReady` — 2);
`submit_panel_test.dart` — 3 (UC-33-P-01, UC-33-P-02 — ответ базы через
несколько кадров; UC-33-P-04 — переключатель); `solutions_list_test.dart` —
1 (UC-35-P-04 — свои попытки не загрузились); `task_screen_test.dart` — 1
(UC-31-P-04).

Тестовые помощники: `pumpApp` — `retry: noProviderRetry`, параметр
`drafts` — `FakeDraftRepository`; `pumpUntilRetriesEnd` удалён — пользователей
не осталось; `FakeDraftRepository` — новый файл
`test/helpers/fake_draft_repository.dart`, `FakeDraftStorage` удалён из
`fake_python_runtime.dart`; `FakePythonRuntime` — «Стоп» во время запуска
отдаёт исход `stopped`; `FakeSubmissionsRepository` — `publishGate`,
`attemptsCalls`, `solutionsCalls`; `FakeReferenceRepository` —
`articleCalls`. Подробно — «Обсуждение», пп. 11–19.

#### Путь → тесты с его меткой

Таблицу собрали разборщики `sdlc_tool run` (`parse_flutter_events`,
`flutter_rows`, `sql_rows`) по JSON-отчёту итогового `flutter test` и по
`rls_tests.sql`; сам `run` не запускался. Все 27 путей — с тестами, Dart —
`PASS`, SQL — вердикт `rls`.

| Путь | Тесты с меткой |
|---|---|
| [UC-31-P-01](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-01) | `supabase/tests/rls_tests.sql`: `UC-31-P-01: автор перезаписывает черновик — строка одна, время записи новое`<br>`supabase/tests/rls_tests.sql`: `UC-31-P-01: автор пишет черновик и читает его`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01, UC-32-P-01: «Запустить» сразу записывает черновик, а запуск записи не ждёт`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: «Отправить ответ» сразу записывает черновик, отправка записи не ждёт, после неё черновик остаётся`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: без правок ни кнопки, ни уход черновик не пишут`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: переход в другой раздел записывает черновик сразу`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: правка переживает смену вкладки и раскладки`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: уход со страницы назад в каталог записывает черновик сразу`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-01: черновик из базы стоит в поле, правка записывается через 1 с после последней`<br>`test/features/editor/editor_test.dart`: `DraftRepositoryImpl UC-31-P-01: загрузка ждёт незаконченной записи той же задачи`<br>`test/features/editor/editor_test.dart`: `DraftRepositoryImpl UC-31-P-01: записи задачи идут по очереди — следующая после ответа на предыдущую`<br>`test/features/editor/editor_test.dart`: `DraftRepositoryImpl UC-31-P-01: черновик читается из строки базы, нет строки — черновика нет`<br>`test/features/editor/editor_test.dart`: `SaveDraftUseCase UC-31-P-01: код записывается черновиком задачи`<br>`test/features/editor/editor_test.dart`: `SupabaseDraftRemoteDataSource UC-31-P-01: черновик пишется upsert по ключу «пользователь, задача»`<br>`test/features/editor/editor_test.dart`: `SupabaseDraftRemoteDataSource UC-31-P-01: черновик читается своей строкой задачи` |
| [UC-31-P-02](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-02) | `supabase/tests/rls_tests.sql`: `UC-31-P-02: автор удаляет свой черновик`<br>`test/features/editor/editor_panel_test.dart`: `UC-31-P-02: код из одних пробельных символов удаляет черновик — при следующем открытии поле пустое`<br>`test/features/editor/editor_test.dart`: `SaveDraftUseCase UC-31-P-02: код из одних пробельных символов удаляет черновик`<br>`test/features/editor/editor_test.dart`: `SupabaseDraftRemoteDataSource UC-31-P-02: удаляется своя строка задачи` |
| [UC-31-P-03](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-03) | `test/features/editor/editor_panel_test.dart`: `UC-31-P-03: сбой записи экран не показывает, следующая запись — по кнопке и при уходе — пишет код снова`<br>`test/features/editor/editor_test.dart`: `DraftRepositoryImpl UC-31-P-03: сбой записи — ошибка в результате, следующая запись уходит` |
| [UC-31-P-04](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-04) | `test/features/tasks/presentation/task_screen_test.dart`: `UC-31-P-04: задача загрузилась, а черновик нет — вместо страницы сразу сообщение и «Повторить»` |
| [UC-32-P-01](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-01) | `test/features/editor/editor_panel_test.dart`: `UC-31-P-01, UC-32-P-01: «Запустить» сразу записывает черновик, а запуск записи не ждёт`<br>`test/features/editor/editor_panel_test.dart`: `UC-32-P-01, UC-32-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет`<br>`test/features/editor/editor_panel_test.dart`: `UC-32-P-01: Ctrl+Enter во время запуска не запускает программу второй раз`<br>`test/features/editor/editor_panel_test.dart`: `UC-32-P-01: запуск передаёт код и файлы задачи`<br>`test/features/editor/editor_panel_test.dart`: `UC-32-P-01: пока грузится среда и пока выполняется программа, «Запустить» недоступна, а «Стоп» доступна`<br>`test/features/editor/editor_test.dart`: `RunController UC-32-P-01: запуск передаёт код, ввод и файлы задачи`<br>`test/features/editor/editor_test.dart`: `RunController UC-32-P-01: состояние среды приходит из потока`<br>`test/features/editor/editor_test.dart`: `runtimeStateOnReady UC-32-P-01: Python загрузился во время запуска — программа выполняется` |
| [UC-32-P-02](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-02) | `test/features/editor/editor_panel_test.dart`: `UC-32-P-02: ошибка программы показывается в консоли` |
| [UC-32-P-03](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-03) | `test/features/editor/editor_panel_test.dart`: `UC-32-P-01, UC-32-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет`<br>`test/features/editor/editor_panel_test.dart`: `UC-32-P-03: «Стоп» во время загрузки среды прерывает её — «Остановлено»`<br>`test/features/editor/editor_test.dart`: `RunController UC-32-P-03: «Стоп» доходит до среды` |
| [UC-32-P-04](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-04) | `test/features/editor/editor_panel_test.dart`: `UC-32-P-04: таймаут — сообщение в консоли и своя строка состояния` |
| [UC-32-P-05](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-05) | `test/features/editor/editor_test.dart`: `RunController UC-32-P-05: ошибка среды попадает в состояние` |
| [UC-33-P-01](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-01) | `supabase/tests/rls_tests.sql`: `UC-33-P-01: публикация своей верной попытки — время публикации записано`<br>`test/features/submissions/submissions_test.dart`: `SubmitController UC-33-P-01: публикация зовёт репозиторий`<br>`test/features/submissions/submit_panel_test.dart`: `UC-19-P-01, UC-33-P-01: верный ответ показывает вердикт и предлагает публикацию`<br>`test/features/submissions/submit_panel_test.dart`: `UC-33-P-01: после публикации из блока переключатель у попытки включён, даже если база ответила не сразу` |
| [UC-33-P-02](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-02) | `supabase/tests/rls_tests.sql`: `UC-33-P-02: снятие с публикации — время публикации снято`<br>`test/features/submissions/submit_panel_test.dart`: `UC-33-P-02: снятие с публикации переключателем — переключатель выключен, даже если база ответила не сразу` |
| [UC-33-P-03](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-03) | `test/features/submissions/submit_panel_test.dart`: `UC-33-P-03: «Не сейчас» скрывает блок и не публикует` |
| [UC-33-P-04](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-04) | `supabase/tests/rls_tests.sql`: `UC-33-P-04: публикация своей неверной попытки — [not_correct]`<br>`supabase/tests/rls_tests.sql`: `UC-33-P-04: публикация чужой попытки — [not_owner]`<br>`test/features/submissions/submit_panel_test.dart`: `UC-33-P-04: переключатель не переключился — внизу экрана сообщение с текстом ошибки, переключатель прежний`<br>`test/features/submissions/submit_panel_test.dart`: `UC-33-P-04: публикация из блока не прошла — блок остаётся, под кнопками текст ошибки, опубликовать можно снова` |
| [UC-34-P-01](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-01) | `test/features/submissions/submit_panel_test.dart`: `UC-34-P-01: мои попытки показываются с вердиктом` |
| [UC-34-P-02](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-02) | `test/features/submissions/submit_panel_test.dart`: `UC-34-P-02: без попыток — «Попыток пока не было»` |
| [UC-34-P-03](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-03) | `test/features/submissions/submit_panel_test.dart`: `UC-34-P-03: сбой загрузки попыток — сразу сообщение и «Повторить» вместо списка` |
| [UC-35-P-01](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-01) | `supabase/tests/rls_tests.sql`: `UC-35-P-01: решившему видна ровно опубликованная попытка другого по этой задаче`<br>`supabase/tests/rls_tests.sql`: `UC-35-P-01: решившему задачу неопубликованные попытки других не видны`<br>`test/features/submissions/solutions_list_test.dart`: `UC-35-P-01: после верного ответа видны чужие решения` |
| [UC-35-P-02](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-02) | `supabase/tests/rls_tests.sql`: `UC-35-P-02: опубликованная попытка другого по задаче, которую ученик не решил, не видна`<br>`test/features/submissions/solutions_list_test.dart`: `UC-35-P-02: без своего верного ответа решения закрыты` |
| [UC-35-P-03](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-03) | `test/features/submissions/solutions_list_test.dart`: `UC-35-P-03: решивший видит пустое состояние, если решений нет` |
| [UC-35-P-04](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-04) | `test/features/submissions/solutions_list_test.dart`: `UC-35-P-04: сбой загрузки решений — сразу сообщение и «Повторить» вместо списка`<br>`test/features/submissions/solutions_list_test.dart`: `UC-35-P-04: свои попытки не загрузились — в «Решениях» сообщение и «Повторить», а не «откроются после верного ответа»` |
| [UC-36-P-01](../2-specs/use-cases/obsolete/UC-36-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-36-p-01) | `supabase/tests/rls_tests.sql`: `UC-36-P-01, UC-37-P-01: опубликованная статья ученику видна`<br>`supabase/tests/rls_tests.sql`: `UC-36-P-01, UC-37-P-02, UC-28-P-02: неопубликованная статья ученику не видна`<br>`test/features/reference/data/supabase_reference_remote_data_source_test.dart`: `UC-36-P-01: статьи идут по уровню, затем по названию — по возрастанию`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-01: нажатие на карточку открывает статью`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-01: показывает список статей` |
| [UC-36-P-02](../2-specs/use-cases/obsolete/UC-36-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-36-p-02) | `test/features/reference/data/reference_repository_impl_test.dart`: `listArticles UC-36-P-02: фильтр передаётся в datasource без изменений`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-36-P-02: выбор другого значения заменяет прежнее`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-36-P-02: повторный выбор снимает условие`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-36-P-02: сброс очищает все условия`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-02: «Сбросить фильтры» снимает все условия и строку поиска, а текст в поле остаётся`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-02: выбор уровня уходит в запрос`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-02: значения фильтров не загрузились — чипов номеров и тегов нет до перезагрузки страницы, а список работает`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-02: строка поиска уходит в запрос через 300 мс после ввода`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-02: чипы номеров и тегов — из значений фильтров` |
| [UC-36-P-03](../2-specs/use-cases/obsolete/UC-36-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-36-p-03) | `test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-03: по заданным условиям статей нет`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-03: пустой справочник объясняет себя` |
| [UC-36-P-04](../2-specs/use-cases/obsolete/UC-36-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-36-p-04) | `test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-04: ошибка списка показывается с кнопкой повтора`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-36-P-04: сбой связи — сразу сообщение и «Повторить», без автоповторов` |
| [UC-37-P-01](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-01) | `supabase/tests/rls_tests.sql`: `UC-36-P-01, UC-37-P-01: опубликованная статья ученику видна`<br>`test/core/markdown/app_markdown_test.dart`: `UC-37-P-01: рисует заголовок, абзац и блок кода`<br>`test/core/markdown/app_markdown_test.dart`: `UC-37-P-01: таблица и цитата не ломают разметку`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-37-P-01: показывает заголовок, сведения и текст` |
| [UC-37-P-02](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-02) | `supabase/tests/rls_tests.sql`: `UC-36-P-01, UC-37-P-02, UC-28-P-02: неопубликованная статья ученику не видна`<br>`test/features/reference/data/reference_repository_impl_test.dart`: `getArticle UC-37-P-02: отсутствующая статья — понятная ошибка`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-37-P-02: статьи нет — сразу «Статья справочника не найдена.» и «Повторить»` |
| [UC-37-P-03](../2-specs/use-cases/UC-37-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-37-p-03) | `test/features/reference/presentation/article_screen_test.dart`: `UC-37-P-03: сбой связи — сразу сообщение и «Повторить», без автоповторов` |

Пути, которые тестом не проверить: нет. Строки кода без теста — «Найдено
вне задания», п. 1.

#### Состояние провайдера в тестах путей о сбое загрузки

Автоповтор выключен, поэтому тесты «сразу» открывают экран конечным числом
кадров — без `pumpAndSettle`, который прокрутил бы повторы под крутящимся
индикатором, — и утверждают состояние провайдера и число запросов.

| Тест | Когда проверки | Состояние провайдера |
|---|---|---|
| UC-31-P-04 «задача загрузилась, а черновик нет…» | 5 кадров по 100 мс после перехода | `taskProvider(slug)` — `AsyncData<TaskDetail>`, `draftControllerProvider(task-24)` — `AsyncError<String>`, `load` — 1 раз; утверждается в тесте. После «Повторить» — страница, `load` — 2 раза |
| UC-34-P-03 «сбой загрузки попыток…» | 5 кадров по 100 мс после открытия вкладки «Код» | `myAttemptsProvider(task-24)` — `AsyncError<List<Submission>>`, запросов 1; утверждается |
| UC-35-P-04 «сбой загрузки решений…» | 5 кадров по 200 мс после открытия вкладки «Решения» | `publishedSolutionsProvider(task-24)` — `AsyncError<List<Submission>>`, запросов 1; утверждается |
| UC-35-P-04 «свои попытки не загрузились…» | то же | `myAttemptsProvider(task-24)` — `AsyncError<List<Submission>>`, запросов 1; утверждается |
| UC-36-P-04 «сбой связи — сразу…» | 5 кадров по 100 мс; ещё через минуту | `articlesProvider` — `AsyncError<List<ArticleBrief>>`; утверждается. `listArticles` — 2 раза (список и значения фильтров), через минуту — те же 2 |
| UC-36-P-04 «ошибка списка показывается с кнопкой повтора» | после `pumpAndSettle` | `articlesProvider` — `AsyncError` (по коду; в тесте не утверждается, повторы ловит тест выше) |
| UC-36-P-02 «значения фильтров не загрузились…» | после `pumpAndSettle` | `articleFacetsProvider` — `AsyncData` с пустыми значениями: при ошибке возвращает `const ArticleFacets()`, не бросает (по коду; в тесте не утверждается). `articlesProvider` — `AsyncError`, после «Повторить» — `AsyncData` |
| UC-37-P-02 «статьи нет — сразу…» | 5 кадров по 100 мс | `articleProvider('no-such-article')` — `AsyncError<ReferenceArticle>`, запросов 1; утверждается |
| UC-37-P-03 «сбой связи — сразу…» | 5 кадров по 100 мс | `articleProvider('file-reading')` — `AsyncError<ReferenceArticle>`, запросов 1; утверждается |

#### Нехолостость

Порчи — на копии рабочего дерева в scratchpad (`rsync` без `.git`,
`pub get`, `gen-l10n`, `build_runner`), скриптом: по одной порче за прогон,
замена одного фрагмента в одном файле `lib/` или в миграции, прогон файла
теста задетого экрана (или `run_local.sh`), возврат файла со сверкой
`sha256`. 47 порч; в первом прогоне выжили 3 (M5, M6, D9) — тесты усилены
(«Обсуждение», пп. 15, 17), на них эти порчи падают. Код 3 у `run_local.sh`
— `psql` остановился на ошибке.

| № | Порча | Итог |
|---|---|---|
| M1 | `drafts_select`: `using (true)` | код 3: `ТЕСТ ПРОВАЛЕН (ф): bob видит чужой черновик` |
| M2 | `drafts_insert`: без `user_id = auth.uid()` | код 3: `ТЕСТ ПРОВАЛЕН (ф): bob записал черновик за другого` |
| M3 | `drafts_insert`: без `is_task_visible` | код 3: `ТЕСТ ПРОВАЛЕН (ф): записан черновик по неопубликованной задаче` |
| M4 | `drafts_update`: `with check` без `is_task_visible` | код 3: `ТЕСТ ПРОВАЛЕН (ф): черновик перенесён на неопубликованную задачу` |
| M5 | `drafts_update`: `using (true)` | первый прогон — код 0, выжила; после п. 15 — код 3: `ERROR:  new row violates row-level security policy for table "drafts"` |
| M6 | `drafts_delete`: `using (true)` | первый прогон — код 0, выжила; после п. 15 — код 3: `ТЕСТ ПРОВАЛЕН (ф): bob удалил чужой черновик без where` |
| M7 | `drafts_select`: `or public.is_admin()` | код 3: `ТЕСТ ПРОВАЛЕН (ф): boss видит чужой черновик` |
| M8 | без триггера `updated_at` | код 3: `ТЕСТ ПРОВАЛЕН (ф): время записи не обновилось` |
| M9 | `task_id` без `on delete cascade` | код 3: `ERROR:  update or delete on table "tasks" violates foreign key constraint "drafts_task_id_fkey"` |
| M10 | `user_id` без `on delete cascade` | код 3: `ERROR:  update or delete on table "profiles" violates foreign key constraint "drafts_user_id_fkey"` |
| M11 | `grant` без `delete` | код 3: `ТЕСТ ПРОВАЛЕН (п): матрица прав разошлась. Сверх ожидаемого: authenticated drafts: INSERT,SELECT,UPDATE. Не хватает: authenticated drafts: DELETE,INSERT,SELECT,UPDATE` |
| M12 | без `revoke all` | код 3: `ТЕСТ ПРОВАЛЕН (п): матрица прав разошлась. Сверх ожидаемого: anon drafts: DELETE,INSERT,MAINTAIN,REFERENCES,SELECT,TRIGGER,TRUNCATE,UPDATE; …` |
| M13 | без первичного ключа | код 3: `ERROR:  there is no unique or exclusion constraint matching the ON CONFLICT specification` |
| D1 | пауза записи 600 мс | код 1, UC-31-P-01 «…через 1 с после последней»: `Expected: empty`, `Actual: ['print(2)']` |
| D2 | правка не сбрасывает таймер | код 1, тот же тест: `Expected: ['print(2)']`, `Actual: ['print(2)', 'print(4)']` |
| D3 | `flush` пишет и без правок | код 1, UC-31-P-01 «без правок ни кнопки, ни уход черновик не пишут»: `Actual: ['print(1)', 'print(1)']` |
| D4 | снятие страницы не пишет | код 1: UC-31-P-01 «уход со страницы назад в каталог…», UC-31-P-03 |
| D5 | сбой записи считается записью | код 1, UC-31-P-03: `Expected: ['print(1)', 'print(1)']`, `Actual: ['print(1)']` |
| D6 | загруженный черновик не подставляется | код 1: UC-31-P-01 «черновик из базы стоит в поле…» (`Actual: ''`), UC-31-P-04 |
| D7 | «Запустить» не пишет черновик | код 1: UC-31-P-01, UC-32-P-01 «…«Запустить» сразу записывает…», UC-31-P-03 |
| D8 | запуск ждёт записи черновика | код 1, «…«Запустить» сразу записывает…»: `Expected: <1>`, `Actual: <0>` |
| D9 | поле — из загруженного черновика, а не из текущего кода | первый прогон — код 0, выжила; после п. 17 — код 1, «правка переживает смену вкладки и раскладки»: `Expected: 'print(1)'`, `Actual: ''` |
| D10 | «Отправить ответ» не пишет черновик | код 1: `Expected: ['print(446)']`, `Actual: []` |
| D11 | после отправки черновик удаляется | код 1: «…после неё черновик остаётся», «без правок…» |
| D12 | скрытие ветки не пишет | код 1, «переход в другой раздел записывает черновик сразу»: `Actual: []` |
| D13 | `TaskScreen`: страница открывается при сбое черновика | код 1, UC-31-P-04 |
| D14 | `TaskScreen`: сбой черновика — не сбой страницы | код 1, UC-31-P-04 |
| D15 | «Повторить» не перезапрашивает черновик | код 1, UC-31-P-04: `Expected: <2>`, `Actual: <1>` |
| D16 | пробельный код пишется, а не удаляется | код 1: `SaveDraftUseCase UC-31-P-02`, виджетный UC-31-P-02 — `Expected: [null]` |
| D17 | записи без очереди | код 1: `Expected: ['upsert print(1)']`, `Actual: ['upsert print(1)', 'upsert print(2)']` |
| D18 | загрузка не ждёт записи | код 1: `Actual: ['fetch task-24', 'upsert print(1)']` |
| D19 | upsert по ключу `task_id` | код 1: `Expected: 'user_id,task_id'`, `Actual: 'task_id'` |
| D20 | чтение без отбора по пользователю | код 1: «черновик читается своей строкой задачи», «без сессии…» |
| R1 | `runtimeStateOnReady` всегда `ready` | код 1: `Expected: PythonRuntimeState:<PythonRuntimeState.running>` |
| R2 | `isBusy` — только `running` | код 1: UC-32-P-01 «пока грузится среда…», UC-32-P-03 «Стоп во время загрузки…» |
| R3 | «Стоп» только при `isRunning` | код 1: те же два теста |
| R4 | Ctrl+Enter во время запуска запускает снова | код 1: `Expected: <2>`, `Actual: <3>` |
| P1 | без `ref.keepAlive()`, выход по `ref.mounted`, как было | код 1: UC-33-P-01 «…даже если база ответила не сразу», UC-33-P-02 «…даже если база ответила не сразу» |
| P2 | список перезапрашивается и после сбоя | код 1, UC-33-P-04 переключатель: `Expected: <1>`, `Actual: <2>` |
| P3 | блок скрывается при любом исходе | код 1, UC-33-P-04 блок |
| P4 | текст сбоя под блоком не показывается | код 1, UC-33-P-04 блок: `Found 0 widgets` |
| P5 | сбой переключателя без SnackBar | код 1, UC-33-P-04 переключатель |
| L1 | сбой попыток — пусто | код 1, UC-34-P-03 |
| L2 | «Повторить» у попыток ничего не делает | код 1, UC-34-P-03: `Expected: <2>`, `Actual: <1>` |
| L3 | сбой решений — индикатор | код 1, UC-35-P-04: найден `CircularProgressIndicator` |
| L4 | «Повторить» у решений ничего не делает | код 1, UC-35-P-04: `Expected: <2>`, `Actual: <1>` |
| L5 | сбой попыток — «Решения» закрыты | код 1, UC-35-P-04 «свои попытки не загрузились…» |
| T1 | `noProviderRetry` — до 10 повторов по 200 мс | код 1 во всех пяти файлах: UC-31-P-04, UC-34-P-03, UC-35-P-04 (оба), UC-36-P-04 «сбой связи — сразу…», UC-37-P-02, UC-37-P-03 — `Expected: <Instance of 'AsyncError<…>'>`, `Actual: AsyncLoading<…>(error: …)` |
| F1 | «Повторить» в справочнике сбрасывает и значения фильтров | код 1, UC-36-P-02 «значения фильтров не загрузились…»: `Expected: ['Базовый', 'Средний', 'Продвинутый']` |

После всех порч файлы копии совпали с исходными по `sha256`; в рабочем дереве
порч не было.

## Не выполнено

- `python3 -m sdlc_tool run` не запускался: по заданию его прогоняет
  постановщик при приёмке.
- Push не делался — по заданию.

## Проверки

Итоговое состояние — рабочее дерево на СТОПе 1, 2026-10-09; вошло в
коммит `2837ec0` без изменений:

- `flutter pub get`, `flutter gen-l10n`,
  `dart run build_runner build --delete-conflicting-outputs` — код 0;
  `pub get`: `shared_preferences 2.5.5 (from direct dependency to dev
  dependency) (2.5.6 available)`, `Changed 1 dependency!`
- `flutter analyze --fatal-infos --fatal-warnings`:
  `No issues found! (ran in 3.0s)`
- `dart run custom_lint`: `No issues found!`
- `flutter test`: `00:11 +335: All tests passed!` — 310 прежних и 25 новых
- `find lib test … | xargs -0 dart format --output=none --set-exit-if-changed`:
  `Formatted 196 files (0 changed) in 0.20 seconds.`, код 0
- `bash supabase/tests/run_local.sh`, строки (п), (ф) и конец:

```
NOTICE:  OK: (п) права anon и authenticated на public совпадают с задуманными
NOTICE:  OK: (ф) автор пишет черновик и читает его
NOTICE:  OK: (ф) автор перезаписывает черновик: строка одна, время записи новое
NOTICE:  OK: (ф) чужой черновик не виден и не меняется — ни ученику, ни администратору
NOTICE:  OK: (ф) по невидимой задаче черновик не записать
NOTICE:  OK: (ф) аноним — permission denied на select, insert, update и delete
NOTICE:  OK: (ф) автор удаляет свой черновик
NOTICE:  OK: (ф) с задачей и с пользователем удаляется и черновик
NOTICE:  RLS TESTS PASSED
RLS OK
```

- `python3 -m sdlc_tool views`, затем `python3 -m sdlc_tool check`:
  `Итог: 0 ошибок, 92 предупреждения` — было 178: ушли метки кода и тестов на
  похороненных UC; остались записи TASK, RESULT, ACC прошлых заданий, ENT-9
  и ACTOR-4 со ссылками на похороненное.
- `git diff HEAD --stat` по `lib/ test/ web/ supabase/ pubspec.*` без
  новых файлов: `43 files changed, 1563 insertions(+), 414 deletions(-)`;
  новые — миграция, `provider_retry.dart`, 6 файлов черновика в
  `lib/features/editor/`, `test/helpers/fake_draft_repository.dart`.
  `supabase/migrations/` (применённые), `.github/`, `reference/`,
  `supabase/seed/` не тронуты; в диффе значений окружения, ключей и адреса
  проекта нет.
- `README.md` не менялся: команды и окружение те же.

На боевой — «Применено к боевой» ниже: снимки «до» и «после», проверка
`public.drafts`.

## Применено к боевой

2026-10-09, после «да» владельца на СТОПе 1 («Обсуждение», п. 20). Доступы —
`set -a; . supabase/.env.local; set +a` внутри скрипта в scratchpad,
значения переменных не выводились. Клиент — PostgreSQL 17.10 (Homebrew),
сервер — 17.6.

0. Очередь: `git merge main` — `Already up to date.`; `main` — `1d3e435`,
   миграция задания позже последней в `main`.
1. Дамп: `pg_dump --schema=public --no-owner` (с правами) —
   `~/backups/yege_wars/before-drafts-20261009-034258.sql`, 7 303 628 байт,
   15 581 строка, `GRANT`/`REVOKE` — 163 строки, `drafts` — 0 вхождений. В
   конце — `-- PostgreSQL database dump complete` (строка 15 577), за ней
   служебная `\unrestrict …` pg_dump 17.
2. Снимок «до» — `begin read only`:

```
 server_version | read_only
----------------+-----------
 17.6           | on

 drafts
--------


 tables_in_public
------------------
               11
```

   Права `anon` и `authenticated` на объекты `public` — запрос матрицы (п):
   39 строк, совпадают с ожидаемыми строками (п) без `drafts`.
3. Миграция — `psql "$SEED_DATABASE_URL" -X -v ON_ERROR_STOP=1 -f
   supabase/migrations/20261009120000_drafts.sql`:

```
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
CREATE TRIGGER
ALTER TABLE
CREATE POLICY
CREATE POLICY
CREATE POLICY
CREATE POLICY
REVOKE
GRANT
```

4. Проверка `public.drafts` — `begin read only`:

```
 rls_enabled
-------------
 t

 column_name |        data_type         | is_nullable | column_default
-------------+--------------------------+-------------+----------------
 user_id     | uuid                     | NO          |
 task_id     | uuid                     | NO          |
 code        | text                     | NO          |
 updated_at  | timestamp with time zone | NO          | now()

       conname       |                           definition
---------------------+-----------------------------------------------------------------
 drafts_pkey         | PRIMARY KEY (user_id, task_id)
 drafts_task_id_fkey | FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
 drafts_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE

           tgname            |                                                         definition
-----------------------------+----------------------------------------------------------------------------------------------------------------------------
 trg_drafts_touch_updated_at | CREATE TRIGGER trg_drafts_touch_updated_at BEFORE UPDATE ON public.drafts FOR EACH ROW EXECUTE FUNCTION touch_updated_at()

  policyname   |  cmd   |      roles      |          qual          |                      with_check
---------------+--------+-----------------+------------------------+-------------------------------------------------------
 drafts_delete | DELETE | {authenticated} | (user_id = auth.uid()) |
 drafts_insert | INSERT | {authenticated} |                        | ((user_id = auth.uid()) AND is_task_visible(task_id))
 drafts_select | SELECT | {authenticated} | (user_id = auth.uid()) |
 drafts_update | UPDATE | {authenticated} | (user_id = auth.uid()) | ((user_id = auth.uid()) AND is_task_visible(task_id))

     role      |            privs
---------------+-----------------------------
 authenticated | DELETE,INSERT,SELECT,UPDATE

 rows
------
    0
```

5. Снимок «после» — `begin read only`:

```
 server_version | read_only
----------------+-----------
 17.6           | on

 drafts
--------
 drafts

 tables_in_public
------------------
               12
```

   Права — 40 строк; `diff` снимков «до» и «после»:

```
18a19
> drafts|authenticated|DELETE,INSERT,SELECT,UPDATE
```

Всё сошлось: в `public` на одну таблицу больше, права на прежние объекты не
изменились, новые — только на `drafts`. Данные не менялись, Content API не
использовался. Откат — из дампа шага 1.

## Обсуждение

До начала работы — план СТОПа 0, 2026-10-09, вопросами с вариантами по
пунктам.

1. Миграция `drafts`: таблица по ENT-15 (`user_id` → `profiles`, `task_id` →
   `tasks`, оба `on delete cascade`; `code text not null`; `updated_at
   default now()` и триггер `touch_updated_at()`; первичный ключ `(user_id,
   task_id)`, других индексов нет; длина кода не ограничена, как у
   `submissions.code`; «не пусто» в базе не проверяется), четыре политики
   `to authenticated` без `is_admin()`, `revoke all` у `anon` и
   `authenticated`, затем `grant select, insert, update, delete` для
   `authenticated`; строка `drafts` в (п); в (ф) запись — тем же `insert … on
   conflict do update`, что шлёт PostgREST, «чужой» — под другим учеником и
   под администратором. Вопрос: проверять ли в (ф) каскад (его нет в перечне
   задания, но он в ENT-15). Варианты: с каскадом, без метки пути; без
   каскада. Выбрано: **с каскадом**.
2. Черновик в клиенте: `DraftRepository` (`load`, `save` — upsert, `delete`),
   `SaveDraftUseCase` с правилом ENT-15 «из одних пробельных символов —
   `delete`» в домене, `SupabaseDraftRemoteDataSource` и `DraftRepositoryImpl`;
   `DraftStorage`, `PreferencesDraftStorage`, `draftStorageProvider` и
   `taskDraftProvider` удаляются, `FakeDraftStorage` → `FakeDraftRepository`.
   Вопрос: откуда `user_id` и куда `shared_preferences`. Варианты: клиент шлёт
   `auth.currentUser.id`, upsert `onConflict: 'user_id,task_id'`,
   `shared_preferences` — в `dev_dependencies`; `default auth.uid()` у
   колонки, клиент шлёт `task_id` и `code`; как первый, но
   `shared_preferences` остаётся в `dependencies`. Выбрано: **`user_id` из
   сессии, `shared_preferences` — в `dev_dependencies`**.
3. Загрузка черновика с задачей (UC-31-P-04). Варианты: отдельный провайдер в
   editor — `TaskScreen` ждёт и задачу, и черновик, сбой любого — COMP-12,
   «Повторить» перезапрашивает оба, +1 запрос по первичному ключу после
   задачи; поле `TaskDetail.draft`, черновик читает `getTask` в общем
   `Future.wait`. Выбрано: **отдельный провайдер**. «Черновика нет» — строки
   нет, поле кода пустое.
4. Сохранение. План: держатель — `DraftController` по id задачи, его слушает
   `TaskScreen` (переживает смену вкладки и раскладки), код — в памяти
   страницы; debounce 1 с; flush без ожидания — «Запустить» и Ctrl/Cmd+Enter,
   «Отправить ответ» и Enter (`SubmitPanel` зовёт `flush()` сам), снятие
   страницы (`onDispose`), скрытие ветки `indexedStack` (гаснет `TickerMode`);
   пишется, только если код отличается от последнего записанного или
   загруженного; записи одной задачи — по очереди в `DraftRepositoryImpl`,
   загрузка ждёт незаконченной записи; пустой код — `delete`; сбой — молча.
   Вопрос: что поменять против плана. Варианты: ничего; скрытие ветки без
   flush; писать без сравнения; без очереди записей. Выбрано: **ничего — как
   в плане**.
5. Автоповтор — штатный параметр `retry` у `ProviderScope` (`null` — не
   повторять). Вопрос: где одна точка настройки. Варианты: функция
   `noProviderRetry` в `lib/app/`, её передают `main.dart`, `pumpApp` и
   `app_router_test`, юнит-тесты на голом `ProviderContainer` не трогаются;
   свой виджет-обёртка `AppProviderScope`. Выбрано: **функция
   `noProviderRetry`**.
6. Запуск: `ready` во время запуска → `running`; «Запустить» недоступна и
   «Стоп» доступна при `RunState.isBusy` (`loading` или `running`);
   Ctrl/Cmd+Enter при `isBusy` ничего не делает. Вопрос: как закрепить
   тестом переход в `PyodideRuntime` (только браузер, на VM не создать).
   Варианты: чистая функция рядом с `PythonRuntimeState` и юнит-тест, строка
   вызова в `PyodideRuntime` — в сдачу без теста; без выноса, переход — в
   сдачу как непроверяемый. Выбрано: **чистая функция**.
7. Публикация. Вопрос: как экран узнаёт о сбое `PublishController`.
   Варианты: `setPublished` возвращает `Failure?` вызывающему (блок — текст
   под кнопками и повтор, переключатель — SnackBar), нечитаемый `state`
   контроллера убирается; общий `state` контроллера читают и блок, и
   переключатель. Выбрано: **возврат `Failure?`**.
8. Списки: при `AsyncError` в «Моих попытках» и «Решениях» — COMP-12
   (`ReferenceErrorView`), «Повторить» — `invalidate` своего провайдера.
   Вопрос: что в «Решениях», если не загрузились свои попытки. Варианты:
   COMP-12 с текстом сбоя попыток, «Повторить» перезапрашивает попытки; как
   сейчас — «Решения других откроются после твоего верного ответа». Выбрано:
   **COMP-12 и там**.
9. Тесты: новые и переписанные по перечню плана с учётом пп. 4, 6, 8; тесты
   сбоя загрузки открывают экран конечным числом кадров без `pumpAndSettle` и
   утверждают `AsyncError` и одно обращение к репозиторию;
   `pumpUntilRetriesEnd` удаляется; нехолостость — порчами `lib/` и миграции
   по одной за прогон, возврат со сверкой `sha256`. Варианты: как в плане;
   без счётчика обращений. Выбрано: **как в плане**.

По ходу:

10. 2026-10-09. Проба (временный виджет-тест, удалён): ответ базы на
    публикацию приходит через 5 кадров по 100 мс — после успеха попытки не
    перезапрашиваются (`попыток запрошено до публикации: 2`, `после
    публикации попыток запрошено: 2, переключатель: false`).
    `PublishController` — autoDispose, его никто не слушает: он уничтожается,
    пока идёт запрос, и после ответа выходит по `ref.mounted`. Переключатель
    у попытки остаётся прежним до перезагрузки — UC-33-P-01 и UC-33-P-02 в
    части переключателя не выполняются. Вопрос: чинить ли в TASK-6. Варианты:
    чинить в п. 7 — `ref.keepAlive()` на время запроса в `setPublished`, тест
    с ответом базы через несколько кадров; не чинить — в «Найдено вне
    задания». Выбрано: **чинить в п. 7**.

Выбор исполнителя там, где задание его не предписывало:

11. Виджет-тесты черновика — в `editor_panel_test.dart` (там был тест
    UC-16-P-01), юнит-тесты — в `editor_test.dart` на месте группы
    `PreferencesDraftStorage`. Datasource проверяется на настоящем
    `SupabaseClient` без сети (`RecordingSupabaseClient`), сессия ставится
    `auth.setInitialSession` без сети.
12. Тесты ухода со страницы после `go` и `pumpAndSettle` делают ещё кадр
    100 мс (помощник `settleAfterLeave`): страница снимается в конце кадра, а
    `flutter_riverpod` снимает autoDispose-контроллер по таймеру с нулевой
    задержкой — `pumpAndSettle` заканчивается раньше. Проверено временными
    тестами-пробами (удалены): страница уходит переходом через ~500 мс,
    запись — на следующем кадре, раньше паузы в 1 с. Тест «назад в каталог»
    проверяет запись через 0,8 с, до паузы.
13. `FakePythonRuntime`: «Стоп», пока `gate` не завершён, отдаёт исход
    `stopped` и состояние `idle`, как `PyodideRuntime.stop()`, — иначе
    «Остановлено» UC-32-P-03 тестом не проверить. Тест «во время выполнения
    «Стоп» доступен…» не менялся.
14. Подделки: `FakeDraftRepository` записывает вызовы (`writes`: код записи
    или `null` — удаление), правило пустого кода не повторяет — его гоняет
    настоящий `SaveDraftUseCase`; `writeGate` держит ответ записи.
    `FakeSubmissionsRepository.publishGate` — ответ базы на публикацию через
    несколько кадров, счётчики `attemptsCalls`, `solutionsCalls`;
    `FakeReferenceRepository.articleCalls`.
15. Порчи M5 и M6 (`using (true)` у update и delete) в первом прогоне выжили:
    проверки «чужого» шли с `where user_id = …`, условие читает строки, и их
    прятала select-политика. В (ф) добавлены `update` и `delete` без `where`
    под bob и boss — без них такая порча стирала бы и переписывала чужие
    черновики.
16. Метки сверх таблицы замен: `UC-31` — миграция, домен, данные,
    `DraftController`, `EditorPanel`, `SubmitPanel`, `TaskScreen`; `UC-35` —
    `TaskScreen` (`_TaskSolutions`); `UC-31`, `UC-34`…`UC-37` —
    `provider_retry.dart`; `UC-32` — `runtimeStateOnReady` в
    `python_runtime.dart` (файл и так был `UC-17` → `UC-32`).
17. Тест смены вкладки снимает фокус с поля кода: поле в фокусе держит
    вкладку `TabBarView` живой (`EditableText` —
    `AutomaticKeepAliveClientMixin`), и пересоздание панели не проверялось
    (порча D9 выжила). Тест проверяет, что панель снята, и ещё смену
    раскладки — узкий экран на широкий 1600 × 900.
18. Метки тестов слоя данных — по правилу TASK-4 и TASK-5: метку получил
    тест, который проверяет утверждение пути; «без сессии черновик не
    читается и не пишется» и «без запуска загруженная среда просто готова» —
    без метки.
19. Тест «без правок ни кнопки, ни уход черновик не пишут» помечен
    UC-31-P-01: правило «пишется только отличающийся код» — п. 4.

По ходу, после части 1:

20. 2026-10-09, СТОП 1. Вопрос: применять ли миграцию `drafts` к боевой
    (часть 2: обновить ветку от `main`, дамп, снимок «до» только на чтение,
    `psql -f` миграции, проверка `drafts`, снимок «после»). Варианты:
    применять; пока не применять. Выбрано: **применять**.
21. 2026-10-09, СТОП 2. Вопрос: коммитить работу и сдачу в `task/TASK-6`
    (два коммита, без push). Варианты: коммитить; не коммитить. Выбрано:
    **коммитить**.

## Отступления от задания

Нет.

## Найдено вне задания

1. Строки кода без теста: вызов `runtimeStateOnReady` в
   `PyodideRuntime._onMessage` — класс только для браузера, на VM его не
   создать (п. 6); `retry: noProviderRetry` в `main.dart` — `main_test.dart`
   проверяет только запуск без параметров сборки.
2. COMP-12 — виджет `ReferenceErrorView` в
   `lib/features/reference/presentation/widgets/`; им пользуются страница
   задачи и каталог, а теперь ещё «Мои попытки» и «Решения»: имя и место —
   от справочника.
3. Выход из учётной записи со страницы задачи: запись черновика при снятии
   страницы уходит уже без сессии и молча не проходит. Это пункт пула
   «сохранение при выходе из учётной записи», не чинилось.
4. На широком экране при сбое своих попыток COMP-12 стоит дважды — в «Моих
   попытках» и в «Решениях», с одним текстом (следствие п. 8).
