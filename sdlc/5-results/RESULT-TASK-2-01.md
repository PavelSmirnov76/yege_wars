# RESULT-TASK-2-01: Адрес проекта и публичный ключ — из параметров сборки

## Задание

[TASK-2](../4-tasks/TASK-2-BUILD-CONFIG.md).

## Коммит работы

`f63f9ce` — «TASK-2: адрес проекта и публичный ключ — только из параметров
сборки».

```
f63f9ced277441be3eff628d23e36f94fa52ece9
TASK-2: адрес проекта и публичный ключ — только из параметров сборки

 README.md                       |  9 +++--
 lib/app/bootstrap.dart          |  4 +++
 lib/app/not_configured_app.dart |  1 +
 lib/core/config/env.dart        | 37 ++++++---------------
 sdlc/2-specs/use-cases/INDEX.md |  2 +-
 test/app/bootstrap_test.dart    | 74 ++++++++++++++++++++++++++++++++++-------
 test/main_test.dart             | 26 +++++++++++++++
 7 files changed, 112 insertions(+), 41 deletions(-)
```

## Выполнено

- **1.1.** В `lib/core/config/env.dart` удалены `_defaultSupabaseUrl` и
  `_defaultSupabaseAnonKey`; `supabaseUrl` и `supabaseAnonKey` —
  `String.fromEnvironment` без значений по умолчанию. Doc-комментарий класса:
  значения только из `--dart-define`, локально — из `supabase/.env.local`,
  команда запуска — README. `bootstrap` и заглушка по поведению не менялись.
- **1.2.** Тест «по умолчанию адрес и ключ проекта заданы в коде» перевёрнут:
  `UC-12-P-02: без параметров сборки адреса и ключа проекта нет` — пустые
  `Env.supabaseUrl` и `Env.supabaseAnonKey`, `Env.isConfigured` — `false`. Без
  правки 1.1 падает (вывод — «Проверки», пункт 3). Тест
  `UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку`
  вызывает `bootstrap()` без аргументов — решение владельца, см.
  «Обсуждение». Добавлены тесты P-01 и P-03 (без сети) и тест запуска
  `main()` без параметров сборки (`test/main_test.dart`). `UC-12` — в
  doc-комментариях `bootstrap` и `NotConfiguredApp`.
- **1.3.** README, «Локальный запуск»: команда из «Решений» задания —
  `set -a; . supabase/.env.local; set +a`, затем `flutter run -d chrome` с
  `--dart-define=SUPABASE_URL="$SUPABASE_URL"` и
  `--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"`. Значений нет.

Пути UC-12 и тесты с их меткой:

