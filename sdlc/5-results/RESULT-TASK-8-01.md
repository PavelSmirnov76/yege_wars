# RESULT-TASK-8-01: Кнопка «Тестовый вход» на экране входа и её секреты в выкладке

## Задание

[TASK-8](../4-tasks/TASK-8-TEST-LOGIN.md).

## Коммит работы

`c3abc87` — «TASK-8: кнопка «Тестовый вход» на экране входа и её секреты в
выкладке», ветка `task/TASK-8`, после «да» владельца на СТОПе 1
(«Обсуждение», п. 13). Индексы в этом коммите собраны без сдачи; сдача и
индексы с ней — отдельным коммитом. Push не было.

```
c3abc87d35d54ab3e7236faf6c75f4fbc7e89eff
TASK-8: кнопка «Тестовый вход» на экране входа и её секреты в выкладке

 .github/workflows/deploy.yml                       |   7 ++
 README.md                                          |  26 +++-
 lib/app/theme/app_theme.dart                       |  19 +++
 lib/core/config/env.dart                           |  13 ++
 lib/features/auth/auth_providers.dart              |  13 ++
 .../auth/domain/entities/test_account.dart         |  27 +++++
 .../auth/presentation/screens/login_screen.dart    |  22 +++-
 lib/l10n/app_ru.arb                                |   1 +
 sdlc/2-specs/use-cases/INDEX.md                    |   2 +-
 test/app/router/app_router_test.dart               |  20 +++
 test/deploy/deploy_workflow_test.dart              | 112 ++++++++++++++---
 .../auth/presentation/login_screen_test.dart       | 134 +++++++++++++++++++++
 test/helpers/fake_auth_repository.dart             |   7 ++
 test/helpers/pump_app.dart                         |   5 +
 14 files changed, 381 insertions(+), 27 deletions(-)
```

## Выполнено

### 1.1. Кнопка «Тестовый вход» — UC-38

- `lib/core/config/env.dart`: `Env.testLoginUsername` и
  `Env.testLoginPassword` — `String.fromEnvironment('TEST_LOGIN_USERNAME')`
  и `('TEST_LOGIN_PASSWORD')`, без значений по умолчанию.
- Новый `lib/features/auth/domain/entities/test_account.dart`: `TestAccount`
  (ENT-17) — `username`, `password`; `static TestAccount? fromBuild(...)` —
  `null`, если хотя бы одно значение пустое («Обсуждение», п. 2).
- `lib/features/auth/auth_providers.dart`: `testAccountProvider`
  (`@Riverpod(keepAlive: true)`) — `TestAccount.fromBuild(username:
  Env.testLoginUsername, password: Env.testLoginPassword)`.
- `lib/features/auth/presentation/screens/login_screen.dart`:
  `ref.watch(testAccountProvider)`; есть учётная запись — под «Войти»
  `SizedBox(AppSpacing.sm)` и `OutlinedButton` с текстом
  `authTestSignInButton`, ниже — ссылка на регистрацию, как была. Пока
  `_isSubmitting`, у кнопки `onPressed: null`. Нажатие —
  `_submitTestAccount`: логин и пароль — в контроллеры полей, затем тот же
  `_submit()`, что у «Войти»: проверка полей, `signIn`, сообщение над
  формой; переход делает guard роутера.
- `lib/app/theme/app_theme.dart`: `outlinedButtonTheme` — минимальный
  размер `_minTapTarget`, отступы `AppSpacing.xl`/`AppSpacing.md`, форма
  `_controlRadius`, шрифт `labelLarge`, как у `filledButtonTheme`; цвета —
  из цветовой схемы («Обсуждение», п. 4). Тема действует и на
  `OutlinedButton.icon` «Копировать» в панели файлов задачи: было — высота
  40 и форма «пилюля» по умолчанию Material, стало — высота не меньше 44 и
  скругление `AppRadius.md`, как у соседней «Скачать».
- `lib/l10n/app_ru.arb`: `authTestSignInButton` — «Тестовый вход».
- Остальное на экране входа не менялось.

### 1.2. Локальный запуск — README

Команда передаёт ещё `--dart-define=TEST_LOGIN_USERNAME="$TEST_LOGIN_USERNAME"`
и `--dart-define=TEST_LOGIN_PASSWORD="$TEST_LOGIN_PASSWORD"` из
`supabase/.env.local`; абзац: логин и пароль тестовой учётной записи,
необязательны, когда заданы оба — кнопка «Тестовый вход», без них кнопки нет.
Значений нет.

