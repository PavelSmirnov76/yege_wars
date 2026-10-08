# RESULT-TASK-1-01: Метки среза «авторизация и роли» и недостающие тесты

## Задание

[TASK-1](../4-tasks/TASK-1-LABELS-AUTH.md).

## Коммит работы

`1381145` — «TASK-1: метки среза «авторизация и роли» и недостающие тесты»,
ветка `task/TASK-1`, после «да» владельца на СТОПе 1 (Обсуждение, п. 3).
Индексы в этом коммите собраны без сдачи; сдача и индексы с ней — отдельным
коммитом.

```
138114544fb9f89b06e7261b1d62bdfd18369377
TASK-1: метки среза «авторизация и роли» и недостающие тесты

 lib/app/router/app_router.dart                     |   2 +
 lib/app/router/app_shell.dart                      |   2 +
 lib/app/theme/app_breakpoints.dart                 |   2 +
 lib/app/theme/app_colors.dart                      |   2 +
 lib/app/theme/app_radius.dart                      |   2 +
 lib/app/theme/app_spacing.dart                     |   2 +
 lib/app/theme/app_theme.dart                       |   2 +
 lib/app/theme/app_typography.dart                  |   2 +
 lib/core/widgets/adaptive_navigation_scaffold.dart |   2 +
 lib/core/widgets/splash_screen.dart                |   2 +
 .../admin/presentation/screens/admin_screen.dart   |   2 +
 .../use_cases/get_current_profile_use_case.dart    |   2 +
 .../use_cases/is_registration_open_use_case.dart   |   2 +
 .../auth/domain/use_cases/sign_in_use_case.dart    |   2 +
 .../auth/domain/use_cases/sign_out_use_case.dart   |   2 +
 .../auth/domain/use_cases/sign_up_use_case.dart    |   2 +
 .../domain/use_cases/watch_auth_user_use_case.dart |   2 +
 .../presentation/controllers/auth_controller.dart  |   2 +
 .../auth/presentation/screens/login_screen.dart    |   2 +
 .../auth/presentation/screens/register_screen.dart |   2 +
 .../auth/presentation/widgets/auth_form_card.dart  |   2 +
 .../auth/presentation/widgets/auth_message.dart    |   2 +
 .../presentation/widgets/auth_submit_button.dart   |   2 +
 .../presentation/screens/profile_screen.dart       |   2 +
 sdlc/2-specs/use-cases/INDEX.md                    |  10 +-
 sdlc/3-design/design-system/INDEX.md               |  29 +-
 supabase/tests/rls_tests.sql                       | 291 ++++++++++++++++++++-
 test/app/router/app_router_test.dart               |  37 ++-
 test/features/auth/domain/use_cases_test.dart      |   6 +-
 .../auth/presentation/auth_controller_test.dart    |  14 +-
 .../auth/presentation/login_screen_test.dart       |  24 +-
 .../auth/presentation/register_screen_test.dart    |  29 +-
 test/features/profile/profile_screen_test.dart     |  24 +-
 33 files changed, 457 insertions(+), 55 deletions(-)
```

## Выполнено

Worktree `~/projects/yege_wars-TASK-1`, ветка `task/TASK-1`. Исходное
состояние сверено: `flutter test` — 271, все проходят; `run_local.sh` —
`RLS OK`.

### Стоп: адрес до входа не открывается после входа

[UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01):
«Без входа приложение показывает экран входа и запоминает адрес. После верных
логина и пароля открывается запомненный адрес или главная».
[UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01):
«приложение открывает адрес, с которым он пришёл, или главную».

Код: `_guard` в `lib/app/router/app_router.dart` сохраняет адрес в параметре
`from` только на время заставки (`AuthUnknown`). Для `AuthUnauthenticated` он
уводит на `AppRoutes.login` без `from`; после входа на `/login`
`_restoredLocation` адреса не находит и открывает каталог.

Проба — временный виджет-тест (удалён): сессия неизвестна, переход на
`/profile` — заставка; сессии нет — экран входа; вход верными логином и
паролем. Вывод:

