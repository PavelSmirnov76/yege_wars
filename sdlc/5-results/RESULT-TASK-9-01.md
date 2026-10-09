# RESULT-TASK-9-01: Причёсывание интерфейса — акцент, отбор по разделам, вкладки задачи, выделение, карточки

## Задание

[TASK-9](../4-tasks/TASK-9-UI-POLISH.md).

## Коммит работы

`ab1b4d5` — «TASK-9: причёсывание интерфейса — акцент, отбор по разделам,
вкладки задачи, выделение, карточки», ветка `task/TASK-9`, после «да»
владельца на СТОПе 1 («Обсуждение», п. 11). Индексы в этом коммите собраны
без сдачи; сдача и индексы с ней — отдельным коммитом. Push не было.

```
ab1b4d5d683c9e7be4effc2b59fc660386605a81
TASK-9: причёсывание интерфейса — акцент, отбор по разделам, вкладки задачи, выделение, карточки

 lib/app/provider_retry.dart                        |   2 +-
 lib/app/theme/app_colors.dart                      |  17 +-
 lib/app/theme/app_theme.dart                       |   3 +
 lib/core/markdown/app_markdown.dart                |  18 +-
 lib/core/markdown/code_block.dart                  |   9 +-
 .../editor/presentation/widgets/editor_panel.dart  |  30 ++-
 .../supabase_reference_remote_data_source.dart     |   2 +-
 .../repositories/reference_repository_impl.dart    |   2 +-
 .../reference/domain/entities/article_facets.dart  |   9 +-
 .../domain/entities/codifier_section.dart          |  35 +++
 .../domain/use_cases/list_articles_use_case.dart   |   2 +-
 .../controllers/reference_controllers.dart         |  18 +-
 .../presentation/screens/article_screen.dart       |  62 ++---
 .../presentation/screens/reference_screen.dart     |   2 +-
 .../presentation/widgets/article_filters_bar.dart  |  18 +-
 .../widgets/codifier_section_label.dart            |  15 ++
 .../presentation/widgets/submit_panel.dart         |   8 +-
 .../supabase_tasks_remote_data_source.dart         |   2 +-
 .../data/repositories/tasks_repository_impl.dart   |   2 +-
 .../tasks/domain/entities/theme_article.dart       |   2 +-
 lib/features/tasks/domain/task_help_rules.dart     |   2 +-
 .../tasks/presentation/screens/task_screen.dart    | 289 ++++++++++++---------
 .../presentation/widgets/task_help_panel.dart      |  50 +---
 lib/l10n/app_ru.arb                                |   6 +
 sdlc/2-specs/use-cases/INDEX.md                    |   6 +-
 sdlc/3-design/design-system/INDEX.md               |   8 +-
 supabase/tests/rls_tests.sql                       |   6 +-
 test/app/theme/card_ink_test.dart                  | 129 +++++++++
 test/core/markdown/app_markdown_test.dart          |  16 +-
 test/features/editor/editor_panel_test.dart        |  31 ++-
 .../data/reference_repository_impl_test.dart       |   2 +-
 ...supabase_reference_remote_data_source_test.dart |   2 +-
 .../reference/domain/article_filter_test.dart      |   6 +-
 .../reference/domain/codifier_section_test.dart    |  36 +++
 .../presentation/article_screen_test.dart          |  89 +++++--
 .../presentation/reference_screen_test.dart        |  78 ++++--
 .../tasks/data/tasks_repository_impl_test.dart     |   6 +-
 .../tasks/domain/task_help_rules_test.dart         |  16 +-
 .../tasks/presentation/task_screen_test.dart       | 254 +++++++++++++++++-
 test/helpers/fake_reference_repository.dart        |   6 +-
 test/helpers/selection.dart                        |  44 ++++
 41 files changed, 992 insertions(+), 348 deletions(-)
```

## Выполнено

### 1.1. Акцент — TOKEN-7

