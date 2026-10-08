# RESULT-TASK-3-01: Адрес, открытый без входа, — после входа и регистрации

## Задание

[TASK-3](../4-tasks/TASK-3-ADDRESS-AFTER-SIGN-IN.md).

## Коммит работы

`1e79eb4` — «TASK-3: адрес, открытый без входа, — после входа и
регистрации», ветка `task/TASK-3`, после «да» владельца на СТОПе 1
(«Обсуждение», п. 9). Производные файлы в этом коммите собраны без сдачи;
сдача и производные файлы с ней — отдельным коммитом.

```
1e79eb4bede43c561a3ec7275688dfe5cafc72c1
TASK-3: адрес, открытый без входа, — после входа и регистрации

 lib/app/router/app_router.dart                     | 117 ++++++++---
 lib/app/router/app_routes.dart                     |   5 +-
 .../auth/domain/use_cases/sign_out_use_case.dart   |   2 +-
 .../domain/use_cases/watch_auth_user_use_case.dart |   2 +-
 .../presentation/controllers/auth_controller.dart  |   2 +-
 .../auth/presentation/screens/login_screen.dart    |  15 +-
 .../auth/presentation/screens/register_screen.dart |  16 +-
 .../presentation/screens/profile_screen.dart       |   2 +-
 sdlc/2-specs/use-cases/INDEX.md                    |   6 +-
 test/app/router/app_router_test.dart               | 224 ++++++++++++++++++++-
 .../auth/presentation/auth_controller_test.dart    |   6 +-
 .../auth/presentation/login_screen_test.dart       |   2 +-
 .../auth/presentation/register_screen_test.dart    |  45 ++++-
 test/features/profile/profile_screen_test.dart     |  25 ++-
 test/helpers/pump_app.dart                         |   6 +
 15 files changed, 425 insertions(+), 50 deletions(-)
```

## Выполнено

Устройство — по плану СТОПа 0; все восемь пунктов владелец принял
(«Обсуждение», пп. 1–8).

- **1.1. Адрес запоминается и открывается.** `lib/app/router/app_router.dart`:
  - `_guard` получает адрес открытой страницы `openLocation` — в `redirect`
    это `GoRouter.of(context).routerDelegate.currentConfiguration.uri`. Без
    входа на любом адресе приложения, кроме входа, регистрации и заставки, —
    `/login?from=<адрес целиком, с параметрами>`, в том числе для `/`
    (`from=%2F`, п. 7).
  - Заставка без входа: `from` — страница входа или регистрации → она как
    есть, со своим `from` (п. 6); иначе `/login?from=<from заставки без
    изменений>`; `from` нет — `/login`.
  - `_restoredLocation`: `from` годен, если `Uri.tryParse` разбирает его без
    схемы и хоста, путь начинается с `/` и не служебный (`/login`,
    `/register`, `/splash`); тогда возвращается целиком, иначе — главная
    (п. 4). Ветка «вошёл» не менялась: с входа, регистрации и заставки — на
    годный `from` или главную; ученика с `/admin` — в каталог.
  - Адрес с `from` собирает `_locationWithFrom` вместо `_splashLocation`;
    маршруты входа и регистрации передают `from` в конструктор экрана (п. 3).
  - `LoginScreen` и `RegisterScreen` — параметр `from`; ссылки «Нет аккаунта?
    Зарегистрируйтесь» и «Уже есть аккаунт? Войдите» —
    `goNamed(…, queryParameters: {from})`, если `from` есть. Тексты экранов не
    менялись.
- **1.2. Конец сессии на странице.** После «Выйти» и при `null` из потока
  сессии роутер перепроверяет открытую страницу; проверяемый адрес совпадает с
  открытым, и `_guard` ведёт на `/login` без `from` (п. 1). Следующий вход
  открывает главную. `AuthState` и `AuthController` по поведению не менялись.
- **1.3. Метки.** `UC-11` → `UC-13` в doc-комментариях `app_router.dart`,
  `auth_controller.dart`, `sign_out_use_case.dart`,
  `watch_auth_user_use_case.dart`, `profile_screen.dart`. `UC-11-P-0x` →
  `UC-13-P-0x` в шести описаниях тестов, тела не менялись. Метка `UC-10-P-01`
  — тестам «без авторизации любой путь ведёт на вход» и «успешный вход ведёт
  в каталог», `UC-1-P-01` — «успешная регистрация ведёт в каталог»; у
  первого и третьего строка объявления перенесена по `dart format`: с меткой
  она длиннее 80 колонок. `UC-1` добавлен в doc-комментарий `LoginScreen`,
  `UC-10` — `RegisterScreen`, `UC-10` и `UC-1` — `AppRoutes.fromQueryParam`.
