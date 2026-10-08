# TASK-4: Метки среза «задачи и решение» и недостающие тесты

## Основание

- Каталог задач — [UC-14-P-01](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-01), [UC-14-P-02](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-02), [UC-14-P-03](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-03), [UC-14-P-04](../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-04).
- Страница задачи — [UC-15-P-01](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-01), [UC-15-P-02](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-02), [UC-15-P-03](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-03).
- Черновик кода — [UC-16-P-01](../2-specs/use-cases/UC-16-ACTOR-4-EVT-13-ENT-8-DRAFT-SAVED-IN-EDITOR.md#uc-16-p-01).
- Запуск программы — [UC-17-P-01](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-01), [UC-17-P-02](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-02), [UC-17-P-03](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-03), [UC-17-P-04](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-04), [UC-17-P-05](../2-specs/use-cases/UC-17-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-EDITOR.md#uc-17-p-05).
- Ответ из вывода — [UC-18-P-01](../2-specs/use-cases/UC-18-ACTOR-4-EVT-15-ENT-9-ANSWER-FILLED-IN-SUBMISSION.md#uc-18-p-01).
- Отправка ответа — [UC-19-P-01](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-01), [UC-19-P-02](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-02), [UC-19-P-03](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-03), [UC-19-P-04](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-04), [UC-19-P-05](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-05), [UC-19-P-06](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-06).
- Публикация решения — [UC-20-P-01](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-01), [UC-20-P-02](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-02), [UC-20-P-03](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-03), [UC-20-P-04](../2-specs/use-cases/UC-20-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-20-p-04).
- Мои попытки — [UC-21-P-01](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-01), [UC-21-P-02](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-02), [UC-21-P-03](../2-specs/use-cases/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-03).
- Чужие решения — [UC-22-P-01](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-01), [UC-22-P-02](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-02), [UC-22-P-03](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-03), [UC-22-P-04](../2-specs/use-cases/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-04).
- Эталон через API — [UC-23-P-01](../2-specs/use-cases/UC-23-ACTOR-4-EVT-18-ENT-10-ANSWER-KEY-DENIED-IN-SUBMISSION.md#uc-23-p-01).
- Запись попытки через API — [UC-24-P-01](../2-specs/use-cases/UC-24-ACTOR-4-EVT-19-ENT-11-ATTEMPT-DENIED-IN-SUBMISSION.md#uc-24-p-01).
- Экраны — [FIG-11](../3-design/FIG-11-CATALOG.md), [FIG-12](../3-design/FIG-12-PROBLEM.md); компоненты — [COMP-5](../3-design/design-system/COMP-5-PROBLEM-CARD.md), [COMP-6](../3-design/design-system/COMP-6-DIFFICULTY-BADGE.md), [COMP-7](../3-design/design-system/COMP-7-PROGRESS-BADGE.md), [COMP-8](../3-design/design-system/COMP-8-CODE-EDITOR.md), [COMP-9](../3-design/design-system/COMP-9-CONSOLE.md), [COMP-10](../3-design/design-system/COMP-10-VERDICT.md), [COMP-11](../3-design/design-system/COMP-11-CODE-BLOCK.md), [COMP-12](../3-design/design-system/COMP-12-ERROR-RETRY.md).
- Бизнес-задачи — [BT-8](../1-business-tasks/planning/BT-8-PLANNING-CATALOG.md), [BT-9](../1-business-tasks/planning/BT-9-PLANNING-PROBLEM-PAGE.md), [BT-10](../1-business-tasks/planning/BT-10-PLANNING-RUN.md), [BT-11](../1-business-tasks/planning/BT-11-PLANNING-ANSWER-CHECK.md), [BT-12](../1-business-tasks/planning/BT-12-PLANNING-SOLUTIONS.md).

## Где работать

Первым шагом перейти в worktree задания: `EnterWorktree` с путём
`/Users/pavelsmirnov/projects/yege_wars-TASK-4`, ветка `task/TASK-4`. Все
правки, проверки и коммиты — только там. В `~/projects/yege_wars` ничего не
менять и в `main` не вливать: это делает постановщик после «принято».
Сгенерированного кода в worktree нет — начать с `pub get` и генерации из
«Проверок части 1».

## Зачем

Проход 5 описал срез «задачи и решение» как построено: 33 пути в UC-14…UC-24,
экраны FIG-11 и FIG-12, компоненты COMP-5…COMP-12. В коде и тестах среза нет
ни одной метки, поэтому сводка `sdlc/6-eval/DASHBOARD.md` показывает все 33
пути «НЕ ПРОВЕРЕНО», а бизнес-задачи BT-8…BT-12 не закрываются. Метки
связывают код и тесты со спеками (закон `sdlc/AGENTS.md`, «Код ссылается на
артефакты»). Задание ставит метки и дописывает тесты путям, у которых их нет.
Поведение продукта не меняется.

Вне задания: расхождения с ТЗ и находки из
`sdlc/0-vibes/raw/2026-10-08/as-built-problems.md` — их не чинить; справка на
странице задачи — срез «справочник»; тест заставки без метки UC-10-P-01 —
находка приёмки TASK-3, в задание не входит.

Прочитать перед работой: `CLAUDE.md`; закон `sdlc/AGENTS.md`, раздел «Код
ссылается на артефакты»; файлы UC, экранов и компонентов из «Основания»;
`sdlc/0-vibes/raw/2026-10-08/as-built-problems.md`; `sdlc_tool/README.md`,
разделы «Метки в коде» и «Прогон run»; образец такой же работы —
`sdlc/4-tasks/TASK-1-LABELS-AUTH.md` и `sdlc/5-results/RESULT-TASK-1-01.md`.
Сдача — по `sdlc/5-results/AGENTS.md`, прочитать до начала работы; номер
сдачи — `python3 -m sdlc_tool next RESULT TASK-4`.

## Решения, принятые при постановке

| Когда | Вопрос | Решение |
|---|---|---|
| 2026-10-08 | Пути, где экран молчит при сбое или не даёт нажать «Стоп» (UC-17 при загрузке среды, UC-20-P-04, UC-21-P-03, UC-22-P-04) — писать ли на них тесты | Владелец: «Тесты как построено» — тест закрепляет нынешнее поведение; исправлять его будут проходом по находкам, и тесты поменяются вместе с путями |
| 2026-10-08 | Устаревшие doc-комментарии `TaskScreen` и `EditorPanel` | Владелец: «Да, в тех же комментариях» — неверные фразы заменить тем, что есть; код и строки l10n не трогать |
| 2026-10-08 | Что входит | Постановщик: метки и недостающие тесты путям среза, как в TASK-1 (`sdlc/RUNBOOK.md`, «Разметка кода после прохода «как построено»») |
| 2026-10-08 | Метки в применённых миграциях | Постановщик: нет — применённые миграции не редактируют. UC-23 и UC-24 реализованы только в базе и метятся только в тестах; «Где реализован» у них останется «не покрыто» |
| 2026-10-08 | Формат метки теста Dart | Постановщик: в начале описания — метки путей, которые тест проверяет, через запятую: `test('UC-19-P-03: пустой ответ …')`, `testWidgets('UC-19-P-01, UC-20-P-01: …')` |
| 2026-10-08 | Формат метки теста SQL | Постановщик: строка-комментарий `-- UC-n-P-nn` перед проверкой в `supabase/tests/rls_tests.sql` |
| 2026-10-08 | Метки в коде | Постановщик: `UC-n` — в doc-комментарии класса или функции, которая реализует UC в клиенте; в `web/pyodide_worker.js` — в комментарии в начале файла; `COMP-n` — в doc-комментарии класса виджета компонента |
| 2026-10-08 | Тесты справки к задаче | Постановщик: не метить — справка входит в срез «справочник» |
| 2026-10-08 | Среда Python в тестах | Постановщик: `PyodideRuntime` и воркер работают только в браузере; пути UC-17 проверяются на подделке среды `FakePythonRuntime`. Браузерных тестов задание не добавляет |

## Исходное состояние (проверено 2026-10-08)

| Что | Состояние |
|---|---|
| Проверки | прогон `run` `2026-10-08-2a0988a` на том же коде клиента и базы: 10 из 10 `PASS`, 291 Dart-тест, `RLS OK`; CI на `b920bb9` зелёный. `python3 -m sdlc_tool check` — 0 ошибок, 6 предупреждений о записях TASK-1 и RESULT-TASK-1-01 (их не трогать) |
| Метки | `UC-14`…`UC-24` и `COMP-5`…`COMP-12` в `lib/`, `test/`, `web/`, `supabase/` нет ни одной |
| Тесты среза | `test/features/tasks/` (7 файлов), `test/features/editor/` (2), `test/features/submissions/` (4), `test/core/markdown/python_highlighter_test.dart`; в `supabase/tests/rls_tests.sql` — разделы (б) `task_answers`, (в) видимость задач, (г) прямая запись в `submissions`, (д) `submit_solution`, (е) лимит отправок, (ж) чужие попытки, (з) `set_solution_published`, (м) `get_task_stats`, (н) — закрытые колонки `tasks` и `tasks_public`, (п) матрица прав |
| Пути без тестов | UC-15-P-03 (сбой загрузки задачи — тест с повтором проверяет только «Задача не найдена»), UC-19-P-05 (`[task_not_found]`), UC-19-P-06 (сбой связи — все тесты ошибки отправки берут текст лимита), UC-20-P-03 («Не сейчас»), UC-21-P-02, UC-21-P-03, UC-22-P-04 |
| Пути, проверенные не целиком | UC-17-P-01 — нет проверки, что пока среда загружается, «Стоп» недоступна, а «Запустить» доступна; UC-17-P-04 — проверена только подпись исхода; UC-20-P-04 — отказ базы проверен в (з), молчание экрана — нет; UC-19-P-02 — нет проверки задачи без эталонного ответа; UC-24-P-01 — в (г) нет удаления. Остальное — выяснить при разметке |
| Компоненты ↔ виджеты | COMP-5 — `TaskCard`, COMP-6 — `DifficultyBadge`, COMP-7 — `ProgressBadge` (`lib/features/tasks/presentation/widgets/`); COMP-8 — `CodeEditor` и `PythonEditingController`, COMP-9 — `ConsoleView` (`lib/features/editor/presentation/widgets/`); COMP-10 — `VerdictBanner` (`lib/features/submissions/presentation/widgets/`); COMP-11 — `CodeBlock` (`lib/core/markdown/code_block.dart`); COMP-12 — `ReferenceErrorView` (`lib/features/reference/presentation/widgets/reference_error_view.dart`) |
| Где реализованы UC в клиенте | UC-14 — `CatalogScreen`, `CatalogFiltersBar`, `TaskFilterController` и `catalog` (`catalog_controllers.dart`), `ListCatalogUseCase`, `GetEgeNumbersUseCase`, `TasksRepositoryImpl`, `SupabaseTasksRemoteDataSource`; UC-15 — `TaskScreen`, `TaskFilesPanel`, `GetTaskUseCase`, `downloadTextFile` (`lib/core/download/`); UC-16 — `EditorPanel`, `DraftStorage`, `PreferencesDraftStorage`, `taskDraft`; UC-17 — `EditorPanel`, `RunController`, `PythonRuntime`, `PyodideRuntime`, `web/pyodide_worker.js`; UC-18 — `AnswerRules`, `SubmitPanel`; UC-19 — `SubmitPanel`, `SubmitController`, `SubmitAnswerUseCase`, `SubmissionsRepositoryImpl`, `SupabaseSubmissionsRemoteDataSource`; UC-20 — `SubmitPanel`, `AttemptsList`, `PublishController`; UC-21 — `AttemptsList`, `myAttempts`; UC-22 — `SolutionsList`, `publishedSolutions`. Метка — у тех, кто реализует путь, не обязательно у каждого из перечисленных |
| Устаревшие комментарии | `TaskScreen`: «Редактор кода, запуск и отправка ответа появятся на следующих этапах; место под них уже выделено правой колонкой на широком экране»; `EditorPanel`: «Отправка ответа появится на следующем этапе» |
| Ловушки | Riverpod 3 сам повторяет упавший провайдер — до 10 раз с паузами от 0,2 до 6,4 с; тесты сбоев загрузки должны это учитывать. Тесты справки в `task_screen_test.dart`, `tasks_repository_impl_test.dart` и `task_help_rules_test.dart` — срез «справочник». Применённые миграции `supabase/migrations/` не редактировать. `run` скрипта конвейера в worktree не запускать — его прогоняет постановщик при приёмке |
| Worktree `~/projects/yege_wars-TASK-4`, ветка `task/TASK-4` от `main` с этим заданием | это задание закоммичено в `main` до запуска — его не менять. `supabase/.env.local` — ссылка на файл основной копии; доступы к боевой не нужны |

## Часть 1. Локально

### 1.1. Метки тестов Dart

Пройти тесты среза. Каждому тесту, который проверяет путь UC из «Основания»,
поставить метку этого пути в начало описания. Тест, который проверяет
устройство, а не путь (разбор DTO, отдельная функция), и тест справки
остаются без метки. Меняется только описание теста, не его тело.

### 1.2. Метки RLS-тестов

В `supabase/tests/rls_tests.sql` поставить `-- UC-n-P-nn` перед каждой
проверкой пути среза: разделы (б), (в), (г), (д), (е), (ж), (з), (м), (н), (п) и
другие, если найдутся.

### 1.3. Недостающие тесты

Для каждого пути из «Основания», у которого после 1.1–1.2 нет теста с меткой,
написать тест — в Dart или в `rls_tests.sql`, где путь реализован. Пути, где
экран молчит при сбое, проверяются как построено: тест утверждает нынешнее
поведение. Как минимум:

- UC-15-P-03 — сбой связи при загрузке задачи: сообщение об ошибке и
  «Повторить»;
- UC-17-P-01 — пока среда в состоянии загрузки, строка «Загружаю Python — это
  разовая загрузка, потерпите», «Стоп» недоступна, «Запустить» доступна;
- UC-17-P-04 — исход `timedOut`: строка «Не уложилось в отведённое время» и
  текст ошибок результата в консоли;
- UC-19-P-02 — задача без эталонного ответа: любой ответ неверен, попытка
  записана (`rls_tests.sql`);
- UC-19-P-05 — неопубликованная задача: `[task_not_found]`, попытки нет
  (`rls_tests.sql`);
- UC-19-P-06 — сбой связи при отправке: текст сбоя под кнопкой, вердикта нет;
- UC-20-P-03 — «Не сейчас»: блок «Задача решена!» скрыт, публикация не
  вызвана;
- UC-20-P-04 — публикация не прошла: сообщения нет, блок скрыт, переключатель
  прежний;
- UC-21-P-02 — «Попыток пока не было»;
- UC-21-P-03 — сбой загрузки попыток: списка и сообщения нет;
- UC-22-P-04 — сбой загрузки решений: индикатор загрузки, сообщения нет;
- UC-24-P-01 — прямое удаление строки `submissions` — отказ.

Каждая новая проверка — с меткой, и она не холостая: если временно перевернуть
ожидание, проверка падает. Показать это в сдаче и вернуть как было. Путь,
который тестом не проверить, — в сдачу с причиной.

### 1.4. Метки в коде и комментарии

- `UC-n` — у кода, который реализует UC среза в клиенте, по таблице «Где
  реализованы UC в клиенте»; в `web/pyodide_worker.js` — `UC-17` в комментарии
  в начале файла.
- `COMP-n` — у классов виджетов, по таблице «Компоненты ↔ виджеты».
- В doc-комментариях `TaskScreen` и `EditorPanel` заменить устаревшие фразы
  тем, что эти классы делают сейчас.

Только комментарии: код не меняется.

### Проверки части 1

```bash
FL=~/fvm/versions/3.41.0/bin/flutter; DA=~/fvm/versions/3.41.0/bin/dart
$FL pub get
$FL gen-l10n && $DA run build_runner build --delete-conflicting-outputs
$FL analyze --fatal-infos --fatal-warnings      # 0 замечаний
$DA run custom_lint                             # 0 замечаний
$FL test                                        # все, не меньше 291 плюс новые
find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' \
  -print0 | xargs -0 $DA format --output=none --set-exit-if-changed
bash supabase/tests/run_local.sh                # RLS OK
python3 -m sdlc_tool views && python3 -m sdlc_tool check   # 0 ошибок
```

### СТОП 1

Сдача (черновик) и коротко в чат: что сделано, выводы проверок дословно,
таблица «путь → тесты с его меткой» и пути без тестов с причиной. Спросить
вопросом с вариантами, коммитить ли. Без ответа «да» дальше не идти.

Стоп-условия — остановиться и доложить, ничего не чиня:
- тест обнаруживает, что код ведёт себя не так, как написано в пути UC;
- путь нельзя проверить без изменения кода продукта.

## Часть 3. Git (только после подтверждения)

Все коммиты — в ветку `task/TASK-4`. Перед каждым коммитом —
`python3 -m sdlc_tool views` и `python3 -m sdlc_tool check` (0 ошибок).

1. **Коммит работы.** Сообщение на русском, в стиле истории. В него идут
   изменённые и новые тесты, комментарии в `lib/` и `web/pyodide_worker.js`,
   тестовые помощники, если менялись, и пересобранные производные файлы;
   сдача — нет. Файлы добавлять по именам: `git add -A` и `git add .` не
   использовать. Перед коммитом проверить `git status`: в индексе нет
   `reference/`, `supabase/seed/local/`, `supabase/.env.local`, `*.g.dart`,
   `lib/l10n/gen/`.
2. **Коммит — в сдачу**, раздел «Коммит работы».
3. **Отдельным коммитом — сдача** и пересобранные производные файлы, сообщение
   «Сдача TASK-4: RESULT-TASK-4-01, коммит <короткий хэш>». Отдельного
   подтверждения этот коммит не требует: он входит в уже подтверждённый.

Ничего не пушить.

## Самопроверка перед сдачей

Перед СТОПом 1 пройти самому:

- каждый пункт «Приёмки» ниже, кроме прогона `run`, — своей командой, с
  выводом в сдачу;
- сдача по составу `sdlc/5-results/AGENTS.md`, «нет» написано явно, где нечего
  сказать; в «Выполнено» — таблица «путь → тесты с его меткой»;
- в сдаче и в `git diff` нет ответов задач, эталонов и значений переменных
  окружения.

## Чего не делать

- Не менять поведение кода: в `lib/` и `web/` — только комментарии.
- Не менять строки l10n и тексты экранов.
- Не редактировать `supabase/migrations/`.
- Не переименовывать и не переносить файлы и классы.
- Не метить тесты справки к задаче.
- Не чинить найденное вне задания, в том числе находки прохода 5: записать в
  сдачу, раздел «Найдено вне задания».
- Не менять в `sdlc/` ничего, кроме своей сдачи и производных файлов.
- Не работать в основной копии `~/projects/yege_wars` и не трогать `main`.
- Не трогать `reference/`.
- Не коммитить без подтверждения.

## Приёмка

Постановщик проверит сам:

1. Полный набор проверок Dart зелёный, тестов не меньше 291 плюс новые;
   `run_local.sh` — `RLS OK` вместе с новыми проверками; новые проверки не
   холостые.
2. `git diff main...task/TASK-4` — изменены только тесты и тестовые
   помощники, комментарии в `lib/` и `web/pyodide_worker.js`,
   `supabase/tests/` и в `sdlc/` — сдача и производные файлы;
   `supabase/migrations/` не тронут; в `lib/` нет изменённых строк, кроме
   комментариев.
3. `python3 -m sdlc_tool check` — 0 ошибок; предупреждений, кроме 6 о записях
   TASK-1 и RESULT-TASK-1-01, нет.
4. `python3 -m sdlc_tool run` в worktree: на сводке у каждого из 33 путей
   вердикт `PASS`, кроме путей, перечисленных в сдаче с причиной; BT-8…BT-12
   закрыты, если таких путей нет.
5. Индексы: «Где реализован» — не «не покрыто» у UC-14…UC-22 и
   COMP-5…COMP-12.
6. Doc-комментарии `TaskScreen` и `EditorPanel` не обещают того, что уже
   сделано.
7. Сдача по составу `sdlc/5-results/AGENTS.md`; хэш в «Коммите работы»
   совпадает с `git log`.