- `lib/app/theme/app_colors.dart`: `accent` `#E8865A`, `accentHover`
  `#F0A07E`, `onAccent` `#2A1006`; dartdoc — «приглушённый оранжевый»,
  контраст `onAccent` ~6.8:1; метка `TOKEN-7`. Остальные цвета не менялись,
  `app_theme.dart` ради цвета не правился («Обсуждение», п. 1). Вслед за
  константами меняются `onError` схемы (он равен `onAccent`) и фон тональных
  кнопок `secondary` = `accentHover` («Опубликовать решение», «Скачать»).

### 1.2. Справочник — UC-39-P-02, FIG-21

- Новый `lib/features/reference/domain/entities/codifier_section.dart`:
  enum `CodifierSection` (`digitalLiteracy` `'1'`, `theory` `'2'`,
  `algorithms` `'3'`, `technologies` `'4'`), поле `tag`,
  `static CodifierSection? fromTag(String)` — тема `1.1` и любой другой тег —
  `null`; метка UC-39.
- Новый `lib/features/reference/presentation/widgets/codifier_section_label.dart`:
  `codifierSectionLabel(section, l10n)` — switch на
  `referenceSection1`…`referenceSection4`; метка UC-39.
- `article_facets.dart`: `ArticleFacets.tags` → `sections`
  (`List<CodifierSection>`).
- `reference_controllers.dart`: `articleFacetsProvider` по-прежнему считает
  значения по всему справочнику один раз за сессию; разделы — только те, что
  `fromTag` нашёл в тегах статей, по порядку номера. При сбое — пустые
  значения, как было.
- `article_filters_bar.dart`: вместо строки чипов тегов — чипы разделов с
  подписью `codifierSectionLabel`; выбор — `filter.tag == section.tag`,
  нажатие — `toggleTag(section.tag)`, повторное снимает. Нет разделов у
  статей — строки нет; значения не загрузились — только чипы уровня.
- `ArticleFilter`, use case, datasource и запрос к базе
  (`contains(tags, [tag])`) не менялись («Обсуждение», п. 2).

### 1.3. Широкий экран задачи — FIG-20

- `task_screen.dart`, `_TaskBody`: уже `AppBreakpoints.tabletMax` —
  `_TaskTabs`, иначе — `_TaskWideTabs`. Это разные виджеты: при переходе
  через границу вкладки строятся заново и открыта первая.
- Общие `_TaskTabView` (`DefaultTabController`, `TabBar` с прокруткой вбок
  по левому краю, `TabBarView`) и `_TaskTabPage` (прокрутка с отступом
  `AppSpacing.lg`) — так же был устроен узкий экран.
- `_TaskWideTabs`: «Задача» (`taskTabProblem`) — `Row`: `Expanded(flex: 3)`
  с `_TaskStatement`, `VerticalDivider`, `Expanded(flex: 2)` с `EditorPanel`,
  без заголовка «Код»; «Попытки» (`taskTabAttempts`) — `AttemptsList` без
  заголовка; «Решения», «Справка», «Файлы» — `_TaskSolutions`,
  `TaskHelpPanel`, `TaskFilesPanel`. Прежняя лента `_TaskSidePanels` удалена.
- `submit_panel.dart`: хвост «Мои попытки» + `AttemptsList` убран, dartdoc —
  список ставит страница. На узком экране его ставит `_TaskCode` во вкладке
  «Код» под `EditorPanel` с прежними отступами и заголовком `attemptsTitle`;
  вкладки узкого экрана прежние.
- Уход с «Задачи» и возврат — как с «Кода» на узком экране, тот же
  `TabBarView`, keepAlive нет («Обсуждение», п. 3).
- Метка `TaskScreen`: UC-15, UC-28, UC-31, UC-34, UC-35 и UC-40.

### 1.4. «Запустить» и «Стоп» — FIG-20

- `editor_panel.dart`: обе кнопки в `Expanded`, между ними
  `SizedBox(AppSpacing.sm)`; подписи — `maxLines: 1`,
  `TextOverflow.ellipsis` («Обсуждение», п. 4). Поведение не менялось.