- Помощник `currentLocation(tester)` в `test/helpers/pump_app.dart` — адрес
  открытой страницы (п. 5). Новых тестов 13: 10 в `app_router_test.dart`, 2 в
  `register_screen_test.dart`, 1 в `profile_screen_test.dart`; всего тестов
  было 278, стало 291.

Пути «Основания» и тесты с их меткой (имена — как в прогоне, с группой):

| Путь | Тест | Тест новый или с новой меткой |
|---|---|---|
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `UC-10-P-01: без авторизации любой путь ведёт на вход` | метка добавлена |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: адрес, открытый без входа, открывается после входа` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: адрес, открытый до проверки сессии, когда сессии нет, открывается после входа` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: путь с параметрами запроса сохраняется целиком` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: без входа на главной вход получает её адрес` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: негодные адреса после входа ведут на главную` (`//example.com`, `/\example.com`, `/login`) | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01: адрес переживает перезагрузку страницы входа` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01), [UC-5-P-02](../2-specs/use-cases/UC-5-ACTOR-2-EVT-5-ENT-2-SECTION-SHOWN-IN-AUTH.md#uc-5-p-02) | `test/app/router/app_router_test.dart`: `адрес после входа UC-10-P-01, UC-5-P-02: ученик с адресом админки после входа попадает в каталог` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/app/router/app_router_test.dart`: `адрес после конца сессии UC-10-P-01: после конца сессии адрес, открытый заново без входа, запоминается` | новый |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/features/auth/presentation/login_screen_test.dart`: `UC-10-P-01: успешный вход ведёт в каталог` | метка добавлена |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | `test/features/auth/presentation/register_screen_test.dart`: `UC-10-P-01: ссылка с регистрации на вход сохраняет адрес` | новый |
| [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) | `test/app/router/app_router_test.dart`: `адрес после входа UC-1-P-01: адрес переживает перезагрузку страницы регистрации` | новый |
| [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) | `test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-01: адрес переходит со входа на регистрацию и открывается после регистрации` | новый |
| [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) | `test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-01: успешная регистрация ведёт в каталог` | метка добавлена |
| [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) | `test/features/auth/presentation/auth_controller_test.dart`: `действия пользователя UC-13-P-01: выход возвращает в unauthenticated` | метка `UC-11-P-01` → `UC-13-P-01` |
| [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) | `test/features/profile/profile_screen_test.dart`: `UC-13-P-01: кнопка «Выйти» возвращает на экран входа` | метка `UC-11-P-01` → `UC-13-P-01` |
| [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) | `test/features/profile/profile_screen_test.dart`: `UC-13-P-01: после «Выйти» адрес профиля не запоминается — следующий вход открывает главную` | новый |
| [UC-13-P-02](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-02) | `test/features/auth/presentation/auth_controller_test.dart`: `действия пользователя UC-13-P-02: ошибка выхода сохраняет вход` | метка `UC-11-P-02` → `UC-13-P-02` |
| [UC-13-P-02](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-02) | `test/features/profile/profile_screen_test.dart`: `UC-13-P-02: ошибка выхода показывается сообщением` | метка `UC-11-P-02` → `UC-13-P-02` |
| [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03) | `test/app/router/app_router_test.dart`: `UC-10-P-05, UC-13-P-03: после входа открывается каталог, после выхода — вход` | метка `UC-11-P-03` → `UC-13-P-03` |
| [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03) | `test/app/router/app_router_test.dart`: `адрес после конца сессии UC-13-P-03: сессия закончилась на открытой странице — адрес не запоминается, следующий вход открывает главную` | новый |
| [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03) | `test/features/auth/presentation/auth_controller_test.dart`: `подписка на сессию UC-13-P-03: выход из аккаунта в другой вкладке сбрасывает состояние` | метка `UC-11-P-03` → `UC-13-P-03` |

Путей «Основания» без тестов — нет.

## Не выполнено

Нет.

## Проверки

