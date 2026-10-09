# RESULT-TASK-7-01: Выкладка сайта на GitHub Pages по ручному запуску

## Задание

[TASK-7](../4-tasks/TASK-7-SITE-DEPLOY.md).

## Коммит работы

`0cb6a3f` — «TASK-7: выкладка сайта на GitHub Pages по ручному запуску»,
ветка `task/TASK-7`, после «да» владельца на СТОПе 1 («Обсуждение», п. 15).
Индексы в этом коммите собраны без сдачи; сдача и индексы с ней — отдельным
коммитом. Push не было.

```
0cb6a3f56c5fd527b7d87407c58a84dffb64a758
TASK-7: выкладка сайта на GitHub Pages по ручному запуску

 .github/workflows/deploy.yml                 | 127 ++++++++++++
 README.md                                    |  32 ++-
 lib/core/python_runtime/pyodide_runtime.dart |   3 +
 pubspec.lock                                 |   2 +-
 pubspec.yaml                                 |   2 +
 sdlc/2-specs/use-cases/INDEX.md              |   2 +-
 test/deploy/deploy_workflow_test.dart        | 287 +++++++++++++++++++++++++++
 test/web/site_base_href_test.dart            |  93 +++++++++
 web/index.html                               |   5 +
 9 files changed, 550 insertions(+), 3 deletions(-)
```

## Выполнено

### 1.1. Workflow выкладки — UC-29

Новый `.github/workflows/deploy.yml`, `name: Выкладка сайта`:

- `on: workflow_dispatch` без входов, других триггеров нет; `permissions:
  contents: read` на весь workflow; `concurrency: {group: pages,
  cancel-in-progress: false}`.
- Задача `build` (`ubuntu-24.04`, права `contents: read`, `pages: read`), шаги
  по порядку:
  1. «Только main» — `GITHUB_REF` не `refs/heads/main`: `::error::Выкладка
     только из main, а запущена из <ref>. Запустите заново с веткой main.`,
     выход 1.
  2. «Секреты заданы» — `env` из `secrets.SUPABASE_URL` и
     `secrets.SUPABASE_ANON_KEY`, `shell: bash`; для каждого пустого
     `::error::Секрет <имя> не задан: Settings → Secrets and variables →
     Actions.`, после обоих — выход 1. Печатаются только имена.
  3. `actions/checkout@v7` без `ref`.
  4. «Настройки Pages» — `actions/configure-pages@v6`.
  5. `subosito/flutter-action@v2`: 3.41.0, stable, `cache: true`.
  6. Проверки, как в задаче `build` из `ci.yml`: `flutter pub get`, проверка
     `dart format` без генерённых файлов, `flutter gen-l10n`, `dart run
     build_runner build`, `flutter analyze --fatal-infos --fatal-warnings`,
     `dart run custom_lint`, `flutter test`.
  7. «Сборка сайта» — `env` из тех же секретов; `flutter build web --release
     --base-href /yege_wars/ --dart-define=SUPABASE_URL="$SUPABASE_URL"
     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"`.
  8. «Загрузка сайта» — `actions/upload-pages-artifact@v5`, `path: build/web`.
- Задача `deploy`: `needs: build`, `ubuntu-24.04`, права `pages: write`,
  `id-token: write`, `environment: {name: github-pages, url: ${{
  steps.deployment.outputs.page_url }}}`, шаг `actions/deploy-pages@v5` с
  `id: deployment`.
- `ci.yml` не менялся.

Workflow не запускался: задание запрещает, а кнопка появится только после
вливания в `main`.

### 1.2. Веб-часть — UC-30

Поведение `lib/` и `web/` не менялось — только комментарии с меткой (1.4).
Что держит сайт под `/yege_wars/`, закрепляют тесты (1.5).

### 1.3. README