### 1.5. Отклик карточек — COMP-5, COMP-14, FIG-20

- `app_theme.dart`, `cardTheme`: `clipBehavior: Clip.antiAlias` —
  Material карточки обрезает подсветку и всплеск по скруглению
  `AppRadius.lg`. Действует на все `Card`: карточку задачи, статьи (в
  справочнике и в справке), файла и `AuthFormCard` входа и регистрации
  («Обсуждение», п. 5).

### 1.6. Выделение — COMP-16, FIG-20, FIG-22

- `task_screen.dart`, `_TaskStatement`: колонка условия — в `SelectionArea`:
  «Задание N», метка сложности, подсказка, текст условия, «Источник: …».
  Одинаково на широком (левая колонка «Задачи») и узком (вкладка «Условие»).
- `article_screen.dart`, `_ArticleBody`: колонка статьи — в `SelectionArea`:
  название, сведения, теги, текст. Заголовок `AppBar` — вне области.
- `app_markdown.dart`: параметр `selectable` удалён; `MarkdownBody` рисуется
  без `selectable` (по умолчанию `false`) — абзацы `Text.rich` и входят в
  область экрана; метка `COMP-16`.
- `code_block.dart`: внутри области (`SelectionContainer.maybeOf(context) !=
  null`) — `Text.rich`, вне — `SelectableText.rich`, как было («Обсуждение»,
  п. 6). Решения других (`SolutionsList`) — вне области, без изменений;
  консоль (`ConsoleView`) не менялась. Горизонтальная прокрутка блока кода —
  прежний `SingleChildScrollView`.
- Ссылки на статьи (UC-28) работают внутри области: проверено настоящим
  нажатием `tapOnText` в условии и в статье.

### 1.7. Справка — UC-40-P-01, UC-40-P-02

- `task_help_panel.dart`: на связь — `ArticleCard` справочника
  (`brief: link.article`), нажатие — `goNamed(referenceArticleName)`;
  `ExpansionTile`, `FilledButton.tonal` «Справка» и отступ `sm` убраны,
  отступ между карточками — `md` из `ArticleCard`. Порядок — как приходит
  из `TaskHelpRules`, главные первыми. Пустая справка и подсказка над
  условием — как были.

### 1.8. Метки

- UC-36 → UC-39: `provider_retry.dart` (строка меток упорядочена:
  UC-31, UC-34, UC-35, UC-37 и UC-39),
  `supabase_reference_remote_data_source.dart`,
  `reference_repository_impl.dart`, `list_articles_use_case.dart`,
  `reference_screen.dart`, `reference_controllers.dart`,
  `article_filters_bar.dart`; тесты `reference_repository_impl_test.dart`,
  `supabase_reference_remote_data_source_test.dart`,
  `article_filter_test.dart`, `reference_screen_test.dart`;
  `rls_tests.sql:1450`, `:1488`.
- UC-27 → UC-40: `supabase_tasks_remote_data_source.dart`,
  `tasks_repository_impl.dart`, `task_help_rules.dart`, `theme_article.dart`,
  `task_screen.dart`, `task_help_panel.dart`; тесты
  `tasks_repository_impl_test.dart`, `task_help_rules_test.dart`,
  `task_screen_test.dart`; `rls_tests.sql:1619`.
- COMP-15 → COMP-16 — `app_markdown.dart`; TOKEN-1 → TOKEN-7 —
  `app_colors.dart`.
- Новые: `CodifierSection`, `codifierSectionLabel` — UC-39; `TaskScreen` —
  ещё UC-34.
- В `rls_tests.sql` изменены только эти три комментария.

### 1.9. Тесты

Новые и изменённые:

- `test/features/reference/domain/codifier_section_test.dart` (новый):
  `fromTag` — `'1'`…`'4'` — разделы, `'1.1'`, `'5'`, `'regex'` — `null`;
  подписи всех четырёх разделов — тексты FIG-21.