Локально, worktree `task/TASK-3`, 2026-10-08.

### До правок

После `flutter pub get`, `flutter gen-l10n` и
`dart run build_runner build --delete-conflicting-outputs` (код 0)
`flutter test` на исходном коде ветки (последняя строка), код 0:

```
00:12 +278: All tests passed!
```

### Проверки части 1

Каждая команда «Проверок части 1» по очереди, полными путями к Flutter и
Dart. Подготовка — `flutter pub get`, `flutter gen-l10n`,
`dart run build_runner build --delete-conflicting-outputs` — код 0.

`flutter analyze --fatal-infos --fatal-warnings` (список доступных
обновлений пакетов опущен), код 0:

```
Analyzing yege_wars-TASK-3...
No issues found! (ran in 3.1s)
```

`dart run custom_lint`, код 0:

```
Analyzing...

No issues found!
```

`flutter test` (последняя строка), код 0:

```
00:09 +291: All tests passed!
```

`find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' -print0 | xargs -0 dart format --output=none --set-exit-if-changed`,
код 0:

```
Formatted 190 files (0 changed) in 0.17 seconds.
```

`python3 -m sdlc_tool views && python3 -m sdlc_tool check`, код 0:

```
обновлено: sdlc/2-specs/use-cases/INDEX.md
ПРЕДУПРЕЖДЕНИЕ sdlc/4-tasks/TASK-1-LABELS-AUTH.md:13: ссылается на похороненный UC-11-P-01 — к пересмотру
ПРЕДУПРЕЖДЕНИЕ sdlc/4-tasks/TASK-1-LABELS-AUTH.md:13: ссылается на похороненный UC-11-P-02 — к пересмотру
ПРЕДУПРЕЖДЕНИЕ sdlc/4-tasks/TASK-1-LABELS-AUTH.md:13: ссылается на похороненный UC-11-P-03 — к пересмотру
ПРЕДУПРЕЖДЕНИЕ sdlc/5-results/RESULT-TASK-1-01.md:230: ссылается на похороненный UC-11-P-01 — к пересмотру
ПРЕДУПРЕЖДЕНИЕ sdlc/5-results/RESULT-TASK-1-01.md:231: ссылается на похороненный UC-11-P-02 — к пересмотру
ПРЕДУПРЕЖДЕНИЕ sdlc/5-results/RESULT-TASK-1-01.md:232: ссылается на похороненный UC-11-P-03 — к пересмотру
Итог: 0 ошибок, 6 предупреждений
```

### Новые тесты не холостые

По п. 8 «Обсуждения». Правки временные: файлы сохранялись в копию в
scratchpad, возвращались и сверялись `cmp` — различий нет. После обоих
возвратов `flutter test` (последняя строка), код 0:
`00:09 +291: All tests passed!`.

1. **Код `lib/` из `main`.** Все восемь изменённых файлов `lib/` взяты из
   `main` (`git show main:<файл> > <файл>`); `git diff --stat main -- lib` во
   время прогона — пусто. Прогон
   `flutter test --reporter expanded test/app/router/app_router_test.dart test/features/auth/presentation/register_screen_test.dart test/features/profile/profile_screen_test.dart`,
   код 1; упавшие тесты (путь к worktree опущен):

   ```
   00:01 +17 -1: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: адрес, открытый без входа, открывается после входа [E]
   00:01 +18 -2: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: адрес, открытый до проверки сессии, когда сессии нет, открывается после входа [E]
   00:01 +18 -3: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: путь с параметрами запроса сохраняется целиком [E]
   00:01 +18 -4: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: без входа на главной вход получает её адрес [E]
   00:01 +18 -5: test/features/auth/presentation/register_screen_test.dart: UC-1-P-01: адрес переходит со входа на регистрацию и открывается после регистрации [E]
   00:01 +18 -6: test/features/auth/presentation/register_screen_test.dart: UC-10-P-01: ссылка с регистрации на вход сохраняет адрес [E]
   00:01 +18 -7: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: негодные адреса после входа ведут на главную [E]
   00:01 +18 -8: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01: адрес переживает перезагрузку страницы входа [E]
   00:01 +18 -9: test/app/router/app_router_test.dart: адрес после входа UC-1-P-01: адрес переживает перезагрузку страницы регистрации [E]
   00:02 +18 -10: test/app/router/app_router_test.dart: адрес после входа UC-10-P-01, UC-5-P-02: ученик с адресом админки после входа попадает в каталог [E]
   00:02 +19 -11: test/app/router/app_router_test.dart: адрес после конца сессии UC-10-P-01: после конца сессии адрес, открытый заново без входа, запоминается [E]
   00:02 +19 -11: Some tests failed.
   ```

   Причины — фактические значения: адрес `/login` или `/register` без
   `from`; у «перезагрузки страницы регистрации» — экрана регистрации нет
   (заставка увела на вход); у «негодных адресов» — `'//example.com/'`:
   прежний `_restoredLocation` пропускал `//example.com`, и после входа
   открывался этот адрес. Новые тесты
   [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01)
   и [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03)
   на коде `main` проходят: там этот путь уже выполняется.
