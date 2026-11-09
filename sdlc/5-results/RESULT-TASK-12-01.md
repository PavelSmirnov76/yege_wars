# RESULT-TASK-12-01: Профиль с прогрессом

**Задание:** [TASK-12](../4-tasks/TASK-12-PROFILE-PROGRESS.md).

## Коммит работы

```text
978b12347cece2a6d943a3acfd4c3e1de8da21da
TASK-12: профиль с прогрессом и последними попытками

 lib/app/router/app_shell.dart                      |   9 +-
 lib/features/profile/data/progress_repository.dart |  76 ++++++
 lib/features/profile/domain/progress.dart          |  57 +++++
 .../profile/presentation/progress_providers.dart   |  21 ++
 .../presentation/screens/profile_screen.dart       | 239 +++++++++++++++----
 lib/l10n/app_ru.arb                                |  41 +++-
 sdlc/2-specs/use-cases/INDEX.md                    |   4 +-
 sdlc/3-design/design-system/INDEX.md               |   4 +-
 supabase/tests/rls_tests.sql                       |  42 ++++
 test/browser/tc19/README.md                        |  60 +++++
 test/browser/tc19/fixtures.json                    |  35 +++
 test/browser/tc19/tc19.cjs                         | 254 +++++++++++++++++++++
 .../features/profile/progress_navigation_test.dart |  54 +++++
 test/features/profile/progress_test.dart           | 121 ++++++++++
 test/features/profile/progress_widget_test.dart    | 150 ++++++++++++
 test/helpers/fake_progress_repository.dart         |  17 ++
 test/helpers/pump_app.dart                         |   7 +
 17 files changed, 1135 insertions(+), 56 deletions(-)
```

## Выполнено

- UC-41-P-01: сводка RPC и последние попытки объединены в одно состояние;
  данные привязаны к id аккаунта, возвращение в ветку и повторный выбор
  обновляют их. Тесты проверяют суммы, запрос, переход после отправки и
  поздний ответ другого аккаунта.
- UC-41-P-02 и UC-41-P-03: нулевой прогресс и пустой каталог; есть widget-
  и SQL-проверки.
- UC-41-P-04 и UC-41-P-05: отказ каждого запроса и повтор обоих проверяются
  тестами репозитория, состояние ошибки и повтор — widget-тестом.
- UC-42-P-01: попытка открывает именованный маршрут выбранного slug;
  переход проверен через реальный роутер.
- UC-4 и UC-13: логин, роль и выход сохранены; существующие тесты выполнены
  в полном прогоне.
- SQL-тест проверяет существующую RPC при пустом каталоге, нулевом прогрессе,
  повторной верной попытке, скрытии и публикации задачи без номера.
- Для независимого TC-19 подготовлены `test/browser/tc19/tc19.cjs`,
  `fixtures.json` и `README.md` с командами и версиями. Node v24.15.0,
  Playwright 1.64.1, Chromium 156.0.8078.4 по `docs/BROWSER_CHECKS.md`.

## Самопроверка приёмки

1. Шесть путей UC помечены в тестах, экран использует l10n и COMP-12/17/18,
   Supabase остаётся в data, domain не зависит от Flutter и Supabase.
2. Тест datasource проверяет id, статус, два порядка и limit; SQL проверяет
   вычисление прогресса, включая пустой каталог и повторную верную попытку.
3. Тесты реального роутера проверяют выбор slug при сохранённой другой задаче,
   возврат после отправки и повторный выбор; отдельный тест — поздний ответ
   при смене аккаунта. Существующие тесты UC-4/UC-13 прошли в полном прогоне.
4. Команды, коды и вывод Luna сохранены по указанным ниже путям. TC-19
   ожидает независимого прогона и не считается принятым.
5. Хэш работы указан в разделе «Коммит работы»; новых миграций и секретов нет.

## Не выполнено

TC-19 передаётся на независимый ручной прогон постановщику.

## Проверки

Luna: команды, полные выводы и коды — `/private/tmp/task12-checks/` и
`/private/tmp/task12-recheck/`, `/private/tmp/task12-final2/` и
`/private/tmp/task12-final3/` и `/private/tmp/task12-handoff/` (суффиксы `.command`, `.stdout`, `.exit`).

- `flutter pub get`, `flutter gen-l10n`, `dart run build_runner build
  --delete-conflicting-outputs` — exit 0. Build runner сообщает, что параметр
  `--delete-conflicting-outputs` удалён и проигнорирован.
- После исправлений `flutter analyze --fatal-infos --fatal-warnings` — exit 0:
  `No issues found! (ran in 3.5s)`; `dart run custom_lint` — exit 0:
  `No issues found!`.
- Полный `flutter test` после исправлений кода: 409 тестов прошли, два теста
  упали из-за неверного finder иконки. После исправления только finder повторены
  два затронутых файла: exit 0, `All tests passed!` (7 тестов). После
  последующих изменений экрана и отключения автоповтора повторены все тесты
  профиля: exit 0, `All tests passed!` (19 тестов).
- Проверка форматирования — exit 0; `python3 -m sdlc_tool views` и
  `python3 -m sdlc_tool check` — exit 0, последнее: `Итог: 0 ошибок,
  147 предупреждений` о ранее похороненных артефактах.
- PostgREST автоповтор отключён для обоих запросов; тест ответа 503
  подтверждает единственный запрос попыток.
- `bash supabase/tests/run_local.sh` — exit 0, `RLS TESTS PASSED`, `RLS OK`.
- `node --check test/browser/tc19/tc19.cjs` и `git diff --check` — exit 0.
  Проверка фикстур: 23 UUID, A — 1 из 3, B — 0 из 3, чужая попытка
  исключена, у A десять попыток в ожидаемом порядке — exit 0.

## Применено к боевой

Нет.

## Обсуждение

До начала работы: нет. По ходу: владелец 2026-11-09 подтвердил оба коммита;
ручной кейс предусмотрен для независимого тестировщика постановщика.

## Отступления от задания

Нет.

## Найдено вне задания

Нет.