- `reference_screen_test.dart`: чипы — уровни, «№ 17», «№ 24»,
  «1 · Цифровая грамотность», «3 · Алгоритмы и программирование»; тем
  «3.12», «1.4» и разделов 2, 4 нет; чип раздела отдаёт в отбор
  `ArticleFilter(tag: '3')`, отмечен, повторное нажатие снимает; у статей
  без разделов — только уровни. В тесте «Сбросить фильтры» вместо тега
  нажимается чип раздела `1`.
- `test/helpers/fake_reference_repository.dart`: теги тестовых статей — как
  на боевой: `['3.12', '3']` и `['1.4', '1']`.
- `task_screen_test.dart`:
  - справка — две карточки `ArticleCard`, главная выше сопутствующей; у
    сопутствующей описание, уровень, время, «№ 9 № 17 № 24 № 26 …», три тега
    из четырёх; `ExpansionTile` и `FilledButton` «Справка» нет; нажатие на
    карточку открывает `/reference/string-scan`;
  - «статья по теме»: прежняя проверка «главная раскрыта, есть кнопка
    «Справка»» заменена на «подсказка над условием есть, карточка статьи
    есть» — главность теперь видна только по подсказке, UC-40 и FIG-20;
  - широкий экран 1600×900: подписи вкладок «Задача», «Попытки», «Решения»,
    «Справка», «Файлы»; во «Задаче» — условие левее поля кода, разделитель
    на 3/5 ширины страницы вкладок, «Моих попыток» и `AttemptsList` нет; во
    «Попытках» — `AttemptsList` со строкой попытки, поля кода нет;
  - узкий экран: подписи вкладок «Условие», «Код», «Решения», «Справка»,
    «Файлы» — добавлено к прежнему тесту вкладок;
  - выделение: на узком 390×1600 и широком 1600×1600 — мышью от «Задание 24»
    до правее конца «Источник: Оригинальная задача», Ctrl+C, буфер обмена
    подменён на канале платформы (`test/helpers/selection.dart`, новый): в
    скопированном «Задание 24», «Средняя», подсказка, оба абзаца, ячейка
    таблицы «ABC», код блока «print(len(s))», источник; на широком — без
    «Ctrl+Enter — запустить»;
  - ссылка `[[regex-basics]]` в условии — `tapOnText` открывает
    `/reference/regex-basics`.
- `article_screen_test.dart`: `tapLink` — настоящее `tapOnText` вместо
  вызова `recognizer.onTap` у `SelectableText`: нажатие проходит hit test
  через область выделения, проверка строже; новый тест — ссылка открывает
  `/reference/regex-basics`, `lastSlug` — `regex-basics`; выделение статьи
  от названия до последнего абзаца: название, «Базовый», «6 мин», тег
  «3.12», заголовок, абзацы, ячейка «чтение», «print(1)».
- `app_markdown_test.dart`: параметр `selectable` убран, разметка — внутри
  `SelectionArea`, как на экранах; UC-28-P-01 там проверяет нажатие внутри
  области.
- `editor_panel_test.dart`: новый тест — ширины «Запустить» и «Стоп» равны
  и вместе с `AppSpacing.sm` занимают ширину поля кода — на узком 390×900 и
  после смены на 1600×900 во «Задаче»; в тесте «правка переживает смену
  вкладки и раскладки» `TabBar findsNothing` заменено на «есть вкладка
  «Задача»» — проверяется та же смена раскладки.
- `test/app/theme/card_ink_test.dart` (новый): `TaskCard`, `ArticleCard` и
  карточка `TaskFilesPanel` в `RepaintBoundary`, снимок `toImage`: при
  наведении мыши и при удержании нажатия пиксель (1, 1) — вне скругления —
  тот же, что без отклика; пиксель в поле отступа на высоте цели при
  наведении другой — отклик есть.

