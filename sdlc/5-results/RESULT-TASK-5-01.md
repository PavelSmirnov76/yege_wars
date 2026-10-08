# RESULT-TASK-5-01: Метки среза «справочник» и недостающие тесты

## Задание

[TASK-5](../4-tasks/TASK-5-LABELS-REFERENCE.md).

## Коммит работы

`ca35839` — «TASK-5: метки среза «справочник» и недостающие тесты»,
ветка `task/TASK-5`, после «да» владельца на СТОПе 1 (Обсуждение, п. 1).
Индексы в этом коммите собраны без сдачи; сдача и индексы с ней — отдельным
коммитом.

```
ca35839913b1b506773f72e8170925be0c8e8eec
TASK-5: метки среза «справочник» и недостающие тесты

 lib/core/markdown/app_markdown.dart                |   2 +
 lib/core/markdown/wiki_link_syntax.dart            |   2 +
 .../supabase_reference_remote_data_source.dart     |   2 +
 .../repositories/reference_repository_impl.dart    |   2 +
 .../use_cases/get_article_titles_use_case.dart     |   2 +
 .../domain/use_cases/get_article_use_case.dart     |   2 +
 .../domain/use_cases/list_articles_use_case.dart   |   2 +
 .../controllers/reference_controllers.dart         |  10 ++
 .../presentation/screens/article_screen.dart       |   2 +
 .../presentation/screens/reference_screen.dart     |   2 +
 .../presentation/widgets/article_card.dart         |   2 +
 .../presentation/widgets/article_filters_bar.dart  |   2 +
 .../presentation/widgets/article_meta.dart         |   2 +
 .../supabase_tasks_remote_data_source.dart         |   2 +-
 .../data/repositories/tasks_repository_impl.dart   |   2 +-
 .../tasks/domain/entities/theme_article.dart       |   2 +
 lib/features/tasks/domain/task_help_rules.dart     |   2 +
 .../tasks/presentation/screens/task_screen.dart    |   2 +-
 .../presentation/widgets/task_help_panel.dart      |   2 +
 sdlc/2-specs/use-cases/INDEX.md                    |   8 +-
 sdlc/3-design/design-system/INDEX.md               |   6 +-
 supabase/tests/rls_tests.sql                       |   3 +
 test/core/markdown/app_markdown_test.dart          |  12 +-
 test/core/markdown/wiki_link_syntax_test.dart      |   5 +-
 .../data/reference_repository_impl_test.dart       |   6 +-
 ...supabase_reference_remote_data_source_test.dart |   3 +-
 .../reference/domain/article_filter_test.dart      |   6 +-
 .../presentation/article_screen_test.dart          | 144 ++++++++++++++-
 .../presentation/reference_screen_test.dart        | 200 ++++++++++++++++++++-
 .../tasks/data/tasks_repository_impl_test.dart     |   7 +-
 .../tasks/domain/task_help_rules_test.dart         |  19 +-
 .../tasks/presentation/task_screen_test.dart       |  34 +++-
 32 files changed, 448 insertions(+), 51 deletions(-)
```

## Выполнено

Worktree `~/projects/yege_wars-TASK-5`, ветка `task/TASK-5` на `742c576`.
Исходное состояние сверено 2026-10-09: `flutter test` —
`00:13 +300: All tests passed!`; `run_local.sh` — `RLS TESTS PASSED`,
`RLS OK`; `python3 -m sdlc_tool check` — `Итог: 0 ошибок, 7 предупреждений`.

### 1.1. Метки тестов Dart

Метка — в начале описания у 36 существующих тестов, тела не менялись.
Длинные описания разбиты на соседние литералы, чтобы `dart format` не сдвигал
тело; в диффе старых тестов — только строки заголовков.