2. **Мутация `_guard`.** Из `lib/app/router/app_router.dart` временно убрана
   ветка «сессия закончилась на открытой странице»:

   ```diff
   @@ -172,10 +172,6 @@
          if (path == AppRoutes.splash) {
            return _signInLocationAfterSplash(state);
          }
   -      // Открытая страница без входа: сессия закончилась на ней.
   -      if (state.uri == openLocation) {
   -        return AppRoutes.login;
   -      }
          return _locationWithFrom(AppRoutes.login, state.uri.toString());
   ```

   Прогон `flutter test --reporter expanded --plain-name 'UC-13-P-0' test/app/router/app_router_test.dart test/features/profile/profile_screen_test.dart`,
   код 1; строки `Expected` и `Actual` и итоговые строки упавших тестов по
   порядку (путь к worktree опущен):

   ```
   Expected: '/login'
     Actual: '/login?from=%2Ftask%2Fe24-longest-run'
   00:00 +3 -1: test/app/router/app_router_test.dart: адрес после конца сессии UC-13-P-03: сессия закончилась на открытой странице — адрес не запоминается, следующий вход открывает главную [E]
   Expected: '/login'
     Actual: '/login?from=%2Fprofile'
   00:01 +3 -2: test/features/profile/profile_screen_test.dart: UC-13-P-01: после «Выйти» адрес профиля не запоминается — следующий вход открывает главную [E]
   00:01 +3 -2: Some tests failed.
   ```

### Самопроверка по «Приёмке»

1. Проверки Dart — выше, «Проверки части 1»: 291 тест (278 и 13 новых);
   нехолостость — выше.
2. `python3 -m sdlc_tool run --allow-dirty --root <клон>` — в клоне ветки
   `task/TASK-3` в scratchpad с перенесёнными незакоммиченными правками
   worktree (почему не в worktree — «Отступления от задания»). HEAD клона и
   worktree — `0f43dbe`; `diff -r` клона и worktree без `.git`, сборки и
   сгенерированного — пусто. Вывод, код 0:

   ```
   pub_get: flutter pub get …
   pub_get: PASS
   gen_l10n: flutter gen-l10n …
   gen_l10n: PASS
   build_runner: dart run build_runner build --delete-conflicting-outputs …
   build_runner: PASS
   analyze: flutter analyze --fatal-infos --fatal-warnings …
   analyze: PASS
   custom_lint: dart run custom_lint …
   custom_lint: PASS
   format: dart format --output=none --set-exit-if-changed <.dart из lib/ и test/ без *.g.dart и lib/l10n/gen/> …
   format: PASS
   flutter_test: flutter test --reporter json …
   flutter_test: PASS
   rls: bash supabase/tests/run_local.sh …
   rls: PASS
   tools_tests: python3 -m unittest discover -s tools/tests -t . …
   tools_tests: PASS
   sdlc_tool_tests: python3 -m unittest discover -s sdlc_tool/tests -t . …
   sdlc_tool_tests: PASS
   прогон: sdlc/6-eval/auto/2026-10-08-0f43dbe/
   Итог: PASS 10, FAIL 0, BLOCKED 0, пропущено 0 — код 0
   обновлено: sdlc/1-business-tasks/planning/INDEX.md
   обновлено: sdlc/2-specs/use-cases/INDEX.md
   обновлено: sdlc/6-eval/DASHBOARD.md
   ```

   В `summary.json` прогона пути «Основания» — `PASS`: UC-10-P-01 (11
   тестов), UC-1-P-01 (3), UC-13-P-01 (3), UC-13-P-02 (2), UC-13-P-03 (3);
   остальные 25 путей — `PASS`. `DASHBOARD.md` клона:
   `Итого путей: PASS 30, FAIL 0, BLOCKED 0, НЕ ПРОВЕРЕНО 0.` Бизнес-задачи
   в `1-business-tasks/planning/INDEX.md` клона:

   ```
   | [BT-1](BT-1-PLANNING-REGISTRATION.md) | Регистрация по логину | … | да |
   | [BT-2](BT-2-PLANNING-SIGN-IN.md) | Вход, выход и сессия | … | да |
   | [BT-7](BT-7-PLANNING-SESSION-END.md) | Конец сессии — следующий вход с главной | … | да |
   ```