Путь → тесты с его меткой:

| Путь | Тесты |
|---|---|
| UC-39-P-01 | `reference_screen_test.dart`: «показывает список статей», «нажатие на карточку открывает статью»; `supabase_reference_remote_data_source_test.dart`: «статьи идут по уровню, затем по названию — по возрастанию»; `rls_tests.sql:1450`, `:1488` |
| UC-39-P-02 | `reference_screen_test.dart`: «выбор уровня уходит в запрос», «чипы номеров и разделов кодификатора — из значений фильтров, темы чипами не показываются», «чип раздела отбирает по тегу раздела, повторное нажатие снимает условие», «у статей нет разделов — строки разделов нет», «значения фильтров не загрузились — …», «строка поиска уходит в запрос через 300 мс после ввода», ««Сбросить фильтры» снимает все условия …»; `codifier_section_test.dart`: оба теста; `article_filter_test.dart`: три теста; `reference_repository_impl_test.dart`: «фильтр передаётся в datasource без изменений» |
| UC-39-P-03 | `reference_screen_test.dart`: «пустой справочник объясняет себя», «по заданным условиям статей нет» |
| UC-39-P-04 | `reference_screen_test.dart`: «ошибка списка показывается с кнопкой повтора», «сбой связи — сразу сообщение и «Повторить», без автоповторов» |
| UC-40-P-01 | `task_screen_test.dart`: «показывает условие и подсказку про справку», «на узком экране условие, справка и файлы — вкладки», «без ручных связей справка показывает статью по теме», «справка — карточки как в справочнике, главные первыми, без раскрытия и кнопки «Справка»», «нажатие на карточку справки открывает статью в разделе «Справочник»»; `task_help_rules_test.dart`: семь тестов; `tasks_repository_impl_test.dart`: два теста; `rls_tests.sql:1619` |
| UC-40-P-02 | `task_screen_test.dart`: «у задачи без статей справка пустая, подсказки над условием нет»; `task_help_rules_test.dart`: «нет ни тем, ни ручных связей — справка пустая»; `tasks_repository_impl_test.dart`: «без тем со статьями второй запрос не уходит» |

Прочие новые проверки: UC-15-P-01 и UC-34-P-01 — вкладки широкого экрана;
UC-15-P-01 — выделение условия на узком и широком; UC-37-P-01 — выделение
статьи; UC-28-P-01 — ссылка в условии и в статье; UC-32-P-01 — равные
кнопки; COMP-5, COMP-14, UC-15-P-01 — отклик карточек.

Тестом не проверено:

- прокрутка длинной строки блока кода вбок внутри области выделения — теста
  на неё нет и не было; код прокрутки (`SingleChildScrollView`) не менялся;
- выбранная вкладка при смене ширины окна (первая) — отдельного теста нет,
  смену раскладки проверяет «правка переживает смену вкладки и раскладки».

Видно только глазом:

- цвет акцента и производные: кнопки, индикаторы навигации, рамка поля в
  фокусе, ссылки и полоса цитаты, тональные кнопки;
- вид вкладок широкого экрана и колонок «Задачи»;
- вид всплеска `InkSparkle` в скруглении (тест смотрит угол и поле
  отступа, не форму всплеска);
- `AuthFormCard` входа и регистрации с обрезкой — внешне без изменений;
- цвет выделения и меню выделения в браузере;
- выделение мышью через блок кода с горизонтальной прокруткой.

## Не выполнено

Нет.

## Проверки

Локально, worktree `~/projects/yege_wars-TASK-9`, 2026-10-09, после всех
порч (файлы возвращены из копий).