| Файл | Метки |
|---|---|
| `reference_screen_test.dart` | UC-25-P-01 — «показывает список статей», «нажатие на карточку открывает статью»; UC-25-P-02 — «выбор уровня уходит в запрос»; UC-25-P-03 — «пустой справочник объясняет себя»; UC-25-P-04 — «ошибка списка показывается с кнопкой повтора» |
| `article_screen_test.dart` | UC-26-P-01 — «показывает заголовок, сведения и текст»; UC-26-P-02 — «ошибка загрузки показывается с повтором»; UC-28-P-01 — «заголовки статей передаются в разметку» |
| `reference_repository_impl_test.dart` | UC-25-P-02 — «фильтр передаётся в datasource без изменений»; UC-26-P-02 — «отсутствующая статья — понятная ошибка»; UC-28-P-01 — «собирает словарь «slug — заголовок»» |
| `supabase_reference_remote_data_source_test.dart` | UC-25-P-01 — «статьи идут по уровню, затем по названию — по возрастанию» |
| `article_filter_test.dart`, группа `ArticleFilterController` | UC-25-P-02 — все 3 |
| `app_markdown_test.dart` | UC-26-P-01 — «рисует заголовок, абзац и блок кода», «таблица и цитата не ломают разметку»; UC-28-P-01 — «нажатие на внутреннюю ссылку отдаёт slug»; UC-28-P-02 — «неизвестная ссылка остаётся текстом» |
| `wiki_link_syntax_test.dart` | UC-28-P-01 — «известный slug становится ссылкой с заголовком статьи»; UC-28-P-02 — «неизвестный slug остаётся обычным текстом» |
| `task_help_rules_test.dart` | UC-27-P-01 — 7; UC-27-P-02 — «нет ни тем, ни ручных связей — справка пустая» |
| `task_screen_test.dart` | к UC-15-P-01 добавлена UC-27-P-01 — «показывает условие и подсказку про справку», «на узком экране условие, справка и файлы — вкладки»; UC-27-P-01 — «без ручных связей справка показывает статью по теме», «из справки к задаче можно перейти в статью» |
| `tasks_repository_impl_test.dart` | к UC-15-P-01 добавлена UC-27-P-01 — «собирает условие, файлы и справку»; UC-27-P-01 — «справка по темам: статьи вторым запросом, ручные — следом»; UC-27-P-02 — «без тем со статьями второй запрос не уходит» |

Без метки в тестах среза:

- «пункт «Справочник» есть в навигации» — триггер UC-25, не путь;
- «внутри блока кода ссылка не создаётся», «внутри участка кода ссылка не
  создаётся» (`wiki_link_syntax_test.dart`) — в UC-28 это триггер («вне
  участков и блоков кода»), не путь;
- тесты устройства: `article_dto_test.dart` (5 — разбор DTO, 2 —
  `escapeSearch`, очистка строки поиска); в `reference_repository_impl_test.dart`
  — «возвращает карточки статей», «битая строка — ошибка базы данных»,
  «возвращает статью с текстом», «строки без нужных полей пропускаются»
  (разбор строк базы), «обрыв связи превращается в сетевую ошибку» (маппер
  ошибок); группа `ArticleFilter` (2 — `isEmpty` и `copyWith`); «slug
  узнаётся по адресу ссылки» (отдельная функция `slugOf`).

Почему метку получили тесты правил справки и рендерера разметки —
Обсуждение, пп. 3–4.

### 1.2. Метки RLS-тестов

Метка — строкой-комментарием `-- UC-n-P-nn: что проверяется` перед
проверкой, как в TASK-4:

| Раздел | Проверка | Метки |
|---|---|---|
| (н) | опубликованная статья `file-reading` ученику видна | UC-25-P-01, UC-26-P-01 |
| (н) | неопубликованная статья `draft-article` ученику не видна | UC-25-P-01, UC-26-P-02, UC-28-P-02 |
| (о) | `task_articles` отдаёт статью задачи по её теме | UC-27-P-01 |

Других проверок путей среза в `rls_tests.sql` нет. Без метки, как решено при
постановке: права, запись тем, служебная тема `none`, Content API в (н), (о),
(п), в том числе пересборка `task_references` при повторном
`admin_upsert_task` и права на `task_articles`.

### 1.3. Недостающие тесты

10 новых тестов Dart, все — минимум из перечня 1.3; путей без теста после
1.1–1.2 было два, UC-26-P-03 и UC-28-P-03. Пути с изъяном проверены как
построено. Тестов в `rls_tests.sql` не добавлено.