3. `check` — выше: 0 ошибок; предупреждений о метках `UC-11` нет, остались 6
   о записях TASK-1 и RESULT-TASK-1-01.
4. По коду — `lib/app/router/app_router.dart`: с заставки `from` уходит на
   вход без изменений или открывает сохранённую страницу входа и
   регистрации (`_signInLocationAfterSplash`); с любого адреса без входа —
   `/login?from=…` (`_guard`); ссылки экранов несут `from` дальше. После
   «Выйти» и при `null` из потока сессии — `/login` без `from` (ветка
   `state.uri == openLocation`). `//…`, `/\…` и служебные пути отсекает
   `_restoredLocation` через `_internalUri` и `_servicePaths`. Каждое —
   тестами из таблицы «Выполнено».
5. `git diff --stat main...task/TASK-3` после коммита работы — те же 15
   файлов, что в «Коммите работы»: `lib/` — 8, `test/` — 6, в `sdlc/` —
   производный `2-specs/use-cases/INDEX.md`. Коммит сдачи добавляет сдачу и
   производные `4-tasks/INDEX.md` и `5-results/INDEX.md`.
6. Сдача — по составу `sdlc/5-results/AGENTS.md`; хэш в «Коммите работы» —
   из `git show` выше.

Ответов задач, эталонов и значений переменных окружения в сдаче и в
`git diff main` нет:
`git diff main | grep -i -E "sb_publishable_|sb_secret_|supabase\.co|postgres(ql)?://|SEED_DATABASE_URL=|SUPABASE_ANON_KEY=|password=|eyJ[a-zA-Z0-9_-]{10,}"`
и то же по сдаче — без вывода, код 1.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — план решений СТОПа 0, вопросы владельцу 2026-10-08. Ответ
записывается под пунктом, как пришёл.

1. Как роутер отличает «сессия закончилась на открытой странице» (адрес не
   запоминать) от «страницу открыли без входа» (запомнить). Штатно в
   go_router 17.5.0: `redirect` с `refreshListenable` (уже в проекте) не
   сообщает, почему вызван; `onEnter` получает открытую страницу
   (`currentState`, берётся из `routerDelegate.currentConfiguration`) и
   целевую. Варианты:
   - а) `_guard` сверяет проверяемый адрес с адресом открытой страницы
     (`routerDelegate.currentConfiguration`, тот же источник, что у
     `onEnter`). Открытую страницу роутер перепроверяет по смене состояния
     входа; без входа «проверяемая = открытая» — сессия закончилась на ней:
     `/login`. Иначе — `/login?from=…`. Всё в `_guard`; `AuthState` и
     `AuthController` не меняются. «Назад» после «Выйти» и адрес, набранный в
     той же вкладке (адреса приложения — после `#`, браузер страницу не
     перезагружает), — открытие без входа, запоминаются.
   - б) Поле `AuthUnauthenticated.sessionEnded`: контроллер ставит его на
     `signOut` и на `null` из потока после входа, `_guard` с ним не добавляет
     `from`. Меняются домен и контроллер. Поле живёт до входа или
     перезагрузки: «Назад» и набранный адрес в той же вкладке не
     запоминаются.
   - в) Слушатель роутера (`ref.listen`, прежнее → новое состояние): на
     «вошёл → не вошёл» роутер сам делает `go('/login')`, `_guard` всегда
     добавляет `from`. Поведение как у (а), решение «куда без входа» — в двух
     местах.
   - г) Охрана в `onEnter` вместо `redirect`: `onEnter` не возвращает адрес —
     только `Block` и `router.go` в микрозадаче; при первом открытии
     `currentState` равен `nextState`. Охрана переписывается целиком.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — сверка с открытой страницей**.