| Путь | Тест |
|---|---|
| [UC-12-P-01](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md#uc-12-p-01) | `test/app/bootstrap_test.dart`: `UC-12-P-01: с адресом и ключом bootstrap поднимает Supabase` |
| [UC-12-P-02](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md#uc-12-p-02) | `test/app/bootstrap_test.dart`: `UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку`, `UC-12-P-02: без параметров сборки адреса и ключа проекта нет`, `UC-12-P-02: заглушка объясняет, чего не хватает`; `test/main_test.dart`: `UC-12-P-02: без параметров сборки приложение показывает экран «не сконфигурировано» с причиной` |
| [UC-12-P-03](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md#uc-12-p-03) | `test/app/bootstrap_test.dart`: `UC-12-P-03: Supabase не поднялся — bootstrap возвращает ошибку подключения`, `UC-12-P-03: заглушка показывает переданные подробности` |

Пути без тестов — нет. P-01 и P-03 проверены без сети: тесты Flutter идут под
`TestWidgetsFlutterBinding` (`test/flutter_test_config.dart`), который
подменяет HTTP ответом 400; `Supabase.initialize` (supabase_flutter 2.17.2)
без сохранённой сессии к проекту не обращается. P-01 проверен на уровне
`bootstrap`: шаг «`main` запускает `YegeWarsApp`» тестом не покрыт — `Env`
задаётся при компиляции, а тесты идут без `--dart-define`; этот шаг показан
запуском сборки с параметрами («Проверки», пункт 5).

## Не выполнено

Нет.

## Проверки

Локально, worktree `task/TASK-2`, 2026-10-08. Подготовка: `flutter pub get`,
`flutter gen-l10n`, `dart run build_runner build --delete-conflicting-outputs`
— без ошибок.

### Проверки части 1 — первый прогон, стоп-условие

`flutter analyze --fatal-infos --fatal-warnings` (список доступных обновлений
пакетов опущен), код 1:

```
Analyzing yege_wars-TASK-2...

   info • The value of the argument is redundant because it matches the default value • test/app/bootstrap_test.dart:22:43 • avoid_redundant_argument_values
   info • The value of the argument is redundant because it matches the default value • test/app/bootstrap_test.dart:22:56 • avoid_redundant_argument_values

2 issues found. (ran in 4.4s)
```

Строка 22 — `bootstrap(url: '', anonKey: '')`: без значений по умолчанию `''`
совпадает с умолчанием параметров `bootstrap`. Работа остановлена, вопрос —
владельцу, см. «Обсуждение». Остальные проверки этого прогона прошли.

### Проверки части 1 — после решения владельца

`flutter analyze --fatal-infos --fatal-warnings`, код 0:

```
Analyzing yege_wars-TASK-2...
No issues found! (ran in 2.8s)
```

`dart run custom_lint`, код 0:

```
Analyzing...

No issues found!
```

`flutter test` (последняя строка), код 0:

```
00:09 +274: All tests passed!
```

`find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' -print0 | xargs -0 dart format --output=none --set-exit-if-changed`,
код 0:

```
Formatted 190 files (0 changed) in 0.17 seconds.
```

`flutter build web --release` без параметров (последняя строка), код 0:

```
✓ Built build/web
```

`git grep -n -E 'sb_publishable_[A-Za-z0-9_-]{8,}|[a-z0-9]{20}\.supabase\.co' -- lib test README.md`
— вывода нет, код 1; с `--untracked` (новый `test/main_test.dart`) — так же.
По тому же выражению в `build/web/main.dart.js` — 0 совпадений.

`python3 -m sdlc_tool views` и `python3 -m sdlc_tool check`:

```
Итог: 0 ошибок, 0 предупреждений
```

### Самопроверка по «Приёмке»

1. Полный набор проверок Dart и `flutter build web --release` без параметров —
   выше, «после решения владельца».
2. `git grep` по `lib/`, `test/`, `README.md` — выше, вывода нет.
3. Перевёрнутый тест без правки 1.1: `env.dart` временно взят из `HEAD`,
   тогда `a6ac60a`
   (`git show HEAD:lib/core/config/env.dart > lib/core/config/env.dart`),
   затем возвращён и сверен `cmp`.
   `flutter test --timeout=90s test/app/bootstrap_test.dart --plain-name 'UC-12-P-02: без параметров сборки адреса и ключа проекта нет'`
   (значение адреса заменено на `***`; строки `pub get`, загрузки и
   подсказка повторного запуска опущены):

   ```
   00:00 +0 -1: UC-12-P-02: без параметров сборки адреса и ключа проекта нет [E]
     Expected: empty
       Actual: '***'
     package:matcher                                     expect
     package:flutter_test/src/widget_tester.dart 473:18  expect
     test/app/bootstrap_test.dart 30:5                   main.<fn>
   00:00 +0 -1: Some tests failed.
   ```

4. `check` — выше, 0 ошибок. `python3 -m sdlc_tool run --allow-dirty --root <копия>`
   — в клоне ветки `task/TASK-2` в scratchpad с перенесёнными незакоммиченными
   правками (почему не в worktree — «Отступления от задания»). Вывод:

   ```
   прогон: sdlc/6-eval/auto/2026-10-08-a6ac60a/
   Итог: PASS 10, FAIL 0, BLOCKED 0, пропущено 0 — код 0
   ```

   Из `summary.md` прогона:

   ```
   - Незакоммиченные изменения: есть (`--allow-dirty`)
   - Итог: PASS (код 0)
   - Тесты: PASS 274, FAIL 0, BLOCKED 0

   | Путь UC | Тест | Вердикт |
   |---|---|---|
   | UC-12-P-01 | `test/app/bootstrap_test.dart` — UC-12-P-01: с адресом и ключом bootstrap поднимает Supabase | PASS |
   | UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку | PASS |
   | UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без параметров сборки адреса и ключа проекта нет | PASS |
   | UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: заглушка объясняет, чего не хватает | PASS |
   | UC-12-P-02 | `test/main_test.dart` — UC-12-P-02: без параметров сборки приложение показывает экран «не сконфигурировано» с причиной | PASS |
   | UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: Supabase не поднялся — bootstrap возвращает ошибку подключения | PASS |
   | UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: заглушка показывает переданные подробности | PASS |
   ```

   Все 10 проверок прогона — `PASS`. В сводке копии у путей UC-12 — `PASS`,
   у BT-6 «Закрыта» — `да`. Копия и её прогон удалены, в ветку не попали.
5. Сборки открыты в headless Chrome (`--screenshot`) с локального
   `python3 -m http.server`:
   - без параметров (`flutter build web --release`) — экран «Приложение не
     сконфигурировано» с причиной «Не заданы SUPABASE_URL и
     SUPABASE_ANON_KEY. Соберите приложение с параметрами --dart-define.»;
   - с параметрами из `supabase/.env.local` (`set -a; . supabase/.env.local;
     set +a`, затем `flutter build web --release` с
     `--dart-define=SUPABASE_URL="$SUPABASE_URL"`,
     `--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"` и `-o` в
     scratchpad), код 0 — экран «Вход»: поля «Логин», «Пароль», кнопка
     «Войти», ссылка «Нет аккаунта? Зарегистрируйтесь». Сборка с параметрами
     после проверки удалена.
6. Сдача — по составу `sdlc/5-results/AGENTS.md`; хэш в «Коммите работы» —
   `f63f9ce`, вывод `git show --stat` взят после коммита.

Значения из `supabase/.env.local` (поиск каждого значения, печатались только
счётчики): в добавленных строках `git diff`, в `test/main_test.dart`, в сдаче
и в сохранённых выводах проверок — 0 совпадений. В удалённых строках
`env.dart` — по одному совпадению у `SUPABASE_URL` и `SUPABASE_ANON_KEY`:
прежние значения по умолчанию совпадают с локальными, их удаление — это
правка 1.1. При разведке в журнал сессии попали прежние значения из
`env.dart`: вывод поиска по `lib/` и первый прогон перевёрнутого теста до
маскировки вывода. В чат и в сдачу они не попали.

## Применено к боевой

Нет. Сборка с параметрами открывалась в браузере на экране «Вход»; данные не
менялись.

## Обсуждение

До начала работы — нет.

По ходу:

- 2026-10-08, вопрос владельцу (стоп-условие): после удаления значений по
  умолчанию `flutter analyze` даёт 2 замечания
  `avoid_redundant_argument_values` в тесте
  `UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку`
  (`bootstrap(url: '', anonKey: '')`) — как их убрать? Варианты:
  `bootstrap()` без аргументов (тест рассчитан на запуск без
  `--dart-define`); оставить `''` и подавить замечание `// ignore:` с
  пояснением. Выбрано: `bootstrap()` без аргументов.
- 2026-10-08, выбор исполнителя: P-02 дополнительно проверен запуском `main()`
  без параметров сборки (`test/main_test.dart`) — экран с заголовком и
  причиной из UC-12. `main()` вызывается через `tester.runAsync`: на прежнем
  `env.dart` без него тест висел до таймаута в 10 минут.
- 2026-10-08, выбор исполнителя: P-03 вызван адресом, который не разбирается
  как URI (`https://[`), — `Supabase.initialize` падает до обращения к
  проекту. P-01 — адресом `https://project.invalid`; `SharedPreferences` в
  тестах `bootstrap` подменён пустым хранилищем, после P-01 —
  `Supabase.instance.dispose`.
- 2026-10-08, вопрос владельцу на СТОПе 1: коммитить ли работу в ветку
  `task/TASK-2`? Варианты: да, коммитить; нет, сначала правки. Выбрано: да.
- 2026-10-08, выбор исполнителя: для коммита работы сдача временно вынесена из
  дерева, производные файлы пересобраны без неё — чтобы `4-tasks/INDEX.md`
  этого коммита не ссылался на сдачу, которой в нём нет.

## Отступления от задания

- Самопроверка пункта 4 «Приёмки»: `run` выполнен не в worktree, а в клоне
  ветки в scratchpad с теми же незакоммиченными правками. `run` пишет папку
  прогона в `sdlc/6-eval/auto/`, а задание запрещает менять в `sdlc/`
  что-либо, кроме своей сдачи и производных файлов.

## Найдено вне задания

- Путь P-03 достижим, только когда падает сам `Supabase.initialize`:
  неразбираемый адрес или сбой хранилища сессии. `initialize` к проекту не
  обращается, поэтому с верно записанным, но чужим адресом или с неверным
  ключом приложение идёт по P-01 и запускается — ошибка проявится на первых
  запросах. Это показывает тест P-01: с адресом `https://project.invalid`
  `bootstrap` возвращает успех.
- Три теста P-02 (`без адреса и ключа bootstrap…`, `без параметров сборки
  адреса и ключа…`, `test/main_test.dart`) проверяют пустые значения `Env` и
  рассчитаны на запуск `flutter test` без `--dart-define`.
