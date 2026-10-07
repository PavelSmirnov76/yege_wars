# Отчёт: ответ по формату и справка по темам на странице задачи

Задание — [PROMPT_CLIENT_ANSWERS.md](PROMPT_CLIENT_ANSWERS.md).

## 1. Состояние

2026-10-07: пункты 1–7 задания сделаны, полный набор проверок зелёный,
запросы клиента проверены на боевой (только чтение). Схема БД, миграции,
боевая база и `normalize_answer` не менялись. Закоммичено по
подтверждению пользователя.

- **Формат ответа** — `enum AnswerFormat` в domain `tasks`,
  `TaskDetail.answerFormat` этого типа; строковые значения — только
  в перечислении.
- **«Взять из вывода»** — `AnswerRules.fromOutput` в domain
  `submissions`: `multi` — все непустые строки через пробел, остальные —
  последняя непустая строка.
- **Подсказка под полем ответа** зависит от формата (4 строки в
  `app_ru.arb`), общая удалена.
- **Ответ без пробельных краёв** — обрезает `SubmitAnswerUseCase`.
- **Справка** — статьи по темам (`task_articles` + `reference_articles`
  двумя запросами) плюс ручные связи, слияние — `TaskHelpRules.merge`
  в domain `tasks`.
- `docs/STATE.md` — раздел «Ответ по формату и справка по темам», правки
  в «Чего ещё нет».

## 2. Журнал решений

| Дата | Вопрос | Варианты | Ответ пользователя |
|---|---|---|---|
| 2026-10-07 | Что делать с 8 опубликованными табличными задачами номера 25 (вопрос постановщика) | доработать клиент / снять с публикации / оставить | Задачи остаются опубликованными, клиент дорабатывается |
| 2026-10-07 | Коммитить ли работу (на СТОПе) | да / нет | Да, коммит |

Других вопросов пользователю по ходу работы не было.

## 3. Изменённые файлы

Новые:

- `lib/features/tasks/domain/entities/answer_format.dart` — `AnswerFormat`.
- `lib/features/tasks/domain/entities/theme_article.dart` — статья по теме
  задачи (`themeOrder`, `relevance`).
- `lib/features/tasks/domain/task_help_rules.dart` — `TaskHelpRules.merge`.
- `lib/features/submissions/domain/answer_rules.dart` —
  `AnswerRules.fromOutput`.
- `lib/features/submissions/presentation/answer_format_hint.dart` —
  `answerFormatHint(l10n, format)`.
- `test/features/submissions/answer_rules_test.dart`,
  `test/features/tasks/domain/task_help_rules_test.dart`.
- `docs/CLIENT_ANSWERS_REPORT.md` (этот файл).

Изменённые:

- `lib/core/network/supabase_schema.dart` — `SupabaseTables.taskArticles`,
  `TaskArticleColumns`, `ArticleColumns.id`.
- `lib/core/python_runtime/run_result.dart` — удалён `lastLine`.
- `lib/features/tasks/domain/entities/task_detail.dart` — `answerFormat`
  типа `AnswerFormat`.
- `lib/features/tasks/data/datasources/tasks_remote_data_source.dart`,
  `supabase_tasks_remote_data_source.dart` — `fetchThemeArticles`,
  `fetchArticles`; у ручных связей порядок `sort_order` по возрастанию.
- `lib/features/tasks/data/dto/task_dto.dart` — `AnswerFormat.fromValue`,
  `toArticleBrief`, `toThemeArticles`.
- `lib/features/tasks/data/repositories/tasks_repository_impl.dart` —
  третий параллельный запрос, второй шаг за статьями, слияние.
- `lib/features/submissions/domain/use_cases/submit_answer_use_case.dart` —
  обрезка краёв.
- `lib/features/submissions/presentation/widgets/submit_panel.dart` —
  правило ответа и подсказка по формату.
- `lib/l10n/app_ru.arb` — `submitHintSingle/Pair/Multi/String` вместо
  `submitAnswerHint`.