```
PROBE адрес на экране входа: /login
PROBE после входа: /; профиль: 0, каталог: 1
```

Решение владельца — Обсуждение, п. 1.

### 1.1. Метки тестов Dart

Метка — в начале описания у 22 существующих тестов, тела не менялись. Три
длинных описания разбиты на соседние литералы, чтобы `dart format` не сдвигал
тело; у нескольких тестов форматтер перенёс список параметров замыкания на
новые строки.

Без метки оставлены:

- тесты путей UC-10-P-01 и UC-1-P-01 — по решению владельца (Обсуждение,
  п. 1): `app_router_test.dart` — «пока сессия не проверена, показывается
  заставка», «без авторизации любой путь ведёт на вход»;
  `login_screen_test.dart` — «успешный вход ведёт в каталог»;
  `register_screen_test.dart` — «успешная регистрация ведёт в каталог»;
  `app_test.dart` — «smoke: приложение стартует на экране входа»;
  `auth_controller_test.dart` — «до первого события статус неизвестен»,
  «пустая сессия — пользователь не авторизован», «успешный вход переводит в
  authenticated», «успешная регистрация переводит в authenticated»;
  `use_cases_test.dart` — «передаёт корректные данные в репозиторий»,
  «регистрирует при корректных данных»;
- тесты устройства (Обсуждение, п. 4): `auth_error_mapper_test.dart`,
  `profile_dto_test.dart`, `supabase_auth_remote_data_source_test.dart`,
  `auth_repository_impl_test.dart`, `auth_rules_test.dart`,
  `auth_entities_test.dart`, группа «остальные use case делегируют
  репозиторию», «повторное событие того же пользователя не грузит профиль
  заново», «показывает индикатор на время отправки»,
  `adaptive_navigation_scaffold_test.dart` (4 теста), «неизвестный путь
  показывает экран 404».

### 1.2. Метки RLS-тестов

Метка стоит в начале комментария к проверке: `-- UC-n-P-nn: что
проверяется`. Где комментария не было, добавлена строка (Обсуждение, п. 5).
Размечено 12 существующих проверок: (а) — UC-1-P-02 дважды, UC-1-P-04; (и) —
UC-6-P-01; (л) — UC-6-P-01, UC-9-P-01 дважды, UC-9-P-02; (н) — UC-6-P-01
дважды; (р) — UC-6-P-01 дважды.

Без метки: (а) «повторный username» — она падает на уникальности почты в
шиме, а не на `[username_taken]` (Найдено вне задания, п. 2); (а)
«Корректная регистрация» и «is_registration_open() доступна роли anon» —
путь UC-1-P-01 (Обсуждение, п. 1).

### 1.3. Недостающие тесты

Минимум задания — пути, у которых после 1.1–1.2 не было тестов: UC-7-P-01,
UC-7-P-02, UC-8-P-01…UC-8-P-04, UC-9-P-03, UC-10-P-04. Сверх минимума по
решению владельца (Обсуждение, п. 2) — UC-1-P-02, UC-1-P-03, UC-4-P-01,
UC-9-P-01, UC-10-P-05. Проверка `admin_set_role` под учеником — выбор
исполнителя (Обсуждение, п. 8).