2. Где формируется `/login?from=…`. Варианты:
   - а) Только в `_guard`: защищённая страница без входа →
     `/login?from=<адрес целиком, с параметрами>`; заставка → вход — по п. 6.
     Адрес собирает один помощник на `Uri(path, queryParameters)` вместо
     `_splashLocation`. Кроме того, ссылка «Уже есть аккаунт? Войдите» несёт
     текущий `from` (п. 3); больше нигде.
   - б) Общий построитель в `AppRoutes` для `_guard` и экранов; экраны
     переходят через `context.go(…)` вместо `goNamed`.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — только `_guard`**.
3. Как ссылки между входом и регистрацией берут текущий `from`. Штатно:
   `state.uri.queryParameters` в построителе маршрута,
   `GoRouterState.of(context)` в виджете. Варианты:
   - а) Построитель маршрута передаёт `from` в конструктор: `LoginScreen(from:
     …)`, `RegisterScreen(from: …)` — как `TaskScreen(slug: …)`. Ссылка —
     `goNamed(…, queryParameters: {from})`, если `from` есть; без проверки.
   - б) Экран сам читает `GoRouterState.of(context).uri.queryParameters`;
     конструкторы не меняются, экран зависит от состояния роутера.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — параметр конструктора**.
4. Как `_restoredLocation` проверяет, что адрес внутренний. Штатно —
   `Uri.tryParse` Dart. Проверено на Dart SDK проекта: `//example.com` и
   `/\example.com` разбираются с `hasAuthority: true` (`\` Dart читает как
   `/`). Варианты:
   - а) `Uri.tryParse(from)`: годен, если нет схемы и хоста, путь начинается
     с `/` и не `/login`, `/register`, `/splash`; иначе главная. Возвращается
     `from` целиком.
   - б) Строковое правило из «Решений» (первый символ `/`, второй не `/` и не
     `\`), путь для служебных — через `Uri.tryParse`.
   - в) Оба: строковое правило, затем `Uri.tryParse` без схемы и хоста.

   Проверка — только при открытии адреса (после входа, регистрации и после
   заставки с сессией), не при сборке `/login?from=…`. Вошедший на
   `/login?from=X` уходит на X — как сейчас. Рекомендация — (а). Ответ владельца
   2026-10-08: **(а) — `Uri.tryParse`**.
5. Что меняется в коде и тестовых помощниках. Код: `app_router.dart`
   (`_guard`, `_restoredLocation`, `from` в экраны входа и регистрации,
   метки); `app_routes.dart` (doc-комментарий `fromQueryParam`, метки);
   `login_screen.dart`, `register_screen.dart` (`from`, ссылки, метки `UC-10`
   и `UC-1`); метки `UC-11` → `UC-13` в `auth_controller.dart`,
   `sign_out_use_case.dart`, `watch_auth_user_use_case.dart`,
   `profile_screen.dart`; `auth_state.dart` не меняется. Тесты: новые — в
   `app_router_test.dart` ([UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01), [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03), ученик с адресом
   `/admin` после входа — в каталог), `register_screen_test.dart`
   ([UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01); ссылка обратно на вход несёт `from`),
   `profile_screen_test.dart` ([UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01)); перемаркировка по 1.3. Варианты
   для помощников:
   - а) В `pump_app.dart` — `currentLocation(tester)`: адрес открытой
     страницы; `FakeAuthRepository` без правок.
   - б) Помощники не меняются, тесты читают адрес у роутера сами.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — как в плане, с `currentLocation`**.
6. Перезагрузка страницы входа с `from`. Заставка хранит адрес целиком:
   `/splash?from=/login?from=X`. Если `from` заставки по букве уходит на вход
   без изменений, вход получает `from=/login?from=X` — служебный (п. 4), и
   после входа открывается главная: адрес теряется. Варианты:
   - а) Без входа: `from` заставки — страница входа или регистрации → открыть
     её как есть; иначе `/login?from=<from заставки без изменений>`. С
     сессией — как сейчас: служебный адрес → главная ([UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05)).
     Перезагрузка регистрации остаётся на регистрации (сейчас уводит на
     вход).
   - б) На страницах входа и регистрации заставка запоминает их `from` (X).
     Без входа → `/login?from=X`; с сессией → X вместо главной — расходится с
     [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05) «с /login и /register — на главную».
   - в) По букве: адрес при перезагрузке страницы входа теряется.

   Так же и при [UC-10-P-06](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-06): вход с ошибкой и с `from`. Рекомендация — (а).
   Ответ владельца 2026-10-08: **(а) — вернуть страницу входа или регистрации как есть**.
7. `from` для корня `/`. Варианты:
   - а) Как у любого адреса: `/login?from=%2F` — буква 1.1, заставка уже
     пишет `/splash?from=%2F`.
   - б) Для `/` без `from`: адрес чище, итог тот же — главная.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — как любой адрес**.
8. Холостые ли новые тесты [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) и [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03): на коде `main` они
   проходят — [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) там уже выполняется («Исходное состояние»).
   Варианты:
   - а) [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) и [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) — возвратом кода из `main`; [UC-13](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md) — временно
     убрать в `_guard` ветку «сессия закончилась на странице»: падают;
     вернуть. Оба вывода — в сдачу.
   - б) Только возврат кода из `main`; для [UC-13](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md) записать, что они проходят.

   Рекомендация — (а). Ответ владельца 2026-10-08: **(а) — мутацией `_guard`**.

По ходу:

9. 2026-10-08, СТОП 1. Вопрос: коммитить работу в `task/TASK-3`?
   Варианты: коммитить; сначала ревью агентами (workflow из трёх агентов),
   потом решение; не коммитить. Выбрано: **коммитить**.

Выбор исполнителя там, где задание и план его не предписывали:

10. Адрес открытой страницы в `redirect` берётся через
    `GoRouter.of(context)`: на время `redirect` go_router кладёт роутер в
    зону. Ссылки на роутер из провайдера (`late`) не понадобилось.
11. Ссылки экранов собирают параметры записью
    `{AppRoutes.fromQueryParam: ?widget.from}` — null-aware элемент Dart 3.8
    (SDK проекта `^3.11.0`): без `from` параметра в адресе нет.
12. Заставка открывает сохранённую страницу входа или регистрации как есть,
    только если `from` — путь внутри приложения (`_internalUri`). Адрес с
    хостом (`//хост/login`) уходит в `from` экрана входа без изменений и
    отсекается при открытии.
13. Тест «ученик с адресом админки после входа попадает в каталог» помечен
    `UC-10-P-01, UC-5-P-02`: он проверяет правило ролей после входа с
    запомненным адресом.
14. Сверх перечня тестов задания — «без входа на главной вход получает её
    адрес» (п. 7) и «после конца сессии адрес, открытый заново без входа,
    запоминается» (следствие п. 1): закрепляют принятые решения.
15. Вход в тестах роутера — через форму (`signInWithForm`, помощник внутри
    `app_router_test.dart`), в тесте профиля — так же, строками теста. Общих
    помощников сверх `currentLocation` нет (п. 5): ожидаемые адреса в
    `register_screen_test.dart` — строками (`/register?from=%2Fprofile`), в
    `app_router_test.dart` — помощником файла `_withFrom`.

## Отступления от задания

- Самопроверка пункта 2 «Приёмки»: `run` выполнен не в worktree, а в клоне
  ветки `task/TASK-3` в scratchpad с теми же незакоммиченными правками. `run`
  пишет папку прогона в `sdlc/6-eval/auto/`, а задание запрещает менять в
  `sdlc/` что-либо, кроме своей сдачи и производных файлов. Так же сделано в
  [RESULT-TASK-2-01](RESULT-TASK-2-01.md).

## Найдено вне задания

1. `sdlc_tool run` считает в строке «Тесты: PASS N» (`summary.md`, `totals` в
   `summary.json`) записи «тест — метка»: тест с двумя метками входит дважды.
   Прогон `2026-10-08-fd7156a` на `main`: 301 — это 279 записей Dart на 278
   тестов и 22 записи SQL-меток. Прогон этой сдачи в клоне: 315 — 293 записи
   Dart на 291 тест и 22 записи SQL-меток. Число тестов в задании и в сдаче —
   по `flutter test`.
2. Тест `пока сессия не проверена, показывается заставка`
   (`test/app/router/app_router_test.dart`) проверяет начало
   [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01)
   — заставку, пока сессия не проверена, затем вход, — но метки не имеет. В
   перечне 1.3 его нет, не трогал.