```
$ flutter pub get
Got dependencies!
$ flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
  Built with build_runner/aot in 16s; wrote 28 outputs.
$ flutter analyze --fatal-infos --fatal-warnings
No issues found! (ran in 2.7s)
$ dart run custom_lint
No issues found!
$ flutter test
00:12 +377: All tests passed!
$ find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' -print0 | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 204 files (0 changed) in 0.20 seconds.
exit 0
$ bash supabase/tests/run_local.sh
psql:…/supabase/tests/rls_tests.sql:2923: NOTICE:  RLS TESTS PASSED
RLS OK
$ flutter build web --release --base-href /yege_wars/
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). …
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 10472 bytes (99.4% reduction). …
Compiling lib/main.dart for the Web...                             22,5s
✓ Built build/web
$ python3 -m sdlc_tool views && python3 -m sdlc_tool check
обновлено: sdlc/2-specs/use-cases/INDEX.md
обновлено: sdlc/3-design/design-system/INDEX.md
обновлено: sdlc/4-tasks/INDEX.md
обновлено: sdlc/5-results/INDEX.md
…
Итог: 0 ошибок, 142 предупреждения
```

Тестов 377: было 362, новых 15. Предупреждений `check` было 194, стало
142 — ушли 52 старые метки в коде и тестах; предупреждений по `lib/`,
`test/`, `supabase/` нет, оставшиеся — артефакты `sdlc/`, ссылающиеся на
похороненное. Предупреждение сборки о шрифтах CupertinoIcons было и до
задания (ACC-TASK-7-01, находка 3). Прогон `run` и снимки экранов не
делались — их делает постановщик.

Нехолостость: по одной порче за полный прогон `flutter test --reporter json`
(скрипт в scratchpad меняет файл и возвращает его из копии). Итог каждого
прогона дословно:

```
порча facets-tags (lib/features/reference/presentation/controllers/reference_controllers.dart): прошло 374, упало 3
  FAIL UC-39-P-01: показывает список статей
  FAIL UC-39-P-02: чипы номеров и разделов кодификатора — из значений фильтров, темы чипами не показываются
  FAIL UC-39-P-02: у статей нет разделов — строки разделов нет
порча chip-wrong-tag (lib/features/reference/presentation/widgets/article_filters_bar.dart): прошло 375, упало 2
  FAIL UC-39-P-02: чип раздела отбирает по тегу раздела, повторное нажатие снимает условие
  FAIL UC-39-P-02: «Сбросить фильтры» снимает все условия и строку поиска, а текст в поле остаётся
порча help-reversed (lib/features/tasks/presentation/widgets/task_help_panel.dart): прошло 376, упало 1
  FAIL UC-40-P-01: справка — карточки как в справочнике, главные первыми, без раскрытия и кнопки «Справка»
порча help-no-tap (lib/features/tasks/presentation/widgets/task_help_panel.dart): прошло 376, упало 1
  FAIL UC-40-P-01: нажатие на карточку справки открывает статью в разделе «Справочник»
порча wide-attempts-in-problem (lib/features/tasks/presentation/screens/task_screen.dart): прошло 376, упало 1
  FAIL UC-15-P-01, UC-34-P-01: на широком экране — вкладки «Задача», «Попытки», «Решения», «Справка», «Файлы»; во «Задаче» условие и код без «Моих попыток», во «Попытках» — список
порча stop-not-expanded (lib/features/editor/presentation/widgets/editor_panel.dart): прошло 376, упало 1
  FAIL UC-32-P-01: «Запустить» и «Стоп» делят строку поровну — на узком и на широком экране
порча task-no-selection-area (lib/features/tasks/presentation/screens/task_screen.dart): прошло 375, упало 2
  FAIL UC-15-P-01: на узком экране условие — одна область выделения от «Задание N» до источника
  FAIL UC-15-P-01: на широком экране условие — одна область выделения, код в неё не входит
порча article-no-selection-area (lib/features/reference/presentation/screens/article_screen.dart): прошло 376, упало 1
  FAIL UC-37-P-01: статья — одна область выделения от названия до конца текста
порча markdown-selectable (lib/core/markdown/app_markdown.dart): прошло 370, упало 7
  FAIL UC-28-P-01: нажатие на внутреннюю ссылку отдаёт slug
  FAIL UC-15-P-01: на узком экране условие — одна область выделения от «Задание N» до источника
  FAIL UC-15-P-01: на широком экране условие — одна область выделения, код в неё не входит
  FAIL UC-28-P-01: ссылка на статью в условии открывает статью в разделе «Справочник»
  FAIL UC-28-P-01: нажатие на ссылку открывает другую статью здесь же, в разделе «Справочник»
  FAIL UC-37-P-01: статья — одна область выделения от названия до конца текста
  FAIL UC-28-P-03: обычная ссылка не открывается
порча codeblock-always-selectable (lib/core/markdown/code_block.dart): прошло 374, упало 3
  FAIL UC-15-P-01: на узком экране условие — одна область выделения от «Задание N» до источника
  FAIL UC-15-P-01: на широком экране условие — одна область выделения, код в неё не входит
  FAIL UC-37-P-01: статья — одна область выделения от названия до конца текста
порча card-no-clip (lib/app/theme/app_theme.dart): прошло 374, упало 3
  FAIL COMP-5: отклик карточки задачи не выходит за скругление
  FAIL COMP-14: отклик карточки статьи не выходит за скругление
  FAIL UC-15-P-01: отклик карточки файла не выходит за скругление
```