| Путь | Где | Что проверяет |
|---|---|---|
| [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02) | `register_screen_test.dart` | некорректные логин и пароль — ошибки у полей, `signUp` не вызван |
| [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03) | `rls_tests.sql`, (а) | запись в `auth.users` с другой почтой и занятым логином — `[username_taken]` |
| [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01) | `profile_screen_test.dart` | профиль администратора — «Роль: Администратор» |
| [UC-6-P-01](../2-specs/use-cases/UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md#uc-6-p-01) | `rls_tests.sql`, (с) | `admin_set_role` под учеником — `[forbidden]` |
| [UC-7-P-01](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-01) | `rls_tests.sql`, (т) | администратор через RLS закрывает регистрацию: 1 строка, `is_registration_open()` — `false`, `signup` — `[registration_closed]`; открывает: 1 строка, `true`, `signup` проходит |
| [UC-7-P-02](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-02) | `rls_tests.sql`, (т) | ученик меняет `registration_open`: без ошибки, 0 строк, `is_registration_open()` — `true` |
| [UC-8-P-01](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-01) | `rls_tests.sql`, (с) | администратор назначает ученику роль `admin` и снимает её |
| [UC-8-P-02](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-02) | `rls_tests.sql`, (с) | администратор снимает роль с себя — `[self_demote]` |
| [UC-8-P-03](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-03) | `rls_tests.sql`, (с) | роль `superuser` — `[bad_role]` |
| [UC-8-P-04](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-04) | `rls_tests.sql`, (с) | несуществующий пользователь — `[user_not_found]` |
| [UC-9-P-01](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01) | `rls_tests.sql`, (л) | после `admin_reset_password` хэш сходится с новым паролем (`extensions.crypt`) и не сходится с другим |
| [UC-9-P-03](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-03) | `rls_tests.sql`, (л) | `admin_reset_password` несуществующему пользователю — `[user_not_found]` |
| [UC-10-P-04](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-04) | `login_screen_test.dart` | `NetworkFailure` при входе — сообщение, остаётся экран входа |
| [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05) | `app_router_test.dart` | вошедший на `/login` и `/register` попадает в каталог |

Разделы (с) `admin_set_role` и (т) «Переключение регистрации» — новые, в
конце `rls_tests.sql` перед итогом. В проверках с ожидаемой ошибкой «роль не
меняется» и «данные не меняются» отдельно не проверяются. Ошибку ловит
подблок `begin … exception`, и она откатывает его изменения, поэтому такая
проверка упасть не может.

Холостота: каждая из 14 новых проверок запущена с перевёрнутым ожиданием —
все падают. Файлы возвращены, `sha256` совпали с исходными. Выводы — в
«Проверках».

Пути, которые тестом не проверить: нет.

### 1.4. Метки в коде

Только абзац doc-комментария, код не менялся.

| Файл | Метка |
|---|---|
| `lib/features/auth/domain/use_cases/sign_up_use_case.dart` | `UC-1` |
| `lib/features/auth/domain/use_cases/is_registration_open_use_case.dart` | `UC-1` |
| `lib/features/auth/domain/use_cases/sign_in_use_case.dart` | `UC-10` |
| `lib/features/auth/domain/use_cases/get_current_profile_use_case.dart` | `UC-10` |
| `lib/features/auth/domain/use_cases/watch_auth_user_use_case.dart` | `UC-10`, `UC-11` |
| `lib/features/auth/domain/use_cases/sign_out_use_case.dart` | `UC-11` |
| `lib/features/auth/presentation/controllers/auth_controller.dart` | `UC-1`, `UC-10`, `UC-11` |
| `lib/features/auth/presentation/screens/register_screen.dart` | `UC-1` |
| `lib/features/auth/presentation/screens/login_screen.dart` | `UC-10` |
| `lib/core/widgets/splash_screen.dart` | `UC-10` |
| `lib/features/profile/presentation/screens/profile_screen.dart` | `UC-4`, `UC-11` |
| `lib/features/admin/presentation/screens/admin_screen.dart` | `UC-5` |
| `lib/app/router/app_router.dart`, функция `_guard` | `UC-1`, `UC-5`, `UC-10`, `UC-11` |
| `lib/app/router/app_shell.dart` | `UC-5`, `COMP-4` |
| `lib/app/theme/app_colors.dart` | `TOKEN-1` |
| `lib/app/theme/app_typography.dart` | `TOKEN-2` |
| `lib/app/theme/app_spacing.dart` | `TOKEN-3` |
| `lib/app/theme/app_radius.dart` | `TOKEN-4` |
| `lib/app/theme/app_breakpoints.dart` | `TOKEN-5` |
| `lib/app/theme/app_theme.dart` | `TOKEN-6` |
| `lib/features/auth/presentation/widgets/auth_form_card.dart` | `COMP-1` |
| `lib/features/auth/presentation/widgets/auth_message.dart` | `COMP-2` |
| `lib/features/auth/presentation/widgets/auth_submit_button.dart` | `COMP-3` |
| `lib/core/widgets/adaptive_navigation_scaffold.dart` | `COMP-4` |

UC-6…UC-9 реализованы только в базе, и метки у них — только в тестах. В
индексе «Где реализован» у них по-прежнему «не покрыто», как решено при
постановке.

### Путь → тесты с его меткой

Таблицу собрали те же разборщики, что использует `sdlc_tool run`
(`parse_flutter_events`, `flutter_rows`, `sql_rows`), по JSON-отчёту
итогового `flutter test` и по `rls_tests.sql`. Сам `run` не запускался.

| Путь | Тесты с меткой |
|---|---|
| [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) | нет — см. «Не выполнено» |
| [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02) | `test/features/auth/domain/use_cases_test.dart`: `SignUpUseCase UC-1-P-02: проверяет ввод до обращения к репозиторию`<br>`test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-02: не отправляет форму с некорректным вводом`<br>`supabase/tests/rls_tests.sql`: `UC-1-P-02: короче 3 символов`<br>`supabase/tests/rls_tests.sql`: `UC-1-P-02: недопустимые символы` |
| [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03) | `test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-03: ошибка регистрации показывается на экране`<br>`supabase/tests/rls_tests.sql`: `UC-1-P-03: занятый логин с другой почтой — [username_taken] из триггера` |
| [UC-1-P-04](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-04) | `test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-04: при закрытой регистрации форма заблокирована`<br>`supabase/tests/rls_tests.sql`: `UC-1-P-04: закрытая регистрация — [registration_closed]` |
| [UC-1-P-05](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-05) | `test/features/auth/presentation/register_screen_test.dart`: `UC-1-P-05: ошибка проверки регистрации показывается` |
| [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01) | `test/features/profile/profile_screen_test.dart`: `UC-4-P-01: показывает логин и роль`<br>`test/features/profile/profile_screen_test.dart`: `UC-4-P-01: показывает роль администратора` |
| [UC-5-P-01](../2-specs/use-cases/UC-5-ACTOR-2-EVT-5-ENT-2-SECTION-SHOWN-IN-AUTH.md#uc-5-p-01) | `test/app/router/app_router_test.dart`: `UC-5-P-01: админ открывает админку и видит пункт меню` |
| [UC-5-P-02](../2-specs/use-cases/UC-5-ACTOR-2-EVT-5-ENT-2-SECTION-SHOWN-IN-AUTH.md#uc-5-p-02) | `test/app/router/app_router_test.dart`: `UC-5-P-02: ученика не пускает в админку и прячет пункт меню` |
| [UC-6-P-01](../2-specs/use-cases/UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md#uc-6-p-01) | `supabase/tests/rls_tests.sql`: `UC-6-P-01: под студентом — [forbidden]`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: admin_reset_password под студентом — [forbidden]`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: админские RPC под студентом`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: admin_upsert_article под студентом`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: admin_set_task_answer под учеником — [forbidden]`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: admin_get_task под учеником`<br>`supabase/tests/rls_tests.sql`: `UC-6-P-01: admin_set_role под учеником — [forbidden]` |
| [UC-7-P-01](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-01) | `supabase/tests/rls_tests.sql`: `UC-7-P-01: администратор закрывает и открывает регистрацию, is_registration_open() и триггер следуют флагу` |
| [UC-7-P-02](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-02) | `supabase/tests/rls_tests.sql`: `UC-7-P-02: ученик меняет registration_open — без ошибки, 0 строк, значение прежнее` |
| [UC-8-P-01](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-01) | `supabase/tests/rls_tests.sql`: `UC-8-P-01: администратор назначает и снимает роль администратора` |
| [UC-8-P-02](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-02) | `supabase/tests/rls_tests.sql`: `UC-8-P-02: снять роль администратора с себя — [self_demote]` |
| [UC-8-P-03](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-03) | `supabase/tests/rls_tests.sql`: `UC-8-P-03: недопустимая роль — [bad_role]` |
| [UC-8-P-04](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-04) | `supabase/tests/rls_tests.sql`: `UC-8-P-04: роль несуществующему пользователю — [user_not_found]` |
| [UC-9-P-01](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01) | `supabase/tests/rls_tests.sql`: `UC-9-P-01: нормальный пароль — проходит`<br>`supabase/tests/rls_tests.sql`: `UC-9-P-01: хэш действительно изменился`<br>`supabase/tests/rls_tests.sql`: `UC-9-P-01: новым паролем можно войти — хэш bcrypt сходится с ним и не сходится с другим` |
| [UC-9-P-02](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-02) | `supabase/tests/rls_tests.sql`: `UC-9-P-02: короткий пароль — [weak_password]` |
| [UC-9-P-03](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-03) | `supabase/tests/rls_tests.sql`: `UC-9-P-03: пароль несуществующему пользователю — [user_not_found]` |
| [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) | нет — см. «Не выполнено» |
| [UC-10-P-02](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-02) | `test/features/auth/presentation/auth_controller_test.dart`: `действия пользователя UC-10-P-02: неуспешный вход не меняет состояние`<br>`test/features/auth/presentation/login_screen_test.dart`: `UC-10-P-02: показывает ошибку сервера` |
| [UC-10-P-03](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-03) | `test/features/auth/domain/use_cases_test.dart`: `SignInUseCase UC-10-P-03: не идёт в репозиторий при неверном логине`<br>`test/features/auth/domain/use_cases_test.dart`: `SignInUseCase UC-10-P-03: не идёт в репозиторий при коротком пароле`<br>`test/features/auth/presentation/login_screen_test.dart`: `UC-10-P-03: не отправляет форму с некорректным вводом` |
| [UC-10-P-04](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-04) | `test/features/auth/presentation/login_screen_test.dart`: `UC-10-P-04: сбой связи показывается сообщением` |
| [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05) | `test/app/router/app_router_test.dart`: `UC-10-P-05: адрес, открытый до проверки сессии, восстанавливается`<br>`test/app/router/app_router_test.dart`: `UC-10-P-05, UC-11-P-03: после входа открывается каталог, после выхода — вход`<br>`test/app/router/app_router_test.dart`: `UC-10-P-05: вошедшего с /login и /register уводит на главную`<br>`test/features/auth/presentation/auth_controller_test.dart`: `подписка на сессию UC-10-P-05: восстановленная сессия загружает профиль` |
| [UC-10-P-06](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-06) | `test/features/auth/presentation/auth_controller_test.dart`: `подписка на сессию UC-10-P-06: ошибка чтения профиля оставляет пользователя снаружи`<br>`test/features/auth/presentation/login_screen_test.dart`: `UC-10-P-06: показывает ошибку восстановления сессии` |
| [UC-11-P-01](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-01) | `test/features/auth/presentation/auth_controller_test.dart`: `действия пользователя UC-11-P-01: выход возвращает в unauthenticated`<br>`test/features/profile/profile_screen_test.dart`: `UC-11-P-01: кнопка «Выйти» возвращает на экран входа` |
| [UC-11-P-02](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-02) | `test/features/auth/presentation/auth_controller_test.dart`: `действия пользователя UC-11-P-02: ошибка выхода сохраняет вход`<br>`test/features/profile/profile_screen_test.dart`: `UC-11-P-02: ошибка выхода показывается сообщением` |
| [UC-11-P-03](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-03) | `test/app/router/app_router_test.dart`: `UC-10-P-05, UC-11-P-03: после входа открывается каталог, после выхода — вход`<br>`test/features/auth/presentation/auth_controller_test.dart`: `подписка на сессию UC-11-P-03: выход из аккаунта в другой вкладке сбрасывает состояние` |

## Не выполнено

- UC-10-P-01 и UC-1-P-01 — без меток. Код не открывает после входа и
  регистрации адрес, с которым пришёл посетитель (см. «Стоп»), поэтому тест
  полного пути не пройдёт. По решению владельца оба пути остаются «НЕ
  ПРОВЕРЕНО» (Обсуждение, п. 1).
- `python3 -m sdlc_tool run` не запускался: по заданию его прогоняет
  постановщик при приёмке.

## Проверки

Исходное состояние, до правок: `flutter test --reporter json` — 271 тест
`success`, 0 упавших; `run_local.sh` — `RLS OK`.

Итоговое состояние — рабочее дерево перед коммитом `1381145`, вошло в него
без изменений:

- `flutter pub get` (в начале работы), `flutter gen-l10n`,
  `dart run build_runner build --delete-conflicting-outputs` — код 0;
  последняя строка: `Built with build_runner/aot in 0s; wrote 0 outputs.`
- `flutter analyze --fatal-infos --fatal-warnings`:
  `No issues found! (ran in 2.0s)`
- `dart run custom_lint`: `No issues found!`
- `flutter test`: `00:11 +275: All tests passed!`
- `find lib test … | xargs -0 dart format --output=none --set-exit-if-changed`:
  `Formatted 189 files (0 changed) in 0.17 seconds.`, код 0
- `bash supabase/tests/run_local.sh`, строки новых и размеченных проверок и
  конец:

```
NOTICE:  OK: (а) короткий username отклонён ([invalid_username] Логин должен содержать от 3 до 20 символов: латинские буквы, цифры или подчёркивание.)
NOTICE:  OK: (а) username с недопустимыми символами отклонён ([invalid_username] Логин должен содержать от 3 до 20 символов: латинские буквы, цифры или подчёркивание.)
NOTICE:  OK: (а) повторный username отклонён (duplicate key value violates unique constraint "users_email_key")
NOTICE:  OK: (а) занятый логин с другой почтой — [username_taken]
NOTICE:  OK: (а) при закрытой регистрации signup падает с [registration_closed]
NOTICE:  OK: (л) admin_reset_password под студентом — [forbidden]
NOTICE:  OK: (л) короткий пароль — [weak_password]
NOTICE:  OK: (л) admin_reset_password под админом: encrypted_password изменился
NOTICE:  OK: (л) admin_reset_password: новый пароль сходится с хэшем, другой — нет
NOTICE:  OK: (л) admin_reset_password несуществующему пользователю — [user_not_found]
NOTICE:  OK: (с) admin_set_role под учеником — [forbidden]
NOTICE:  OK: (с) admin_set_role: администратор назначает и снимает роль
NOTICE:  OK: (с) admin_set_role: снять роль с себя — [self_demote]
NOTICE:  OK: (с) admin_set_role: недопустимая роль — [bad_role]
NOTICE:  OK: (с) admin_set_role несуществующему пользователю — [user_not_found]
NOTICE:  OK: (т) администратор закрывает и открывает регистрацию, is_registration_open() и триггер следуют флагу
NOTICE:  OK: (т) ученик меняет registration_open — без ошибки, 0 строк, значение прежнее
NOTICE:  RLS TESTS PASSED
RLS OK
```

- `python3 -m sdlc_tool views`, затем `python3 -m sdlc_tool check`:
  `Итог: 0 ошибок, 0 предупреждений`
- В `lib/` изменены только строки `///`: добавлено 48, других изменённых строк
  0. `git diff --stat supabase/migrations` — пусто. В изменениях нет
  `reference/`, `supabase/seed/local/`, `.env`, `*.g.dart`, `lib/l10n/gen/`.
- Индексы: «Где реализован» заполнено у UC-1, UC-4, UC-5, UC-10, UC-11, у
  TOKEN-1…TOKEN-6 и COMP-1…COMP-4; у UC-6…UC-9 — «не покрыто». Раздела «Файлы
  темы без метки» нет.

Холостота новых проверок — ожидание перевёрнуто, запуск, файл возвращён.
Перевороты сделаны на итоговом файле, номера строк — его.

| Путь | Что перевёрнуто | Вывод |
|---|---|---|
| [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03) | `sqlerrm not like '[username_taken]%'` → `like` | `rls_tests.sql:98: ERROR:  ТЕСТ ПРОВАЛЕН (а): ожидалась ошибка [username_taken], получено: [username_taken] Логин «alice» уже занят, выберите другой.` |
| [UC-9-P-01](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01) | `crypt(…, v_hash) <> v_hash` → `=` | `rls_tests.sql:940: ERROR:  ТЕСТ ПРОВАЛЕН (л): новый пароль не сходится с хэшем после admin_reset_password` |
| [UC-9-P-03](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-03) | `sqlerrm not like '[user_not_found]%'` → `like` | `rls_tests.sql:962: ERROR:  ТЕСТ ПРОВАЛЕН (л): ожидалась ошибка [user_not_found], получено: [user_not_found] Пользователь не найден.` |
| [UC-6-P-01](../2-specs/use-cases/UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md#uc-6-p-01) | `sqlerrm not like '[forbidden]%'` → `like` | `rls_tests.sql:2267: ERROR:  ТЕСТ ПРОВАЛЕН (с): ожидалась ошибка [forbidden], получено: [forbidden] Доступно только администратору.` |
| [UC-8-P-01](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-01) | `v_role is distinct from 'admin'` → `is not distinct from` | `rls_tests.sql:2297: ERROR:  ТЕСТ ПРОВАЛЕН (с): после назначения роль carol = admin, ожидалась admin` |
| [UC-8-P-02](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-02) | `sqlerrm not like '[self_demote]%'` → `like` | `rls_tests.sql:2319: ERROR:  ТЕСТ ПРОВАЛЕН (с): ожидалась ошибка [self_demote], получено: [self_demote] Нельзя снять роль администратора с самого себя.` |
| [UC-8-P-03](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-03) | `sqlerrm not like '[bad_role]%'` → `like` | `rls_tests.sql:2343: ERROR:  ТЕСТ ПРОВАЛЕН (с): ожидалась ошибка [bad_role], получено: [bad_role] Недопустимая роль. Разрешены: student, admin.` |
| [UC-8-P-04](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-04) | `sqlerrm not like '[user_not_found]%'` → `like` | `rls_tests.sql:2365: ERROR:  ТЕСТ ПРОВАЛЕН (с): ожидалась ошибка [user_not_found], получено: [user_not_found] Пользователь не найден.` |
| [UC-7-P-01](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-01) | `is_registration_open() is not false` → `is not true` | `rls_tests.sql:2419: ERROR:  ТЕСТ ПРОВАЛЕН (т): регистрация закрыта, а is_registration_open() вернула не false` |
| [UC-7-P-02](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-02) | `v_rows <> 0` → `v_rows = 0` | `rls_tests.sql:2446: ERROR:  ТЕСТ ПРОВАЛЕН (т): ученик изменил registration_open, изменено строк: 0` |
| [UC-10-P-04](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-04) | сообщение `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Нет соединения с сервером. Проверьте` / `Some tests failed.` |
| [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02) | ошибка у поля логина `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Логин: 3–20 символов — латиница, цифры и` / `Some tests failed.` |
| [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01) | «Роль: Администратор» `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Роль: Администратор": [` / `Some tests failed.` |
| [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05) | `CatalogScreen` `findsOneWidget` → `findsNothing` | `Expected: no matching candidates` / `Actual: _TypeWidgetFinder:<Found 1 widget with type "CatalogScreen": [` / `Some tests failed.` |

Код выхода: `run_local.sh` — 3 (psql с `ON_ERROR_STOP`), `flutter test` — 1.
После всех переворотов: `файлы возвращены как были: True`.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — нет.

По ходу:

1. 2026-10-08, стоп по расхождению кода с путями. Вопрос: как поступить с
   [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01)
   и [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01):
   адрес до входа не открывается после входа? Варианты: не метить два пути;
   метить по рабочим частям; остановить задание. Выбрано: **не метить два
   пути** — они остаются «НЕ ПРОВЕРЕНО», в сдаче — с причиной, остальное
   задание продолжается.
2. 2026-10-08. Вопрос: какие непроверенные части путей с метками дописать
   тестами сверх минимума задания? Варианты, можно несколько:
   [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03)
   и [UC-9-P-01](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01)
   — SQL (`[username_taken]` из триггера; вход новым паролем после
   `admin_reset_password`);
   [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02)
   — виджет (ошибки у полей на экране регистрации);
   [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01)
   — виджет (роль «администратор» в профиле);
   [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05)
   — роутер (вошедшего с `/login` и `/register` уводит на главную). Выбрано:
   **все четыре**.
3. 2026-10-08, СТОП 1. Вопрос: коммитить работу в `task/TASK-1`?
   Варианты: коммитить; сначала проверка разметки агентами (workflow из
   трёх агентов), потом решение; не коммитить. Выбрано: **коммитить**.

Выбор исполнителя там, где задание его не предписывало:

4. Какие тесты метить. Задание: «тест, который проверяет устройство, а не
   путь (разбор DTO, отдельная функция), остаётся без метки». Метку получили
   тесты кода, который реализует UC (use case, контроллер, экраны, роутер), и
   проверки базы. Тесты слоя данных (маппер ошибок, DTO, datasource,
   репозиторий) и правил ввода остались без метки. Они проверяют, как
   устроен слой, а путь проверяют тесты выше по слоям.
5. Формат SQL-метки — `-- UC-n-P-nn: что проверяется`, в начале комментария
   к проверке. Скрипт берёт имя строки SQL в прогоне из текста комментария, и
   голые метки дали бы в сводке одинаковые строки. Такой же вид у меток в
   тестах скрипта (`sdlc_tool/tests/test_run.py`).
6. Метки `UC-n` в коде сверх перечня задания: `AuthController` (`UC-1`,
   `UC-10`, `UC-11` — вход, регистрация, выход, подписка на сессию),
   `SplashScreen` (`UC-10` — заставка из UC-10-P-01), `AdminScreen` (`UC-5` —
   «экран раздела открывается»). Формулировки: `/// Реализует UC-n.`,
   `/// Воплощает TOKEN-n.`, `/// Воплощает COMP-n.`
7. UC-6-P-01 стоит и на проверках (н) и (р), которые проверяют только факт
   отказа, без кода. UC-1-P-02 стоит на проверках (а), которые не сверяют код
   `[invalid_username]`. По выводу прогона отказ в обоих случаях приходит с
   нужным кодом (Найдено вне задания, п. 4).
8. Сверх перечня 1.3 добавлена проверка `admin_set_role` под учеником
   (`[forbidden]`, UC-6-P-01): до задания RLS-тесты `admin_set_role` не
   вызывали вовсе.

## Отступления от задания

Нет.

## Найдено вне задания

1. Адрес до входа не запоминается. UC-10-P-01, UC-1-P-01 и требование
   [R9](../0-vibes/prd/PRD.md#r9) («адрес, с которым пришёл посетитель,
   открывается после входа») расходятся с `_guard`: адрес сохраняется только
   на время заставки (см. «Стоп»). Не чинилось.
2. Проверка «повторный username» в разделе (а) `rls_tests.sql` падает на
   уникальности `email` в таблице шима `auth.users`, а не на `[username_taken]`
   триггера `handle_new_user`. Вывод прогона: `OK: (а) повторный username
   отклонён (duplicate key value violates unique constraint "users_email_key")`.
   Ответ `[username_taken]` теперь проверяет отдельная проверка UC-1-P-03.
3. Клиент выводит почту из логина в нижнем регистре
   (`SupabaseAuthRemoteDataSource.emailFor`), а `profiles.username` уникален с
   учётом регистра. Поэтому повтор логина при регистрации — это и повтор
   почты. Доходит ли такой запрос на боевой до триггера и `[username_taken]`,
   не проверялось.
4. Проверки (а) на недопустимый логин и проверки (н), (р) на отказ `admin_*`
   под учеником проходят при любой ошибке: код (`[invalid_username]`,
   `[forbidden]`) они не сверяют.
5. Описание теста `UC-10-P-02: показывает ошибку сервера` не совпадает с
   проверяемым: тест проверяет неверный пароль. Описание не менялось — по
   заданию в нём добавляется только метка.