Раздел «Деплой» вместо заглушки: адрес сайта; что владелец делает один раз —
Pages с источником «GitHub Actions», секреты `SUPABASE_URL` и
`SUPABASE_ANON_KEY` (без значений, «те же, что в `supabase/.env.local`»);
запуск — Actions → «Выкладка сайта» → Run workflow → `main`, кнопка есть,
только когда workflow в `main`; шаги выкладки; если упала — сайт прежний,
причина — в упавшем шаге прогона, у шагов ветки и секретов — ещё и в
аннотации; после исправления — запуск заново.

### 1.4. Метки

- `.github/workflows/deploy.yml` — `# Реализует UC-29.` в шапке. Скрипт
  `.github/` не читает: у UC-29 в `2-specs/use-cases/INDEX.md` «Где
  реализован» — «не покрыто», как решил владелец.
- `web/index.html` — комментарий `Реализует UC-30: …` у `<base href>`.
- `lib/core/python_runtime/pyodide_runtime.dart` — строка в dartdoc
  `PyodideRuntime.defaultWorkerUrl`: «…разрешается от `<base href>` страницы
  — UC-30».
- После `views` у UC-30 «Где реализован» — эти два файла.

### 1.5. Тесты

`pubspec.yaml`: `yaml: ^3.1.4` в `dev_dependencies` с комментарием;
`pubspec.lock`: у `yaml` `dependency: transitive` → `"direct dev"`, версия
та же 3.1.4.

`test/deploy/deploy_workflow_test.dart` разбирает `deploy.yml` пакетом
`yaml`. Шаги «Только main», «Секреты заданы» и «Сборка сайта» тест
запускает: пишет `run` шага во временный файл и выполняет его так же, как
GitHub на Linux, — при `shell: bash` `bash --noprofile --norc -eo pipefail`,
без `shell` — `bash -e`. Для шага сборки в начало `PATH` ставится поддельный
`flutter`, который печатает свои аргументы, — тест сверяет команду целиком.
Значения секретов в тесте — поддельные.

`test/web/site_base_href_test.dart` читает `web/index.html`,
`web/manifest.json` и исходник `pyodide_runtime.dart` — `PyodideRuntime` на
VM не импортируется (`dart:js_interop`).