Что делала каждая порча:

| Порча | Что испорчено |
|---|---|
| facets-tags | в значения фильтров — все четыре раздела, а не найденные в тегах |
| chip-wrong-tag | чип раздела отдаёт в отбор имя раздела (`algorithms`), а не тег |
| help-reversed | карточки справки в обратном порядке |
| help-no-tap | нажатие на карточку справки ничего не делает |
| wide-attempts-in-problem | во «Задаче» широкого экрана — код вместе с «Моими попытками» |
| stop-not-expanded | «Стоп» — `Flexible(fit: loose)` вместо `Expanded` |
| task-no-selection-area | у условия вместо `SelectionArea` — `SelectionContainer.disabled` |
| article-no-selection-area | то же у статьи |
| markdown-selectable | `MarkdownBody(selectable: true)` |
| codeblock-always-selectable | блок кода всегда `SelectableText.rich` |
| card-no-clip | из темы карточек убрано `clipBehavior: Clip.antiAlias` |

## Применено к боевой

Нет.

## Обсуждение

До начала работы — план СТОПа 0, 2026-10-09, вопросами с вариантами по
пунктам. Штатные механизмы, названные в плане: константы `AppColors` и
`ThemeData`; `DefaultTabController` + `TabBar` + `TabBarView`, как узкий
экран; `Card.clipBehavior`; `SelectionArea` с `MarkdownBody(selectable:
false)` — так советует README flutter_markdown_plus;
`SelectionContainer.maybeOf`; `ArticleCard` справочника.

1. Акцент. Варианты: только три константы `accent`, `accentHover`,
   `onAccent` и dartdoc `app_colors.dart` (метка TOKEN-7), `app_theme.dart`
   не меняется — вслед за константами меняются `onError` схемы (равен
   `onAccent`) и тональные кнопки (фон `secondary` = `accentHover`);
   поправить. Выбрано: **«Только константы»**.
2. Справочник. Варианты: enum `CodifierSection` в domain (`tag` `'1'`…`'4'`,
   `fromTag`) и подпись `codifierSectionLabel`, `ArticleFacets.tags` →
   `sections` (только разделы среди тегов, по номеру), `ArticleFilter.tag`,
   `toggleTag` и запрос к базе прежние; поле `section` в фильтре — правка use
   case, datasource и их тестов. Нет разделов у статей — строки разделов нет;
   значения не загрузились — только уровни. Выбрано: **«Enum + tag в
   фильтре»**.