- Тесты: `test/features/editor/editor_test.dart`,
  `test/features/submissions/submissions_test.dart`,
  `test/features/submissions/submit_panel_test.dart`,
  `test/features/tasks/data/task_dto_test.dart`,
  `test/features/tasks/data/tasks_repository_impl_test.dart`,
  `test/features/tasks/presentation/task_screen_test.dart`,
  `test/helpers/fake_tasks_repository.dart`, `test/helpers/pump_app.dart`.
- `docs/STATE.md`.

## 4. Проверки

Полный набор из `CLAUDE.md`, 2026-10-07, выводы дословно:

```text
$ flutter gen-l10n
Because l10n.yaml exists, the options defined there will be used instead.
To use the command line arguments, delete the l10n.yaml file in the Flutter project.

$ dart run build_runner build --delete-conflicting-outputs
  Built with build_runner/aot in 4s; wrote 8 outputs.

$ flutter analyze --fatal-infos --fatal-warnings
Analyzing yege_wars...
No issues found! (ran in 2.7s)

$ dart run custom_lint
Analyzing...

No issues found!

$ flutter test
00:08 +267: All tests passed!

$ find lib test ... | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 186 files (0 changed) in 0.17 seconds.
exit=0
```

Тестов 267 (было 238): +30 новых, один тест `lastLine` заменён (см.
раздел 5). Новое: правило ответа и разбор формата (8), обрезка ответа (2),
слияние справки (8), DTO (4), репозиторий (2), виджет страницы задачи —
статья по теме без ручных связей (1), виджеты панели отправки (5).

### Запросы к боевой (только чтение)

Как проверялось: временный тест `test/zz_prod_probe_test.dart` (удалён
после прогона, в коммит не идёт) собирает `SupabaseClient` с токеном
сервисного аккаунта из `tools/content_client.py` (`ContentClient().token`,
логин `CONTENT_API_LOGIN`) и HTTP-клиентом, который пропускает только GET
и печатает путь и запрос без хоста и заголовков. Через него вызывается
настоящий `TasksRepositoryImpl(SupabaseTasksRemoteDataSource(client))
.getTask(slug)` — те же запросы и то же слияние, что в приложении.
Значения переменных окружения не выводились.

```text
GET /rest/v1/tasks_public?select=id,slug,ege_number,title,difficulty,tags,statement_md,answer_format,source&slug=eq.fipi-9c9ef1 -> 200
GET /rest/v1/task_files?select=filename,content,size_bytes&task_id=eq.1b5bacb0-d75a-bf28-4c69-471d7dc7f817&order=sort_order.desc.nullslast -> 200
GET /rest/v1/task_articles?select=article_id,sort_order&task_id=eq.1b5bacb0-d75a-bf28-4c69-471d7dc7f817&order=sort_order.asc.nullslast -> 200
GET /rest/v1/task_references?select=relevance,sort_order,reference_articles(slug,title,summary,level,reading_minutes,ege_numbers,tags)&task_id=eq.1b5bacb0-d75a-bf28-4c69-471d7dc7f817&order=sort_order.asc.nullslast -> 200
GET /rest/v1/reference_articles?select=id,slug,title,summary,level,reading_minutes,ege_numbers,tags&id=in.("f90a1ec3-ada1-447e-a9c6-e9a177028256","e5e2e2ee-ba84-4e8c-99c0-6d901ff01978","f4f421c9-1891-4962-8d80-da2cb7b5f369","90467c7f-7c62-48cf-ba3f-d03108960059") -> 200
fipi-9c9ef1: answerFormat=multi
  kes-3-2: primary
  kes-3-3: related
  kes-3-4: related
  kes-3-5: related
GET /rest/v1/tasks_public?select=id,slug,ege_number,title,difficulty,tags,statement_md,answer_format,source&slug=eq.e24-longest-run -> 200
GET /rest/v1/task_articles?select=article_id,sort_order&task_id=eq.52fa5be5-5dba-4d2b-b77c-a9c3bcf381c7&order=sort_order.asc.nullslast -> 200
GET /rest/v1/task_references?select=relevance,sort_order,reference_articles(slug,title,summary,level,reading_minutes,ege_numbers,tags)&task_id=eq.52fa5be5-5dba-4d2b-b77c-a9c3bcf381c7&order=sort_order.asc.nullslast -> 200
GET /rest/v1/task_files?select=filename,content,size_bytes&task_id=eq.52fa5be5-5dba-4d2b-b77c-a9c3bcf381c7&order=sort_order.desc.nullslast -> 200
GET /rest/v1/reference_articles?select=id,slug,title,summary,level,reading_minutes,ege_numbers,tags&id=in.("1cf36acd-0edd-4422-8c50-82a5df0a8417") -> 200
e24-longest-run: answerFormat=single
  kes-3-9: primary
```