### 1.3. Выкладка — R49, UC-29-P-02

- `.github/workflows/deploy.yml`, шаг «Сборка сайта»: в `env` —
  `TEST_LOGIN_USERNAME` и `TEST_LOGIN_PASSWORD` из секретов с теми же
  именами; в команде — ещё два `--dart-define=…="$…"`. Незаданный секрет
  приходит пустой строкой — сборка идёт, кнопки нет.
- «Секреты заданы» и остальные шаги не менялись. Значения нигде не
  печатаются.
- README «Деплой»: в «Один раз» — п. 3, необязательные секреты
  `TEST_LOGIN_USERNAME` и `TEST_LOGIN_PASSWORD`; заданы оба — кнопка на
  сайте, не заданы — сайт без неё; убрать тестовый вход — удалить секреты и
  выложить заново. Шаг 2 — «`SUPABASE_URL` и `SUPABASE_ANON_KEY` заданы»,
  шаг 5 — четыре `--dart-define`. Без предупреждения о пароле в коде сайта —
  «Обсуждение», п. 9.

### 1.4. Метки

- `UC-38` комментарием: dartdoc `LoginScreen` («Реализует UC-10, UC-38 и
  UC-1.») и `_submitTestAccount`, `TestAccount`, `testAccountProvider`.
- В workflow — комментарий над шагом «Сборка сайта»: «Секреты тестового
  входа (UC-38) необязательны…». Шапка «Реализует UC-29.» не менялась.
- Индекс UC-38 после `views`: код — `auth_providers.dart`,
  `test_account.dart`, `login_screen.dart`.

### 1.5. Тесты

- `test/helpers/pump_app.dart`: параметр `TestAccount? testAccount`,
  `testAccountProvider` подменяется всегда, по умолчанию `null`.
- `test/helpers/fake_auth_repository.dart`: `fakeTestAccount` — поддельные
  логин и пароль.
- `test/deploy/deploy_workflow_test.dart`: `_expectSecretsEnv(step, names)` —
  у «Секретов заданы» `_secretNames`, у сборки ещё
  `_testLoginSecretNames`; помощники `_buildEnv` и `_buildCall`.

Путь → тесты с его меткой:

| Путь | Тесты с его меткой (файл) |
|---|---|
| [UC-38-P-01](../2-specs/use-cases/UC-38-ACTOR-1-EVT-2-ENT-17-TEST-SESSION-STARTED-IN-AUTH.md#uc-38-p-01) | «UC-38-P-01: «Тестовый вход» подставляет логин и пароль и входит; пока идёт отправка, обе кнопки недоступны», «UC-38-P-01: пока отправляет «Войти», «Тестовый вход» недоступна» (`login_screen_test.dart`); «адрес после входа UC-38-P-01: после тестового входа открывается запомненный адрес» (`app_router_test.dart`); «UC-29-P-01, UC-38-P-01: сборка по ENT-16 и ENT-17 — release, base href /yege_wars/, параметры и тестовый вход из секретов» (`deploy_workflow_test.dart`) |
| [UC-38-P-02](../2-specs/use-cases/UC-38-ACTOR-1-EVT-2-ENT-17-TEST-SESSION-STARTED-IN-AUTH.md#uc-38-p-02) | «UC-38-P-02: не заданы логин и пароль — кнопки «Тестовый вход» нет», «UC-38-P-02: задан только логин — …», «UC-38-P-02: задан только пароль — …» (`login_screen_test.dart`); «UC-38-P-02: секреты тестового входа не заданы — проверка секретов проходит, сборка идёт с пустыми значениями» (`deploy_workflow_test.dart`) |
| [UC-38-P-03](../2-specs/use-cases/UC-38-ACTOR-1-EVT-2-ENT-17-TEST-SESSION-STARTED-IN-AUTH.md#uc-38-p-03) | «UC-38-P-03: тестовый вход отклонён — сообщение над формой, в полях подставленные значения» (`login_screen_test.dart`) |
| [UC-29-P-02](../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-02) | новый — «UC-29-P-02: сборка упала — шаг сборки падает, дальше выкладка не идёт»; прежние 7 из TASK-7 не менялись, кроме вызова `_expectSecretsEnv` со списком имён (`deploy_workflow_test.dart`) |

Тест «сборка по ENT-16» переименован и сверяет вызов `flutter` целиком, с
четырьмя `--dart-define`: метки UC-29-P-01 и UC-38-P-01 в одном имени.
Все тесты таблицы — `PASS`.

Без метки пути — «Обсуждение», п. 8: «тестовый вход с логином и паролем не
по правилам — ошибки у полей, запрос не отправлен» (`login_screen_test.dart`).

Нехолостость:

Скрипт в scratchpad: порча — замена одной строки в одном файле, прогон всего
`flutter test --reporter json`, файл возвращается из копии; после всех порч
хэши файлов совпали с исходными. Без порчи — 362 теста, 0 упавших.

| № | Порча | Упали |
|---|---|---|
| 1 | `fromBuild`: `&&` вместо `||` — хватает одного значения | 2: UC-38-P-02 «только логин», «только пароль» |
| 2 | `fromBuild`: учётная запись есть всегда | 3: все UC-38-P-02 на экране |
| 3 | кнопка не заполняет поля | 3: UC-38-P-01 (экран, роутер), UC-38-P-03 |
| 4 | кнопка входит `signIn` напрямую, мимо полей | 3: UC-38-P-01, UC-38-P-03, «не по правилам» |
| 5 | кнопка заполняет поля, но не отправляет | 4: UC-38-P-01 (экран, роутер), UC-38-P-03, «не по правилам» |
| 6 | логин и пароль перепутаны при подстановке | 4: UC-38-P-01 (экран, роутер), UC-38-P-03, «не по правилам» |
| 7 | поля заполнены, `signIn` мимо проверки полей | 3: UC-38-P-01, UC-38-P-03, «не по правилам» |
| 8 | «Тестовый вход» доступна во время отправки | 2: оба UC-38-P-01 на экране |
| 9 | после отказа поля очищаются | 1: UC-38-P-03 |
| 10 | провайдер: логин и пароль из `Env` перепутаны | 0 — ожидаемо, см. ниже |
| 11 | workflow: в `env` сборки нет `TEST_LOGIN_PASSWORD` | 1: UC-29-P-01, UC-38-P-01 |
| 12 | workflow: `TEST_LOGIN_USERNAME` из секрета `TEST_LOGIN_PASSWORD` | 1: UC-29-P-01, UC-38-P-01 |
| 13 | workflow: нет `--dart-define=TEST_LOGIN_USERNAME` | 2: UC-29-P-01, UC-38-P-01; UC-38-P-02 |
| 14 | workflow: `--dart-define=TEST_LOGIN_USERNAME="$TEST_LOGIN_PASSWORD"` | 1: UC-29-P-01, UC-38-P-01 |
| 15 | workflow: «Секреты заданы» требует секреты тестового входа | 2: UC-38-P-02 (workflow), UC-29-P-02 «оба секрета заданы» |
| 16 | workflow: «Секреты заданы» получает их в `env` и требует | 4: UC-38-P-02 (workflow), три UC-29-P-02 «не задан …» |
| 17 | workflow: `flutter build web … \|\| true` | 1: UC-29-P-02 «сборка упала» |

Порча 17 — обязательная из задания: до этого задания её не ловил ни один
тест (ACC-TASK-7-02).

Что тестом не проверить:

- Чтение параметров сборки: `Env` → `testAccountProvider`. Константу
  `String.fromEnvironment` тест не переопределит, а `flutter test` и `run`
  идут без `--dart-define`; тесты подменяют провайдер целиком. Порча 10
  выживает. Проверит сборка с параметрами — локальный запуск или сайт.
- Вид кнопки по теме — высота, форма, контур: тестов темы кнопок в проекте
  нет и для `filledButtonTheme`, `textButtonTheme`.

Проверит только настоящий сайт:

1. Секреты тестового входа заданы — на сайте под «Войти» кнопка «Тестовый
   вход», вход в настоящую учётную запись и переход (UC-38-P-01).
2. Секреты не заданы или удалены и сайт выложен заново — кнопки нет
   (UC-38-P-02).
3. Учётная запись удалена или пароль сменён — «Неверный логин или пароль.»
   от Supabase (UC-38-P-03).
4. Значения секретов в логе прогона не видны: GitHub маскирует, шаги их не
   печатают.
5. Упавшая на GitHub сборка не выкладывает `build/web` (UC-29-P-02) —
   тест проверяет код выхода шага и отсутствие `if` и `continue-on-error`.

## Не выполнено

Нет.

## Проверки

Локально, 2026-10-09, worktree `~/projects/yege_wars-TASK-8`, до коммита.

```
$ flutter pub get
Got dependencies!
$ flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
  Built with build_runner/aot in 4s; wrote 6 outputs.
$ flutter analyze --fatal-infos --fatal-warnings
No issues found! (ran in 4.7s)
$ dart run custom_lint
No issues found!
$ flutter test
00:12 +362: All tests passed!
$ find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' -print0 | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 199 files (0 changed) in 0.20 seconds.
format exit=0
$ bash supabase/tests/run_local.sh
NOTICE:  RLS TESTS PASSED
RLS OK
$ flutter build web --release --base-href /yege_wars/
Compiling lib/main.dart for the Web...                             22,8s
✓ Built build/web
$ python3 -m sdlc_tool views && python3 -m sdlc_tool check
Итог: 0 ошибок, 93 предупреждения
```

Тестов 362: 352 прежних и 10 новых. Сборка печатает и предупреждение о
шрифтах CupertinoIcons — было и до задания (ACC-TASK-7-01, находка 3).
Предупреждения `check` — те же 93, что в «Исходном состоянии» задания, все в
записях `sdlc/`.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — план СТОПа 0, 2026-10-09, вопросами с вариантами по
пунктам. Штатные механизмы, названные в плане: параметры сборки —
`String.fromEnvironment`, как `Env`; подмена в тестах — override провайдера
Riverpod, как подменяет репозитории `pumpApp`; кнопка-контур — Material
`OutlinedButton` с темой; workflow — `env` шага из `secrets`, как сейчас.

1. Где живут логин и пароль. Варианты: в `Env` — `testLoginUsername` и
   `testLoginPassword` (`String.fromEnvironment`, без значений по
   умолчанию); сущность ENT-17 — `TestAccount` в
   `lib/features/auth/domain/entities/test_account.dart` с
   `static TestAccount? fromBuild(...)` — `null`, если тестовый вход не
   задан; провайдер `testAccountProvider` (`@Riverpod(keepAlive: true)`) в
   `auth_providers.dart`; тест подставляет свои значения через
   `pumpApp(testAccount: …)`, который подменяет провайдер всегда, по
   умолчанию `null`; параметр конструктора `LoginScreen` — правка роутера.
   Последствие первого: строку «`Env` → провайдер» тест не видит. Выбрано:
   **`Env` + `TestAccount` + провайдер**.
2. Что считать «задан». Варианты: пустая строка — не задан, пробелы —
   задан, значение как есть, как `Env.isConfigured`; пробелы — тоже не задан
   (`trim`). Выбрано: **пустая — не задан**.
3. Как кнопка входит. Варианты: значения — в контроллеры полей, затем тот же
   `_submit()`: проверка полей, `signIn`, сообщения; не прошли проверку —
   ошибки под полями, запрос не уходит; `signIn` напрямую, мимо проверки
   полей. Выбрано: **через `_submit()`**.
4. Вид кнопки-контура. Место: под «Войти» `SizedBox(AppSpacing.sm)` и
   `OutlinedButton`, ниже — `SizedBox(sm)` и ссылка, как сейчас; ширина — от
   `stretch` карточки; пока идёт отправка — `onPressed: null`, индикатор
   только у «Войти». Вопрос — тема: своей темы кнопок-контуров в `AppTheme`
   нет. Варианты: `outlinedButtonTheme` в `AppTheme` с размером, отступами,
   формой и шрифтом, как у filled, — TOKEN-6, затронет «Копировать» в панели
   файлов задачи, `app_theme.dart` — сверх списка приёмки; тема Material по
   умолчанию — высота 40, «пилюля». Выбрано: **`outlinedButtonTheme` в
   `AppTheme`**.
5. Метки `UC-38`. Варианты: три места — dartdoc `LoginScreen` («Реализует
   UC-10, UC-38 и UC-1.»), `TestAccount` и `testAccountProvider`; только
   `LoginScreen`. Выбрано: **три места**.
6. Workflow. Варианты: в шаге «Сборка сайта» — два секрета в `env` и два
   `--dart-define=…="$…"` всегда, незаданный — пустая строка, кнопки нет;
   комментарий с `UC-38` над шагом; «Секреты заданы», шапка «Реализует
   UC-29.» и остальные шаги не меняются; с условием на bash — передавать,
   только когда секрет не пуст. Выбрано: **всегда, без условия**.
7. Тест на упавшую сборку (UC-29-P-02). Варианты: отдельный тест — шаг
   сборки с поддельным `flutter`, который выходит с кодом 1: `flutter`
   вызван, шаг завершился не 0; сборка в цикле `_checks` теста «упала
   проверка перед сборкой». Выбрано: **отдельный тест**.
8. Тесты. План: `login_screen_test.dart` — `UC-38-P-01` (подстановка, вход
   с этими значениями, при придержанном ответе «Тестовый вход» недоступна,
   у «Войти» индикатор, ссылка недоступна, после ответа — каталог),
   `UC-38-P-01` (отправка «Войти» — «Тестовый вход» недоступна),
   `UC-38-P-02` (оба пустые, только логин, только пароль — через
   `TestAccount.fromBuild` — кнопки нет), `UC-38-P-03` (отказ: сообщение,
   подставленные значения, экран входа); `app_router_test.dart`, группа
   «адрес после входа», — `UC-38-P-01`: после тестового входа — запомненный
   адрес; `deploy_workflow_test.dart` — `_expectSecretsEnv` со списком имён
   (у проверки два, у сборки четыре), «сборка по ENT-16» →
   `UC-29-P-01, UC-38-P-01` с четырьмя `--dart-define`, новый `UC-38-P-02`
   (тестовые секреты пустые — «Секреты заданы» код 0, сборка с пустыми
   `TEST_LOGIN_…=`), новый `UC-29-P-02` (п. 7); `pump_app.dart` — параметр
   `testAccount`. Нехолостость — скрипт в scratchpad, по одной порче за
   прогон всего `flutter test`, в том числе `flutter build web … || true`.
   Вопрос — тест «логин тестового входа не по правилам — ошибки у полей,
   запрос не ушёл» без метки пути. Варианты: план и этот тест; только план.
   Выбрано: **план и этот тест**.
9. README. План: «Локальный запуск» — ещё два `--dart-define` из
   `supabase/.env.local` и абзац «необязательны, без них кнопки нет»;
   «Деплой» — в «Один раз» необязательные секреты `TEST_LOGIN_USERNAME`,
   `TEST_LOGIN_PASSWORD`, «убрать — удалить секреты и выложить заново»,
   шаг 2 — «`SUPABASE_URL` и `SUPABASE_ANON_KEY` заданы», шаг 5 — четыре
   `--dart-define`; значений нет. Владелец переспросил, что значит «пароль
   виден в коде сайта»; объяснено: `--dart-define` вшивает значение в
   `main.dart.js`, его может прочитать любой посетитель (ENT-17), сам пароль
   нигде не выводится. Вопрос: добавлять ли в «Деплой» фразу-предупреждение
   об этом. Варианты: с предупреждением; без предупреждения. Выбрано:
   **без предупреждения**.

Ответы получены по всем 9 пунктам; первая правка кода — после них.

По ходу — выбор исполнителя там, где задание и план его не предписывали:

10. `fakeTestAccount` — в `test/helpers/fake_auth_repository.dart`, рядом с
    `testStudent`: им пользуются тесты экрана входа и роутера.
11. У `TestAccount` нет своего `toString`: пароль не попадёт в вывод тестов
    и логи при печати объекта.
12. Тест UC-38-P-01 на экране входа проверяет и недоступность «Войти»
    (`FilledButton.enabled`) — «обе кнопки недоступны» из UC-38-P-01.

На СТОПе 1:

13. 2026-10-09, вопрос: коммитить ли работу в `task/TASK-8` — коммит работы,
    затем отдельным коммитом сдача, без push. Варианты: коммитить; не
    коммитить. Выбрано: **коммитить**.

## Отступления от задания

1. `lib/app/theme/app_theme.dart` изменён — сверх списка файлов п. 2
   «Приёмки»: тема кнопок-контуров, решение владельца на СТОПе 0
   («Обсуждение», п. 4). Затронута и кнопка «Копировать» в панели файлов
   задачи («Выполнено», 1.1).

## Найдено вне задания

1. Темы кнопок тестами не закреплены: в `test/app/theme/app_theme_test.dart`
   4 теста — яркость, фон, `primary`, Material 3. Размер, форма и отступы
   `filledButtonTheme`, `textButtonTheme` и нового `outlinedButtonTheme`
   можно испортить, не уронив ни одного теста.