3. Широкий экран. Варианты: всё как в плане — `_TaskWideTabs` с `TabBar`
   как на узком (прокручиваемый, по левому краю), «Задача» — `Row` 3 : 2 с
   `_TaskStatement` и `EditorPanel`, заголовка «Код» нет; «Мои попытки»
   уходят из `SubmitPanel` на страницу — на узком под `EditorPanel` во
   вкладке «Код», на широком `AttemptsList` во вкладке «Попытки» без
   заголовка; при смене ширины раскладка строится заново и открыта первая
   вкладка; при уходе с «Задачи» сохраняется то же, что с «Кода» на узком
   (код — да; ввод, консоль, строка состояния, ответ, вердикт, «Задача
   решена!» — нет, кроме случая, когда поле в фокусе держит вкладку); с
   заголовком «Код»; keepAlive для «Задачи». Выбрано: **«Весь пункт как в
   плане»**.
4. «Запустить» и «Стоп». Варианты: обе в `Expanded`, подпись в одну строку с
   многоточием; `Expanded` и штатный перенос подписи. Выбрано: **«Expanded +
   многоточие»**.
5. Отклик карточек. Варианты: `clipBehavior: Clip.antiAlias` в `cardTheme` —
   все `Card`, в том числе `AuthFormCard` входа и регистрации (внешне без
   изменений, проверка на снимке «Вход»); у трёх `Card` по месту. Выбрано:
   **«В cardTheme»**.
6. Выделение. `SelectionArea` вокруг `_TaskStatement` и колонки статьи,
   `AppMarkdown` без параметра `selectable` (`MarkdownBody(selectable:
   false)`), `CodeBlock` в области — `Text.rich`, вне — `SelectableText.rich`.
   Как `CodeBlock` узнаёт об области — варианты: `SelectionContainer.maybeOf`;
   флаг `selectable`. Выбрано: **`SelectionContainer.maybeOf`**.
7. Справка. Варианты: `ArticleCard` справочника без переноса, нажатие —
   `goNamed(referenceArticleName)`; общий виджет в `core/widgets`. Выбрано:
   **«ArticleCard справочника»**.
8. l10n. `taskTabProblem` «Задача», `taskTabAttempts` «Попытки»,
   `referenceSection1`…`4` — тексты FIG-21; удаляемых ключей нет. Варианты:
   так; поправить. Выбрано: **«Так»**.
9. Метки. UC-36 → UC-39, UC-27 → UC-40, COMP-15 → COMP-16, TOKEN-1 →
   TOKEN-7 в `lib/`, `test/` и трёх комментариях `rls_tests.sql`, номер пути
   прежний; новые — `CodifierSection` и подпись раздела UC-39, `TaskScreen`
   добавляет UC-34. Варианты: так; поправить. Выбрано: **«Так»**.
10. Тесты. По плану: чипы разделов и тег в отборе (UC-39-P-02) и юнит-тест
    `CodifierSection`; карточки справки, порядок, нажатие (UC-40-P-01);
    вкладки широкого экрана и список во «Попытках» (UC-15-P-01, UC-34-P-01);
    равная ширина кнопок (UC-32-P-01); выделение — протягивание мышью и
    Ctrl+C в подменённый буфер (UC-15-P-01, UC-37-P-01); ссылки — настоящим
    `tapOnText` (UC-28-P-01); теги тестовых статей — как на боевой;
    нехолостость — по одной порче за полный прогон `flutter test`. Как
    проверять отклик карточек — варианты: по пикселям снимка (угол — фон,
    центр отличается от карточки без наведения); по структуре
    `Material.clipBehavior`. Выбрано: **«По пикселям снимка»**.

По ходу работы решений вне постановки и плана не принималось.

11. СТОП 1, 2026-10-09: коммитить ли работу в `task/TASK-9` — коммит
    работы, затем отдельным коммитом сдача, без push. Варианты: да,
    коммитить; нет, сначала поправить. Выбрано: **«Да, коммитить»**.

## Отступления от задания

Нет.

## Найдено вне задания

- Прокрутка блока кода вбок тестом не проверяется ни сейчас, ни до задания
  (COMP-11: «длинные строки прокручиваются вбок»).