Тот же код по всем опубликованным задачам (без печати запросов):

```text
задач: 140, ровно одна главная и она первая: 140, с дублями: 0, статей на задачу: {1: 37, 2: 17, 3: 58, 5: 13, 10: 2, 4: 12, 11: 1}
00:53 +1: All tests passed!
```

Разведка до начала работы (GET под тем же аккаунтом): `task_articles`
у 140 опубликованных — 389 строк, у каждой задачи есть строка с
`sort_order = 0`, основной темы `none` нет ни у одной; `task_references` —
0 строк. Форматы опубликованных: `string` 107, `single` 25, `multi` 8
(все — номер 25).

## 5. Отступления от задания и найдено вне задания

### Отступления

- **`RunResult.lastLine` удалён.** Правило «последняя непустая строка»
  переехало в `AnswerRules.fromOutput`, чтобы не держать две реализации.
  Тест `editor_test.dart` «ответом считается последняя непустая строка
  вывода» и «у пустого вывода ответа нет» заменены одним тестом на
  `isSuccess`; их случаи проверяются в `answer_rules_test.dart`.
- **Неизвестный формат ответа читается как `string`** (раньше пустое
  значение читалось как `single`). Задание этого не задавало; подсказка
  `string` верна для любого ответа, а кнопка берёт последнюю строку, как
  и раньше.
- **Подсказка — `helperText` под полем**, а не `hintText` внутри него:
  задание говорит «под полем», а подсказка `multi` в узкое поле не
  помещается. Видна всегда, а не только пока поле пустое.
- **Запрос ручных связей:** убран порядок по `relevance` (главные первыми
  ставит слияние), `sort_order` — по возрастанию. Раньше из-за умолчания
  SDK оба шли по убыванию (см. ниже).
- **Проверка на боевой — кодом клиента**, а не GET-запросами, собранными
  вручную: так запросы гарантированно те же. Все запросы — GET, другие
  методы клиент проверки отклонял. Дополнительно прогнаны все 140
  опубликованных задач.
- **`pumpApp(tasks:)`** принимает любой `TasksRepository`, а не только
  `FakeTasksRepository`: виджет-тест справки идёт через настоящий
  `TasksRepositoryImpl` поверх заглушки datasource.
- **`STATE.md`, «Чего ещё нет»:** кроме двух предписанных правок
  в пункте про `normalize_answer` заменена фраза «Клиент отправляет ответ
  как есть» — она стала неверной. Добавлен пункт про порядок сортировки
  (ниже).

### Найдено вне задания

- **`order()` в `postgrest` 2.9.1 по умолчанию сортирует по убыванию**
  (`ascending = false`, проверено по исходнику пакета и по запросам
  клиента: `order=sort_order.desc.nullslast`). Затронуты запросы, которые
  этого не учитывают:
  - каталог — `order=ege_number.desc.nullslast,title.desc.nullslast`:
    на боевой каталог начинается с номера 26 и заканчивается номером 2;
  - файлы задачи — по `sort_order` в обратном порядке;
  - список статей справочника — по `level` и `title` по убыванию.
  Не исправлялось: вне задания («не переделывать экраны сверх
  описанного»). Записано в `STATE.md`, «Чего ещё нет».
- Проверка на боевой шла под сервисным аккаунтом (роль `admin`). Ученику
  статьи видны по RLS только опубликованные; все 45 статей банка
  опубликованы, но под учётной записью ученика запросы не проверялись —
  её нет (регистрация закрыта подтверждением почты).