| Путь | Где | Что проверяет |
|---|---|---|
| [UC-25-P-02](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-02) | `reference_screen_test.dart` | «чипы номеров и тегов — из значений фильтров»: чипы отбора по порядку — три уровня, «№ 17», «№ 24», `files`, `regex`, `strings` — ровно номера и теги статей справочника |
| UC-25-P-02 | `reference_screen_test.dart` | «значения фильтров не загрузились — чипов номеров и тегов нет до конца сессии, а список работает»: при открытии нет связи; связь вернулась, пока Riverpod повторяет запрос списка, — список есть, чипы только уровня (после минуты фейкового времени); выбор уровня уходит в запрос; список снова упал, «Повторить» загрузил его — чипов номеров и тегов по-прежнему нет |
| UC-25-P-02 | `reference_screen_test.dart` | «строка поиска уходит в запрос через 300 мс после ввода»: через 299 мс запросов не прибавилось и строки в фильтре нет; через 300 мс — один новый запрос со строкой |
| UC-25-P-02 | `reference_screen_test.dart` | ««Сбросить фильтры» снимает все условия и строку поиска, а текст в поле остаётся»: без условий кнопки нет; после выбора уровня — есть; уровень, «№ 24», `regex` и строка «окно» уходят в запрос; после нажатия запрос — пустой фильтр, кнопки нет, в поле поиска — «окно» |
| [UC-25-P-03](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-03) | `reference_screen_test.dart` | «по заданным условиям статей нет»: пустой ответ и выбранный уровень — «По этим условиям ничего не нашлось», «В справочнике пока нет статей» нет |
| [UC-25-P-04](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-04) | `reference_screen_test.dart` | «сбой связи — индикатор, пока идут повторы, затем сообщение и «Повторить»» |
| [UC-26-P-03](../2-specs/use-cases/obsolete/UC-26-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-26-p-03) | `article_screen_test.dart` | «сбой связи — индикатор, пока идут повторы, затем сообщение и «Повторить»» |
| [UC-27-P-02](../2-specs/use-cases/UC-27-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md#uc-27-p-02) | `task_screen_test.dart` | «у задачи без статей справка пустая, подсказки над условием нет»: на вкладке «Условие» условие есть, подсказки «Не знаешь, с чего начать?…» нет; на вкладке «Справка» — «К этой задаче пока нет статей справочника» |
| [UC-28-P-02](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-02) | `article_screen_test.dart` | «словарь заголовков не загрузился — slug текстом до конца сессии»: в статье «Читай regex-basics дальше.», названия нет; связь вернулась — ни через минуту фейкового времени, ни в другой статье после ухода в каталог ссылка не появляется |
| [UC-28-P-03](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-03) | `article_screen_test.dart` | «обычная ссылка не открывается»: нажатие на `[документации](https://docs.python.org/3/)` — адрес страницы прежний, другая статья не запрошена, экран статьи на месте |

Состояние провайдера в момент проверок путей о сбое загрузки:

| Тест | Проверки | Состояние провайдера |
|---|---|---|
| UC-25-P-04 | первые — экран открыт пятью кадрами по 100 мс: индикатор в `ReferenceScreen`, сообщения и «Повторить» нет | `articlesProvider` — `AsyncLoading<List<ArticleBrief>>`, `error` — `NetworkFailure`, идут автоповторы; утверждается в тесте |
| UC-25-P-04 | вторые — после `pumpUntilRetriesEnd`: индикатора нет, текст сбоя и кнопка «Повторить» есть | `AsyncError<List<ArticleBrief>>`; утверждается в тесте |
| UC-26-P-03 | первые — так же, в `ArticleScreen` | `articleProvider(slug)` — `AsyncLoading<ReferenceArticle>`, `error` — `NetworkFailure`; утверждается в тесте |
| UC-26-P-03 | вторые — после `pumpUntilRetriesEnd` | `AsyncError<ReferenceArticle>`; утверждается в тесте |
| UC-25-P-02, значения фильтров | все проверки чипов | `articleFacetsProvider` — `AsyncData` с пустыми значениями: при ошибке он возвращает `const ArticleFacets()`, не бросает, автоповторов нет (по коду; в тесте не утверждается — его нарушение ловит порча 4). `articlesProvider` при проверках — `AsyncData` |
| UC-28-P-02 | все проверки текста | `articleTitlesProvider` — `AsyncData` с пустым словарём: при ошибке возвращает `{}` (по коду; в тесте не утверждается — нарушение ловит порча 19). `articleProvider(slug)` — `AsyncData` |

Тестовые помощники — только локальные функции в файлах тестов:
`openReference` и `openArticle` получили параметр `settle` (по умолчанию
прежнее поведение; без него экран открывается пятью кадрами по 100 мс),
`chipLabels` и `levelChips` (`reference_screen_test.dart`), `tapLink`
(`article_screen_test.dart`). `test/helpers/` и `FakeReferenceRepository` не
менялись (Обсуждение, п. 7).

Пути, которые тестом не проверить: нет.

### 1.4. Метки в коде

Только doc-комментарии; код не менялся. Метки — строго по таблицам задания
«Где реализованы UC в клиенте» и «Компоненты ↔ виджеты».

| Где | Метка |
|---|---|
| `ReferenceScreen`, `ArticleFiltersBar`, `ArticleFilterController`, `articles`, `articleFacets` (`reference_controllers.dart`), `ListArticlesUseCase` | `UC-25` |
| `article` (`reference_controllers.dart`), `GetArticleUseCase` | `UC-26` |
| `ArticleScreen` | `UC-26`, `UC-28` |
| `TaskHelpPanel`, `TaskHelpRules`, `ThemeArticle` | `UC-27` |
| `TasksRepositoryImpl`, `SupabaseTasksRemoteDataSource` | было `UC-14`, стало `UC-14`, `UC-27` |
| `TaskScreen` | было `UC-15`, стало `UC-15`, `UC-27`, `UC-28` |
| `WikiLinkSyntax`, `articleTitles` (`reference_controllers.dart`), `GetArticleTitlesUseCase` | `UC-28` |
| `ReferenceRepositoryImpl`, `SupabaseReferenceRemoteDataSource` | `UC-25`, `UC-26`, `UC-28` |
| `AppMarkdown` | `UC-28`, `COMP-15` |
| `ArticleMeta` | `COMP-13` |
| `ArticleCard` | `COMP-14` |

Формулировки — `/// Реализует UC-n.` и `/// Воплощает COMP-n.` отдельным
абзацем в конце doc-комментария; у `AppMarkdown` — одной фразой «Реализует
UC-28, воплощает COMP-15.», как у `AppShell`. В уже размеченных классах
номер добавлен в ту же фразу: «Реализует UC-14 и UC-27.», «Реализует UC-15,
UC-27 и UC-28.».

### Путь → тесты с его меткой

Таблицу собрали разборщики `sdlc_tool run` (`parse_flutter_events`,
`flutter_rows`, `sql_rows`) по JSON-отчёту итогового `flutter test` и по
`rls_tests.sql`. Все 12 путей среза — с тестами; 52 строки, Dart — `PASS`,
SQL — вердикт `rls`. Сам `run` не запускался.

| Путь | Тесты с меткой |
|---|---|
| [UC-25-P-01](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-01) | `test/features/reference/data/supabase_reference_remote_data_source_test.dart`: `UC-25-P-01: статьи идут по уровню, затем по названию — по возрастанию`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-01: показывает список статей`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-01: нажатие на карточку открывает статью`<br>`supabase/tests/rls_tests.sql`: `UC-25-P-01, UC-26-P-01: опубликованная статья ученику видна`<br>`supabase/tests/rls_tests.sql`: `UC-25-P-01, UC-26-P-02, UC-28-P-02: неопубликованная статья ученику не видна` |
| [UC-25-P-02](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-02) | `test/features/reference/data/reference_repository_impl_test.dart`: `listArticles UC-25-P-02: фильтр передаётся в datasource без изменений`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-25-P-02: повторный выбор снимает условие`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-25-P-02: выбор другого значения заменяет прежнее`<br>`test/features/reference/domain/article_filter_test.dart`: `ArticleFilterController UC-25-P-02: сброс очищает все условия`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-02: выбор уровня уходит в запрос`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-02: чипы номеров и тегов — из значений фильтров`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-02: значения фильтров не загрузились — чипов номеров и тегов нет до конца сессии, а список работает`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-02: строка поиска уходит в запрос через 300 мс после ввода`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-02: «Сбросить фильтры» снимает все условия и строку поиска, а текст в поле остаётся` |
| [UC-25-P-03](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-03) | `test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-03: пустой справочник объясняет себя`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-03: по заданным условиям статей нет` |
| [UC-25-P-04](../2-specs/use-cases/obsolete/UC-25-ACTOR-4-EVT-20-ENT-12-ARTICLES-LISTED-IN-REFERENCE.md#uc-25-p-04) | `test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-04: ошибка списка показывается с кнопкой повтора`<br>`test/features/reference/presentation/reference_screen_test.dart`: `UC-25-P-04: сбой связи — индикатор, пока идут повторы, затем сообщение и «Повторить»` |
| [UC-26-P-01](../2-specs/use-cases/obsolete/UC-26-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-26-p-01) | `test/core/markdown/app_markdown_test.dart`: `UC-26-P-01: рисует заголовок, абзац и блок кода`<br>`test/core/markdown/app_markdown_test.dart`: `UC-26-P-01: таблица и цитата не ломают разметку`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-26-P-01: показывает заголовок, сведения и текст`<br>`supabase/tests/rls_tests.sql`: `UC-25-P-01, UC-26-P-01: опубликованная статья ученику видна` |
| [UC-26-P-02](../2-specs/use-cases/obsolete/UC-26-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-26-p-02) | `test/features/reference/data/reference_repository_impl_test.dart`: `getArticle UC-26-P-02: отсутствующая статья — понятная ошибка`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-26-P-02: ошибка загрузки показывается с повтором`<br>`supabase/tests/rls_tests.sql`: `UC-25-P-01, UC-26-P-02, UC-28-P-02: неопубликованная статья ученику не видна` |
| [UC-26-P-03](../2-specs/use-cases/obsolete/UC-26-ACTOR-4-EVT-21-ENT-12-ARTICLE-SHOWN-IN-REFERENCE.md#uc-26-p-03) | `test/features/reference/presentation/article_screen_test.dart`: `UC-26-P-03: сбой связи — индикатор, пока идут повторы, затем сообщение и «Повторить»` |
| [UC-27-P-01](../2-specs/use-cases/UC-27-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md#uc-27-p-01) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `getTask UC-15-P-01, UC-27-P-01: собирает условие, файлы и справку`<br>`test/features/tasks/data/tasks_repository_impl_test.dart`: `getTask UC-27-P-01: справка по темам: статьи вторым запросом, ручные — следом`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: статья основной темы главная, других тем — сопутствующая`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: без ручных связей справка состоит из статей по темам`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: без тем справка — ручные связи`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: главные первыми, внутри — по порядку темы, затем ручные`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: статья по теме и вручную — один раз, с более сильной значимостью и на месте темы`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: повтор ручной связи не дублирует статью`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-01: статья двух тем — один раз, по ранней теме`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-01, UC-27-P-01: показывает условие и подсказку про справку`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-15-P-01, UC-27-P-01: на узком экране условие, справка и файлы — вкладки`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-27-P-01: без ручных связей справка показывает статью по теме`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-27-P-01: из справки к задаче можно перейти в статью`<br>`supabase/tests/rls_tests.sql`: `UC-27-P-01: task_articles отдаёт статью задачи по её теме` |
| [UC-27-P-02](../2-specs/use-cases/UC-27-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md#uc-27-p-02) | `test/features/tasks/data/tasks_repository_impl_test.dart`: `getTask UC-27-P-02: без тем со статьями второй запрос не уходит`<br>`test/features/tasks/domain/task_help_rules_test.dart`: `TaskHelpRules.merge UC-27-P-02: нет ни тем, ни ручных связей — справка пустая`<br>`test/features/tasks/presentation/task_screen_test.dart`: `UC-27-P-02: у задачи без статей справка пустая, подсказки над условием нет` |
| [UC-28-P-01](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-01) | `test/core/markdown/wiki_link_syntax_test.dart`: `WikiLinkSyntax UC-28-P-01: известный slug становится ссылкой с заголовком статьи`<br>`test/core/markdown/app_markdown_test.dart`: `UC-28-P-01: нажатие на внутреннюю ссылку отдаёт slug`<br>`test/features/reference/data/reference_repository_impl_test.dart`: `articleTitles UC-28-P-01: собирает словарь «slug — заголовок»`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-28-P-01: заголовки статей передаются в разметку` |
| [UC-28-P-02](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-02) | `test/core/markdown/wiki_link_syntax_test.dart`: `WikiLinkSyntax UC-28-P-02: неизвестный slug остаётся обычным текстом`<br>`test/core/markdown/app_markdown_test.dart`: `UC-28-P-02: неизвестная ссылка остаётся текстом`<br>`test/features/reference/presentation/article_screen_test.dart`: `UC-28-P-02: словарь заголовков не загрузился — slug текстом до конца сессии`<br>`supabase/tests/rls_tests.sql`: `UC-25-P-01, UC-26-P-02, UC-28-P-02: неопубликованная статья ученику не видна` |
| [UC-28-P-03](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-03) | `test/features/reference/presentation/article_screen_test.dart`: `UC-28-P-03: обычная ссылка не открывается` |

## Не выполнено

- `python3 -m sdlc_tool run` не запускался: по заданию его прогоняет
  постановщик при приёмке.
- Части путей с метками, которые тестами не проверены и не входят в перечень
  1.3, — без новых тестов, как решено при постановке; перечень — «Найдено вне
  задания», п. 1.

## Проверки

Итоговое состояние — рабочее дерево на СТОПе 1, 2026-10-09; вошло в
коммит `ca35839` без изменений:

- `flutter pub get`, `flutter gen-l10n`,
  `dart run build_runner build --delete-conflicting-outputs` — код 0;
  последняя строка: `Built with build_runner/aot in 0s; wrote 0 outputs.`
- `flutter analyze --fatal-infos --fatal-warnings`:
  `No issues found! (ran in 2.7s)`
- `dart run custom_lint`: `No issues found!`
- `flutter test`: `00:11 +310: All tests passed!` — 300 прежних и 10 новых
- `find lib test … | xargs -0 dart format --output=none --set-exit-if-changed`:
  `Formatted 190 files (0 changed) in 0.19 seconds.`, код 0
- `bash supabase/tests/run_local.sh`, строки размеченных проверок и конец:

```
NOTICE:  OK: (н) файлы и статьи видны ученику только для опубликованного контента
NOTICE:  OK: (о) task_articles отдаёт статью задачи по её теме
NOTICE:  RLS TESTS PASSED
RLS OK
```

- `python3 -m sdlc_tool views`, затем `python3 -m sdlc_tool check`:
  `Итог: 0 ошибок, 7 предупреждений` — те же 7, что в исходном состоянии:
  6 о ссылках TASK-1 и RESULT-TASK-1-01 на похороненные UC-11-P-01…UC-11-P-03
  и 1 — TASK-4 ссылается на похороненный FIG-12.
- `lib/`: добавлено 43 строки, удалено 3, все — `///` (40 — метки с пустой
  строкой-разделителем, 3 — замена фразы «Реализует …» в `TaskScreen`,
  `TasksRepositoryImpl`, `SupabaseTasksRemoteDataSource`); других изменённых
  строк нет. `supabase/migrations/`, `supabase/seed/`, `reference/`, `web/` не
  тронуты. В диффе значений окружения, ключей и адреса проекта нет.
- Индексы: «Где реализован» у UC-25 — 6 файлов, UC-26 — 5, UC-27 — 6,
  UC-28 — 8; COMP-13, COMP-14, COMP-15 — по 1.

Нехолостость новых проверок — порчей кода в `lib/`, по одной порче за запуск
`flutter test <файл> --plain-name <тест>`, файл возвращается после каждой.
Две порчи `@Riverpod(keepAlive: true)` → `@riverpod` прогонялись с
`build_runner` до и после. После всех порч `sha256` 8 задетых файлов `lib/`
совпали с исходными.

| № | Путь | Порча | Итог |
|---|---|---|---|
| 1 | UC-25-P-02 | `ArticleFiltersBar`: чипы номеров из `[...facets.egeNumbers, 27]` | код 1: `Which: at location [5] is '№ 27' instead of 'files'` / `reference_screen_test.dart:137` |
| 2 | UC-25-P-02 | `articleFacets`: `tags: const []` | код 1: `Actual: ['Базовый', 'Средний', 'Продвинутый', '№ 17', '№ 24']` / `reference_screen_test.dart:137` |
| 3 | UC-25-P-02 | «Повторить» в `ReferenceScreen` сбрасывает и `articleFacetsProvider` | код 1: `Expected: ['Базовый', 'Средний', 'Продвинутый']` / `reference_screen_test.dart:177` |
| 4 | UC-25-P-02 | `articleFacets` при ошибке бросает её — Riverpod повторяет | код 1: `Expected: ['Базовый', 'Средний', 'Продвинутый']` / `reference_screen_test.dart:161` |
| 5 | UC-25-P-02 | `articleFacets` без `keepAlive` | код 0, `All tests passed!` — порча эквивалентна, см. ниже |
| 6 | UC-25-P-02 | пауза поиска 100 мс | код 1: `Expected: <2>` / `Actual: <3>` / `reference_screen_test.dart:188` |
| 7 | UC-25-P-02 | пауза поиска 500 мс | код 1: `Expected: <3>` / `Actual: <2>` / `reference_screen_test.dart:194` |
| 8 | UC-25-P-02 | `reset()` оставляет строку поиска | код 1: `Expected: <Instance of 'ArticleFilter'>` / `reference_screen_test.dart:235` |
| 9 | UC-25-P-02 | `reset()` снимает только уровень и строку, номер и тег остаются | код 1: `Expected: <Instance of 'ArticleFilter'>` / `reference_screen_test.dart:235` |
| 10 | UC-25-P-02 | «Сбросить фильтры» видна всегда | код 1: `Expected: no matching candidates` / `Actual: _AncestorWidgetFinder:<Found 1 widget with type "TextButton"` / `reference_screen_test.dart:203` |
| 11 | UC-25-P-02 | `ReferenceScreen` очищает поле поиска, когда фильтр пуст | код 1: `Expected: 'окно'` / `Actual: ''` / `reference_screen_test.dart:237` |
| 12 | UC-25-P-03 | при условиях — «В справочнике пока нет статей» | код 1: `Found 0 widgets with text "По этим условиям ничего не нашлось"` / `reference_screen_test.dart:252` |
| 13 | UC-25-P-04 | `ReferenceScreen`: `AsyncLoading` с ошибкой показывает сообщение и «Повторить» | код 1: `Found 0 widgets with type "CircularProgressIndicator"` / `reference_screen_test.dart:270` |
| 14 | UC-25-P-04 | `ReferenceScreen`: в `AsyncError` — индикатор | код 1: `Found 1 widget with type "CircularProgressIndicator"` / `reference_screen_test.dart:281` |
| 15 | UC-26-P-03 | `ArticleScreen`: `AsyncLoading` с ошибкой показывает сообщение и «Повторить» | код 1: `Found 0 widgets with type "CircularProgressIndicator"` / `article_screen_test.dart:145` |
| 16 | UC-26-P-03 | `ArticleScreen`: в `AsyncError` — индикатор | код 1: `Found 1 widget with type "CircularProgressIndicator"` / `article_screen_test.dart:156` |
| 17 | UC-27-P-02 | `TaskScreen`: подсказка над условием всегда | код 1: `Found 1 widget with text "Не знаешь, с чего начать? Загляни в справку"` / `task_screen_test.dart:191` |
| 18 | UC-27-P-02 | `TaskHelpPanel`: без статей — пустой текст | код 1: `Found 0 widgets with text "К этой задаче пока нет статей справочника"` / `task_screen_test.dart:195` |
| 19 | UC-28-P-02 | `articleTitles` при ошибке бросает её — Riverpod повторяет | код 1: `Found 1 widget with text containing Регулярные выражения` / `article_screen_test.dart:187` |
| 20 | UC-28-P-02 | `articleTitles` без `keepAlive` | код 1: `Found 0 widgets with text containing Читай regex-basics` / `article_screen_test.dart:196` |
| 21 | UC-28-P-02 | `WikiLinkSyntax`: неизвестный slug — `[[slug]]` | код 1: `Found 0 widgets with text containing Читай regex-basics` / `article_screen_test.dart:176` |
| 22 | UC-28-P-03 | `AppMarkdown.onTapLink`: любая ссылка — `onArticleTap(slug ?? href ?? '')` | код 1: `Expected: '/reference/file-reading'` / `Actual: '/reference/https%3A%2F%2Fdocs.python.org%2F3%2F'` / `article_screen_test.dart:213` |
| 23 | UC-28-P-03 | `AppMarkdown.onTapLink`: обычная ссылка открывает пустую страницу через `Navigator.push` | код 1: `Found 0 widgets with type "ArticleScreen"` / `article_screen_test.dart:215` |

Каждая порча, кроме 5, падает с `Some tests failed.`. Порча 5 эквивалентна:
разделы приложения — ветки `StatefulShellRoute.indexedStack`
(`app_router.dart`), экран справочника после первого открытия живёт до конца
сессии и сам держит `articleFacetsProvider`; без `keepAlive` значения
фильтров тоже не перезапрашиваются, поведение не меняется. Шаг теста «уход
в каталог и возврат» её не различал и из теста убран (Обсуждение, п. 9).

## Применено к боевой

Нет.

## Обсуждение

До начала работы — нет.

По ходу:

1. 2026-10-09, СТОП 1. Вопрос: коммитить работу в `task/TASK-5`?
   Варианты: коммитить; не коммитить. Выбрано: **коммитить**.

Выбор исполнителя там, где задание его не предписывало:

2. Тесты слоя данных — по правилу TASK-4: метку получили тесты, которые
   проверяют утверждение пути (порядок списка в запросе, фильтр в
   datasource, «не найдена» у отсутствующей статьи, словарь заголовков,
   сборка справки, пустая справка без тем); без метки — разбор строк, маппер
   ошибок, очистка строки поиска.
3. Тесты `TaskHelpRules.merge` получили метки UC-27-P-01 и UC-27-P-02: правила
   слияния — текст пути UC-27-P-01, а «Исходное состояние» задания считает
   тест правила слияния частичной проверкой UC-27-P-02. В TASK-4 тесты
   `AnswerRules` остались без метки как тесты отдельной функции.
4. Тесты рендерера `AppMarkdown` «рисует заголовок, абзац и блок кода» и
   «таблица и цитата не ломают разметку» получили UC-26-P-01: путь
   перечисляет в тексте статьи заголовки, таблицы, цитаты, блоки кода, а текст
   статьи рисует этот компонент. Метку UC-15-P-01 (условие задачи) не ставил:
   это другой срез.
5. SQL-проверке «неопубликованная статья ученику не видна» дана и UC-28-P-02:
   словарь заголовков — выборка из той же `reference_articles` под теми же
   политиками («ученику она не видна»).
6. Метки в коде — только у перечисленных в таблицах задания; что ещё
   реализует пути без метки — «Найдено вне задания», п. 2.
7. «Значения фильтров не загрузились, а список есть» проверяется без правки
   `FakeReferenceRepository`: при открытии падают оба запроса, затем связь
   возвращается, пока Riverpod повторяет запрос списка. Список и значения
   фильтров идут одним методом `listArticles` с одним и тем же пустым
   фильтром; отвечать им по-разному по порядку вызова — значит привязать тест
   к порядку сборки виджетов.
8. Нажатие на обычную ссылку (UC-28-P-03) проверяется на экране статьи, а не
   на `AppMarkdown`: «никуда не ведёт» видно по адресу страницы. Текст статьи
   выделяемый, `tapOnText` подстроку в нём не находит, поэтому помощник
   `tapLink` находит `TextSpan` ссылки в `SelectableText` и вызывает его
   `TapGestureRecognizer` — тот же, что сработал бы от нажатия.
9. Из теста значений фильтров убран шаг «уход в каталог и возврат»: ни одна
   порча его не различала (порча 5, эквивалентная). В тесте словаря
   заголовков такой же шаг оставлен: его различает порча 20.

## Отступления от задания

Нет.

## Найдено вне задания

1. Части путей с метками, которые тестами не проверены (не входят в перечень
   1.3):
   - UC-25-P-01: в карточке — время чтения «N мин», до четырёх номеров «№ N»
     и «…», до трёх тегов; администратору база отдаёт и неопубликованные
     статьи — в `rls_tests.sql` проверки под администратором нет;
   - UC-25-P-02: поиск по части названия или описания и отбор по номеру,
     тегу и уровню в запросе к базе — `supabase_reference_remote_data_source_test.dart`
     проверяет только порядок; повторное нажатие чипа на экране (проверено на
     контроллере);
   - UC-25-P-04, UC-26-P-03: «около 40 секунд» — длительность повторов
     тесты не утверждают;
   - UC-26-P-01: название статьи в заголовке экрана, все теги, «…» у
     номеров, списки, подсветка Python; неопубликованная статья
     администратору;
   - UC-26-P-02: индикатор, пока идут повторы, — тест смотрит экран только
     после повторов (`pumpAndSettle`);
   - UC-27-P-01: «ученику неопубликованных статей в справке нет» — нет
     проверки `task_articles` и `task_references` с неопубликованной статьёй
     под учеником; сопутствующие свёрнуты; раскрытая карточка показывает
     уровень, время чтения, номера; без главной статьи подсказки нет;
   - UC-28-P-01: пока словарь грузится — slug текстом, когда пришёл —
     ссылка; ссылка в условии задачи и переход по ней;
   - UC-28-P-02, UC-28-P-03: в условии задачи — проверено только в статье;
     UC-28-P-03: «нарисована так же, как ссылка на статью».
2. Код, который реализует пути среза, но метки не получил — его нет в
   таблицах задания: `articleLevelLabel` (уровни в чипах и сведениях,
   UC-25, UC-26), `ArticleFilter` (`isEmpty` решает, видна ли «Сбросить
   фильтры» и какой текст у пустого списка, UC-25), `ArticleDto`,
   `TaskDto.toThemeArticles`, `TaskDto.toArticleLink` и
   `TaskDetail.primaryArticles` (подсказка над условием, UC-27), маршруты
   `/reference` и `/reference/:slug` в `app_router.dart` (триггеры UC-25 и
   UC-26).
3. Находки прохода 6 (`sdlc/0-vibes/raw/2026-10-08/as-built-reference.md`)
   не чинились. Новые тесты закрепляют построенное поведение находок 1–4:
   индикатор до конца повторов (UC-25-P-04, UC-26-P-03), текст в поле после
   «Сбросить фильтры», обычная ссылка не открывается, значения фильтров и
   словарь заголовков после ошибки не перезапрашиваются.