| Путь | Тесты с его меткой |
|---|---|
| [UC-29-P-01](../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-01) | `deploy_workflow_test.dart`: «выкладка запускается только вручную — workflow_dispatch, других триггеров нет»; «выкладывается только main — другая ветка останавливает сборку первым шагом» (шаг первый; `refs/heads/main` — код 0, `refs/heads/task/TASK-7` — не 0, `::error::` и ref в выводе; у checkout нет `ref`); «перед сборкой — анализ и тесты, как в CI» (7 команд есть и стоят раньше сборки); «сборка по ENT-16 — release, base href /yege_wars/, параметры из секретов» (`env` шага — из секретов, аргументы `flutter` — ровно `build web --release --base-href /yege_wars/ --dart-define=SUPABASE_URL=<знач.> --dart-define=SUPABASE_ANON_KEY=<знач.>`); «сборка публикуется на GitHub Pages из build/web» (`configure-pages` есть; артефакт из `build/web` после сборки; `deploy` — `needs: build`, окружение `github-pages`, права `pages: write`, `id-token: write`, единственный шаг — `deploy-pages`) |
| [UC-29-P-02](../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-02) | `deploy_workflow_test.dart`: «не задан SUPABASE_URL — выкладка падает до сборки, в логе — имя секрета»; «не задан SUPABASE_ANON_KEY — …»; «не задан SUPABASE_URL и SUPABASE_ANON_KEY — …» (код не 0, `::error::Секрет <имя> не задан` — ровно у пустых, поддельных значений в выводе нет); «оба секрета заданы — проверка проходит и значений не печатает»; «секреты проверяются до checkout, проверок и сборки»; «упавшая сборка не публикуется — публикация только в deploy после build» (`needs: build`; у задач и шагов `build` нет `if` и `continue-on-error`; `deploy-pages` в `build` нет) |
| [UC-30-P-01](../2-specs/use-cases/UC-30-ACTOR-1-EVT-10-ENT-16-SITE-OPENED-IN-SITE.md#uc-30-p-01) | `site_base_href_test.dart`: «<base href> в web/index.html — из параметра сборки --base-href» (один `<base>`, значение `$FLUTTER_BASE_HREF`); «адреса в web/index.html относительные и ведут в web/» (все `href` и `src`, кроме `<base>`: без `/` в начале и без схемы, файл есть в `web/`, кроме `flutter_bootstrap.js` — его пишет сборка); «адреса в web/manifest.json относительные и ведут в web/» (`start_url`, `scope`, если есть, `src` иконок); «воркер Python грузится с адреса сайта — адрес относительный» (`defaultWorkerUrl` из исходника — относительный, `web/pyodide_worker.js` есть) |

Нехолостость — раздел «Проверки».

### По путям UC

- [UC-29-P-01](../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-01)
  — workflow собирает `main` по ENT-16 и публикует на Pages; тестами
  закреплён текст workflow и поведение шагов ветки и сборки. Что сайт
  действительно обновился — только TC-1.
- [UC-29-P-02](../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-02)
  — пустой секрет роняет выкладку вторым шагом с именем секрета в логе;
  любая неудача в `build` до публикации не пускает `deploy`. Что сайт после
  этого прежний — только TC-1.
- [UC-30-P-01](../2-specs/use-cases/UC-30-ACTOR-1-EVT-10-ENT-16-SITE-OPENED-IN-SITE.md#uc-30-p-01)
  — `<base href>` из `--base-href`, адреса страницы, манифеста и воркера
  относительные; локальная сборка `--base-href /yege_wars/` даёт `<base
  href="/yege_wars/">` и `pyodide_worker.js` в `build/web`. Что приложение
  открывается по адресу сайта на компьютере и телефоне — только TC-1.

### Что проверит только TC-1

Тестом не проверить — нужен настоящий прогон на GitHub или браузер на
выложенном сайте:

- кнопка Run workflow есть, запуск из `main` проходит до публикации;
- `configure-pages` проходит при включённом Pages и падает при выключенном;
- секреты из настроек репозитория доходят до сборки, сайт открывается не на
  экране «не сконфигурировано»;
- `deploy-pages` публикует, по адресу сайта — новая версия; после упавшей
  выкладки — прежняя;
- в браузере по `https://pavelsmirnov76.github.io/yege_wars/` грузятся
  `main.dart.js`, манифест, иконки и `pyodide_worker.js` с адреса сайта,
  запуск Python работает; адреса внутри приложения — с `#`, перезагрузка на
  `…/yege_wars/#/task/<slug>` открывает задачу;
- правило окружения `github-pages`: документация GitHub советует добавить
  «только ветка по умолчанию», README `deploy-pages` пишет, что ставит его
  сам, — как вышло, видно только после включения Pages.

## Не выполнено

Нет. Первая выкладка, включение Pages, секреты и TC-1 — вне задания.

## Проверки

2026-10-09, worktree `~/projects/yege_wars-TASK-7`, незакоммиченное состояние
работы; команды «Проверок части 1» по одной, выводы — хвосты дословно.

```
$ flutter pub get
Got dependencies!
$ flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
  Built with build_runner/aot in 0s; wrote 0 outputs.
$ flutter analyze --fatal-infos --fatal-warnings
No issues found! (ran in 2.1s)
$ dart run custom_lint
No issues found!
$ flutter test
00:12 +351: All tests passed!
$ find lib test … | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 198 files (0 changed) in 0.19 seconds.
$ bash supabase/tests/run_local.sh
NOTICE:  RLS TESTS PASSED
RLS OK
$ flutter build web --release --base-href /yege_wars/
✓ Built build/web
$ grep -n '<base href' build/web/index.html
22:  <base href="/yege_wars/">
$ ls build/web/pyodide_worker.js
build/web/pyodide_worker.js
$ python3 -m sdlc_tool views && python3 -m sdlc_tool check
Итог: 0 ошибок, 92 предупреждения
```

Тестов 351: 336 прежних и 15 новых — `deploy_workflow_test.dart` — 11
(5 UC-29-P-01, 6 UC-29-P-02), `site_base_href_test.dart` — 4 (UC-30-P-01).
92 предупреждения `check` — те же, что в «Исходном состоянии» задания, все в
записях `sdlc/`.

Утечки: значения `supabase/.env.local` (5 штук) и шаблоны ключей,
адреса проекта, JWT и строк подключения в изменённых файлах и сдаче — 0
совпадений; печатались только счётчики.

### Нехолостость

Порча — замена в рабочем файле, по одной за прогон всего `flutter test
--reporter json`; после прогона файл возвращён из копии и сверен с исходным.
Каждая порча роняет новый тест, прочие тесты проходят.

| № | Порча | Упали |
|---|---|---|
| 1 | workflow: добавлен триггер `push` | UC-29-P-01 «только вручную» |
| 2 | workflow: проверка ветки на `refs/heads/dev` вместо `main` | UC-29-P-01 «только main» |
| 3 | workflow: `checkout` с `ref: dev` | UC-29-P-01 «только main» |
| 4 | workflow: шаг `flutter test` после сборки | UC-29-P-01 «анализ и тесты» |
| 5 | workflow: `flutter analyze` заменён на `echo` | UC-29-P-01 «анализ и тесты» |
| 6 | workflow: `--base-href /` | UC-29-P-01 «сборка по ENT-16» |
| 7 | workflow: сборка без `--dart-define=SUPABASE_ANON_KEY` | UC-29-P-01 «сборка по ENT-16» |
| 8 | workflow: `--dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }}` | UC-29-P-01 «сборка по ENT-16» |
| 9 | workflow: проверка секретов только `SUPABASE_URL` | UC-29-P-02 «не задан SUPABASE_ANON_KEY», «не задан SUPABASE_URL и SUPABASE_ANON_KEY» |
| 10 | workflow: проверка секретов печатает `url=$SUPABASE_URL` | UC-29-P-02 «не задан SUPABASE_ANON_KEY», «оба секрета заданы» |
| 11 | workflow: проверка секретов после `checkout` | UC-29-P-02 «секреты проверяются до checkout» |
| 12 | workflow: у `deploy` нет `needs` | UC-29-P-01 «публикуется на GitHub Pages», UC-29-P-02 «упавшая сборка не публикуется» |
| 13 | workflow: у `deploy` `if: always()` | UC-29-P-02 «упавшая сборка не публикуется» |
| 14 | workflow: у шага тестов `continue-on-error: true` | UC-29-P-02 «упавшая сборка не публикуется» |
| 15 | workflow: артефакт из `build` вместо `build/web` | UC-29-P-01 «публикуется на GitHub Pages» |
| 16 | `web/index.html`: `href="/favicon.png"` | UC-30-P-01 «адреса в web/index.html» |
| 17 | `web/index.html`: `<base href="/">` | UC-30-P-01 «<base href> … из параметра сборки», «адреса в web/index.html» |
| 18 | `web/manifest.json`: `"start_url": "/"` | UC-30-P-01 «адреса в web/manifest.json» |
| 19 | `lib/…/pyodide_runtime.dart`: `defaultWorkerUrl = '/pyodide_worker.js'` | UC-30-P-01 «воркер Python» |

Вывод прогонов — счётчики дословно: порчи 1–8, 11, 13–16, 18, 19 —
`flutter test: код 1, прошли 350, упали 1`; порчи 9, 10, 12, 17 — `код 1,
прошли 349, упали 2`. Без порчи после всех — `flutter test: код 0, прошли
351, упали 0`. `git status` после — только файлы работы.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — план СТОПа 0, 2026-10-09, вопросами с вариантами по
пунктам. Штатный механизм платформы, названный в плане: шаблон GitHub
`starter-workflows/pages/static.yml` и README `actions/deploy-pages` — задача
сборки загружает артефакт `upload-pages-artifact`, задача выкладки с `needs`
публикует его `deploy-pages` в окружение `github-pages`, права выкладки
`pages: write` и `id-token: write`, `concurrency: pages` без обрыва. Версии
по API GitHub 2026-10-09: `configure-pages` v6.0.0, `upload-pages-artifact`
v5.0.0, `deploy-pages` v5.0.1.

1. Устройство workflow. Варианты: две задачи `build` и `deploy` по шаблону,
   права `pages: write` и `id-token: write` только у `deploy`, на весь
   workflow `contents: read`; одна задача с правами на весь workflow, как
   `static.yml`; три задачи `checks → build → deploy`. Общее: файл
   `.github/workflows/deploy.yml`, `name: Выкладка сайта`, только
   `workflow_dispatch` без входов, `concurrency: {group: pages,
   cancel-in-progress: false}`, `runs-on: ubuntu-24.04`,
   `subosito/flutter-action@v2` 3.41.0 stable `cache: true` — как в CI.
   Выбрано: **`build` + `deploy`**.
2. «Выкладывается текущий `main`», в форме выбрана другая ветка. Варианты:
   первый шаг `build` проверяет `GITHUB_REF` и падает с `::error::` и именем
   ветки до секретов и проверок; `checkout` с `ref: main`; `if:` у задачи —
   прогон зелёный, причины в логе нет; только правило окружения
   `github-pages` — падение на публикации. Выбрано: **шаг-проверка,
   падение**.
3. Проверки до сборки. Варианты: свои шаги, как в задаче `build` CI —
   `pub get`, проверка `dart format`, `gen-l10n`, `build_runner build`,
   `analyze --fatal-infos --fatal-warnings`, `custom_lint`, `flutter test`
   без `--coverage`, `ci.yml` не меняется; `ci.yml` через `workflow_call`;
   только `analyze` и `flutter test`. Выбрано: **свои шаги, `ci.yml` не
   трогать**.
4. Пустой секрет. Варианты: шаг в workflow сразу после проверки ветки, до
   checkout, — `env` из секретов, `shell: bash`, для каждого пустого
   `::error::Секрет <имя> не задан: Settings → Secrets and variables →
   Actions.`, затем выход 1, значения не печатаются; тест берёт `run` шага из
   YAML и запускает `bash --noprofile --norc -eo pipefail`; отдельный файл
   `.github/scripts/check-secrets.sh`; как первый, но прямо перед сборкой.
   Выбрано: **шаг в workflow сразу после проверки ветки**.
5. Сборка: `flutter build web --release --base-href /yege_wars/
   --dart-define=SUPABASE_URL="$SUPABASE_URL"
   --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"`. Варианты: значения
   через `env` шага из секретов, `--base-href` — литерал по ENT-16;
   `${{ secrets.X }}` прямо в команде; `--base-href` из `base_path` действия
   `configure-pages`. Выбрано: **через `env` шага**.
6. Публикация: `actions/upload-pages-artifact@v5` в `build` из `build/web`,
   `actions/deploy-pages@v5` в `deploy`, окружение `github-pages` с `url` из
   выхода шага, версии — мажорными тегами, как в `ci.yml`. Вопрос: ставить ли
   `configure-pages`. Варианты: `actions/configure-pages@v6` после checkout —
   при выключенном Pages падение сразу, задаче `build` нужно `pages: read`;
   без него — падает `deploy-pages` после проверок и сборки. Выбрано: **с
   `configure-pages@v6`**.
7. Тесты: YAML — пакетом `yaml` в `dev_dependencies`; файлы
   `test/deploy/deploy_workflow_test.dart` (UC-29-P-01, UC-29-P-02) и
   `test/web/site_base_href_test.dart` (UC-30-P-01); нехолостость — порчами
   по одной за прогон всего `flutter test`. Вопрос: как проверять адрес
   воркера — `PyodideRuntime` на VM не импортируется (`dart:js_interop`).
   Варианты: тест читает `pyodide_runtime.dart` и берёт значение
   `defaultWorkerUrl`; браузерный тест `@TestOn('browser')` — `flutter test`
   и `run` его пропускают; вынести константу в файл без `dart:js_interop` —
   правка `lib/` сверх комментариев. Выбрано: **чтением исходника**.
8. Метки: `UC-29` — комментарий `Реализует UC-29.` в шапке `deploy.yml`.
   Вопрос: где `UC-30`. Варианты: комментарий у `<base href>` в
   `web/index.html` и строка в dartdoc `PyodideRuntime.defaultWorkerUrl`;
   только `web/index.html`. Выбрано: **`web/index.html` и
   `defaultWorkerUrl`**.
9. README «Деплой»: адрес сайта; один раз — Pages с источником «GitHub
   Actions» и секреты `SUPABASE_URL`, `SUPABASE_ANON_KEY` без значений;
   запуск — Actions → «Выкладка сайта» → Run workflow → `main`, кнопка есть,
   только когда workflow в `main`; что делает выкладка; упала — красный шаг и
   аннотация, сайт прежний. Вопрос: добавлять ли шаг владельца — правило
   окружения `github-pages` «только `main`». Варианты: без него — только
   предусловия UC-29; с ним — второй замок к п. 2. Выбрано: **без правила
   окружения**.

По ходу — выбор исполнителя там, где задание и план его не предписывали:

10. Шаг сборки проверяется запуском с поддельным `flutter` в `PATH`, а не
    разбором строки: тест сверяет аргументы, какими их получит `flutter`, и
    не зависит от переносов и кавычек в YAML.
11. Шаги в тесте ищутся по имени («Только main», «Секреты заданы») и по
    команде (`flutter build web` и проверки) — переименование шага или смена
    команды роняет тест.
12. Тест «упавшая сборка не публикуется» проверяет ещё отсутствие `if` и
    `continue-on-error` у задач и шагов `build`: без них GitHub не идёт
    дальше упавшего шага и не запускает `deploy` после упавшей `build`.
13. Порч — 19 вместо 12 из плана: добавлены checkout с `ref`, без
    статического анализа, `${{ secrets }}` в команде сборки, проверка
    секретов после checkout, `if: always()` у `deploy`, `continue-on-error`
    у тестов, артефакт из `build` вместо `build/web`.
14. Шаг «Секреты заданы» перебирает имена циклом с косвенной подстановкой
    bash `${!name}` — один текст сообщения на оба секрета.

СТОП 1:

15. 2026-10-09. Вопрос: коммитить ли TASK-7 в `task/TASK-7` — работа
    отдельно, затем сдача отдельным коммитом, без push. Варианты:
    коммитить; не коммитить — есть правки. Выбрано: **коммитить**.

## Отступления от задания

Нет.

## Найдено вне задания

1. Адреса внутри приложения с `#` (ENT-16) тестом не закреплены: в `lib/`
   нет `usePathUrlStrategy` и `setUrlStrategy`, но проверки на это нет —
   задание её не просило. Без `#` перезагрузка на `…/yege_wars/task/<slug>`
   дала бы `404` от Pages. Сейчас это проверит только TC-1.
2. `web/manifest.json` и `web/index.html` — остатки шаблона Flutter:
   `"name"` и `"short_name"` — `yege_wars`, `"description": "A new Flutter
   project."`, `background_color` и `theme_color` — `#0175C2`, а фон страницы
   — `#0F1115`; `apple-mobile-web-app-title` — `yege_wars`. Это видно при
   добавлении сайта на экран «Домой» телефона. Не чинилось: менять поведение
   `web/` задание запрещает.
3. `flutter build web --release --base-href /yege_wars/` печатает «Expected
   to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons),
   but found (MaterialIcons)…». В `lib/` нет `CupertinoIcons`, в
   `pubspec.yaml` нет `cupertino_icons`; откуда ссылка, не искал. Сборка
   проходит.
4. Проверки выкладки повторяют задачу `build` из `ci.yml` (решение п. 3): при
   правке проверок CI ту же правку нужно вносить в `deploy.yml`. Тест
   сверяет команды выкладки, но с `ci.yml` их не сравнивает.
