# Состояние проекта

Обновлено: 2026-09-17. Полное ТЗ — [SPEC.md](SPEC.md). Выполнены этапы 1–3 из 10.
Коммиты: `0a3179c` (этап 1, каркас), `b86adc4` (этап 2, Supabase),
этап 3 (авторизация) — в рабочем дереве.

## Этап 1 — каркас (готово)

Структура: Clean Architecture + feature-first (`lib/app`, `lib/core`,
`lib/features/<feature>/{domain,data,presentation}`).

Контракты, на которые завязан существующий код (не переименовывать):

- **Тема** `lib/app/theme/`: `AppColors` (background, surface, surfaceElevated,
  border, textPrimary/Secondary/Disabled, accent, accentHover, onAccent,
  success, warning, danger, difficultyEasy/Medium/Hard, codeBackground),
  `AppSpacing` (xxs…xxxl), `AppRadius` (sm/md/lg/full),
  `AppBreakpoints` (mobileMax=600, tabletMax=1024, isMobile/isTablet/isDesktop),
  `AppTypography` (`textTheme()` — Inter, `code()` — JetBrains Mono),
  `AppTheme.dark()`. Хардкод цветов вне токенов запрещён.
- **Ошибки** `lib/core/error/`: `sealed class Failure` (message — русский текст
  для UI, cause) с подклассами Network/Auth/Database/Validation/UnexpectedFailure;
  `sealed class Result<T>` = `Ok<T>` | `Err<T>` (fold, map, isOk, isErr,
  valueOrNull, failureOrNull), `typedef FutureResult<T>`.
- **Конфиг** `lib/core/config/env.dart`: `Env.supabaseUrl`, `Env.supabaseAnonKey`
  из `--dart-define`, `Env.isConfigured`.
- **l10n**: все UI-строки в `lib/l10n/app_ru.arb`, генерация в `lib/l10n/gen/`
  (`l10n.yaml`, synthetic-package: false), доступ через `context.l10n`
  (`lib/core/utils/l10n_ext.dart`). Кодоген (l10n и build_runner) в git НЕ коммитится.
- **Навигация**: `lib/core/widgets/adaptive_navigation_scaffold.dart`
  (NavigationBar при ширине <600, NavigationRail дальше, extended ≥1024);
  `lib/app/router/app_routes.dart` (константы путей и имён: `/`, `/profile`,
  `/admin`, `/login`, `/register`); `app_router.dart` — `@riverpod GoRouter appRouter`,
  StatefulShellRoute.indexedStack (3 ветки), redirect по `authControllerProvider`,
  refreshListenable через ValueNotifier + ref.listen, errorBuilder → NotFoundScreen.
- **Auth-стаб**: `lib/features/auth/presentation/controllers/auth_controller.dart` —
  `@riverpod class AuthController`, `AuthStatus {unknown, unauthenticated,
  authenticated}` (`lib/features/auth/domain/auth_status.dart`), signIn()/signOut()
  ВРЕМЕННЫЕ заглушки — заменяются на этапе 3.
- **Riverpod v3 + кодогенерация**: провайдеры только через `@riverpod`
  (riverpod_annotation), part-файлы `*.g.dart`.
- Тесты: 22 (тема, Result, адаптивная навигация, guard-редиректы, smoke,
  auth-контроллер). Экраны входа/регистрации/каталога/профиля/админки —
  свёрстанные заглушки.
- CI `.github/workflows/ci.yml`: format-check (только не-генерённые файлы) →
  gen-l10n → build_runner → analyze --fatal-infos --fatal-warnings →
  custom_lint → test --coverage → build web. GitHub remote ещё НЕ настроен,
  CI на GitHub не гонялся.

## Этап 2 — Supabase (готово)

- **Миграции** `supabase/migrations/` (применять по порядку имён):
  `20260917120000_schema.sql` — profiles, tasks, task_answers, submissions,
  app_settings (registration_open=true, submissions_per_minute=10); триггеры на
  auth.users: check_registration_open (before insert) и handle_new_user
  (after insert, username из raw_user_meta_data, регэксп `^[A-Za-z0-9_]{3,20}$`);
  `20260917120001_rls.sql` — RLS на всех таблицах + is_admin(), has_solved_task();
  task_answers: ни политик, ни привилегий; submissions: select своя / админ /
  опубликованная при собственной верной попытке, insert/update/delete только RPC;
  `20260917120002_functions.sql` — 15 RPC (security definer): submit_solution
  (нормализация ответа, rate limit), set_solution_published, is_registration_open
  (доступна anon), get_user_progress, get_task_stats, admin_get_task_answer,
  admin_reset_password, admin_set_role, admin_list_students,
  admin_student_overview, admin_task_attempts, admin_recent_submissions и др.
- **Ошибки RPC** — `raise exception '[код] Русский текст'`. Коды:
  registration_closed, invalid_username, username_taken, rate_limit, not_owner,
  not_correct, forbidden, weak_password, self_demote. Клиент должен парсить код
  из начала message и показывать русский текст.
- **RLS-тесты** `supabase/tests/`: shim_local.sql (эмуляция auth-схемы Supabase
  на голом PostgreSQL), rls_tests.sql (37 проверок), run_local.sh — поднимает
  временный кластер PostgreSQL 17 и гоняет всё. Запуск:
  `bash supabase/tests/run_local.sh` → в конце `RLS OK`. Docker не нужен.
- **Seed** `supabase/seed/seed_tasks/` — отдельный Dart-пакет (45 юнит-тестов):
  `SEED_DATABASE_URL=postgres://… dart run bin/seed_tasks.dart`
  `[--tasks-dir tasks] [--answers …/answers.local.json] [--dry-run] [--unpublished]`.
  Идемпотентный upsert по slug; `files` формируются как
  `task_files/<ege_number>/<slug>/<имя файла>`.
- **Банк задач** `tasks/<ege_number>/<slug>/` (task.yaml + statement.md + файлы
  данных) — 10 оригинальных задач в стиле КЕГЭ-2027: e02-truth-table,
  e05-num-transform, e12-editor, e16-rec-branch, e17-pairs-file, e23-dag-paths,
  e24-longest-run, e25-divisors-mask, e26-warehouse, e27-pair-sum. Ответ каждой
  вычислен эталонным решением и подтверждён независимым решением по условию.

## Этап 3 — авторизация (готово)

Пакеты: `supabase_flutter` 2.17.2, `http` (распознавание обрыва запроса
PostgREST), `meta` (`@immutable` в domain).

- **Старт** `lib/app/bootstrap.dart`: `Future<Result<void>> bootstrap()` —
  `ensureInitialized`, проверка `Env.isConfigured`, затем
  `Supabase.initialize(url:, publishableKey:)` (`anonKey` в SDK объявлен
  устаревшим, значение то же — публичный anon-ключ). `main.dart` по
  результату запускает `ProviderScope(YegeWarsApp)` либо
  `NotConfiguredApp(details:)` (`lib/app/not_configured_app.dart`).
- **Domain** `lib/features/auth/domain/`:
  `entities/user_role.dart` — `enum UserRole {student, admin}` (`value`,
  `fromValue` — неизвестное значение трактуется как `student`, `isAdmin`);
  `entities/user_profile.dart` — `UserProfile(id, username, role)` c `==`;
  `auth_state.dart` — sealed `AuthState`: `AuthUnknown` |
  `AuthUnauthenticated({failure})` | `AuthAuthenticated(profile)`,
  геттеры `profileOrNull`/`isAuthenticated`/`isAdmin`
  (**заменил `enum AuthStatus`, файл `auth_status.dart` удалён**);
  `auth_rules.dart` — `usernamePattern` `^[A-Za-z0-9_]{3,20}$`,
  `passwordMinLength = 8` (единственный источник правил для UI и domain);
  `credentials_validation.dart` — `ValidationFailure` с русским текстом;
  `repositories/auth_repository.dart` — `watchUserId`, `currentProfile`,
  `signIn`, `signUp`, `signOut`, `isRegistrationOpen`, всё через `Result`;
  `use_cases/` — SignIn, SignUp, SignOut, GetCurrentProfile, WatchAuthUser,
  IsRegistrationOpen (вызываются как функции, метод `call`).
- **Data** `lib/features/auth/data/`:
  `datasources/auth_remote_data_source.dart` — интерфейс;
  `supabase_auth_remote_data_source.dart` — `emailDomain = 'ege.local'`,
  `emailFor(username)` приводит логин к нижнему регистру (логин в
  `profiles` сохраняется как введён), `signUp` кладёт логин в
  `data: {'username': …}` для триггера, `watchUserId` =
  `onAuthStateChange.map(session.user.id).distinct()`;
  `dto/profile_dto.dart` (`FormatException` на неожиданной строке);
  `mappers/auth_error_mapper.dart` — `AuthErrorMapper.map(error,
  {operation})` и `enum AuthOperation {signIn, signUp, other}`;
  `repositories/auth_repository_impl.dart` — единственное место, где
  исключения SDK превращаются в `Failure`.
- **Ошибки БД на клиенте**: `lib/core/error/rpc_error.dart` —
  `RpcError.tryParse('[код] Текст')` и `RpcErrorCodes` (пригодится
  этапам 6 и 8). `Failure` теперь `implements Exception` (нужно, чтобы
  ошибку можно было пробросить в `AsyncError`).
- **Важно про регистрацию**: ошибку триггера (`[username_taken]`,
  `[registration_closed]`) Supabase Auth обычно отдаёт как
  `unexpected_failure` / «Database error saving new user», теряя исходный
  текст. Маппер разбирает `[код]`, если текст дошёл, иначе при регистрации
  показывает «Не удалось зарегистрироваться. Возможно, логин уже занят или
  регистрация закрыта». **Живьём не проверено** — нужен проект Supabase.
- **Presentation**: `lib/features/auth/auth_providers.dart` —
  `authRepositoryProvider` (в тестах подменяется целиком), провайдеры
  use case'ов, `registrationOpenProvider` (`FutureProvider<bool>`,
  ошибку отдаёт как `Failure` в `AsyncError`);
  `AuthController` — `@Riverpod(keepAlive: true)`, состояние `AuthState`,
  подписка на `watchUserId`, методы `signIn`/`signUp`/`signOut`
  возвращают `Result`; экраны входа и регистрации (валидация, индикатор
  на кнопке, сообщение об ошибке над формой, блокировка формы при
  закрытой регистрации), `ProfileScreen` (логин, роль, «Выйти»);
  виджеты `AuthFormCard`, `AuthMessage`, `AuthSubmitButton`;
  `auth_field_validators.dart` — правила из `AuthRules`, тексты из l10n.
- **Роутер**: добавлен `/splash` (`AppRoutes.splash`, `splashName`) и
  параметр `AppRoutes.fromQueryParam = 'from'`. Guard: `AuthUnknown` →
  splash с сохранением адреса; `AuthUnauthenticated` → `/login`;
  `AuthAuthenticated` на `/login`, `/register`, `/splash` → сохранённый
  адрес или `/`; `/admin` не-админу → `/`.
  `lib/app/router/app_shell.dart` (`AppShell`) скрывает пункт «Админка»
  у студентов: ветка админки последняя, поэтому индексы видимых пунктов
  совпадают с индексами веток, `selectedIndex` ограничен `math.min`.
- **core**: `lib/core/network/supabase_schema.dart` (`SupabaseTables`,
  `ProfileColumns`, `SupabaseRpc`), `supabase_client_provider.dart`
  (`@Riverpod(keepAlive: true) SupabaseClient supabaseClient`),
  `lib/core/widgets/splash_screen.dart`.
- **l10n**: добавлены `authUsernameInvalid`, `authPasswordInvalid`,
  `authRegistrationClosed`, `authRegistrationCheckFailed`,
  `profileSignOut`, `profileRoleLabel`, `profileRoleStudent`,
  `profileRoleAdmin`, `errorUnexpected`, `configMissingTitle`,
  `configMissingBody`.
- **Тесты**: 118 (было 22), покрытие auth domain+data — 93,9 %.
  Хелперы: `test/helpers/fake_auth_repository.dart` (`FakeAuthRepository`,
  `testStudent`, `testAdmin`) и `test/helpers/pump_app.dart`
  (`pumpApp`, `containerOf`). Не покрыты `fetchProfile` и
  `isRegistrationOpen` в datasource (цепочки postgrest/rpc осмысленно не
  мокаются) и `supabaseClientProvider`.

## Секреты (только локально, в git не попадают)

`supabase/seed/local/` (в .gitignore): `answers/<slug>.json` (по задаче),
`answers.local.json` (слитый файл для seed), `reference/<slug>/gen_data.py` +
`solution.py` (генераторы данных и эталонные решения). Эти файлы существуют
ТОЛЬКО на этой машине — на этапе 9 завести GitHub secret / бэкап.

## Отступления от ТЗ (озвучены пользователю)

- Seed подключается к Postgres напрямую по `SEED_DATABASE_URL` (Session Pooler),
  а не через REST + service role key: один и тот же скрипт работает с локальной
  проверочной базой и с Supabase.
- Эталонный ответ админу отдаёт RPC `admin_get_task_answer`, а не политика на
  task_answers (у таблицы вообще нет API-доступа — надёжнее буквы ТЗ).
- `Result<T>` собственный, без fpdart. Freezed пока не подключён (не нужен был).
- Ключ Supabase передаётся в SDK как `publishableKey`: параметр `anonKey`
  в `supabase_flutter` 2.17 помечен устаревшим, а `analyze --fatal-infos`
  не прощает обращения к устаревшему API. Имя переменной окружения
  (`SUPABASE_ANON_KEY`) не менялось.
- Пока статус авторизации неизвестен, показывается `/splash`, а исходный
  адрес сохраняется в параметре `from` — иначе при перезагрузке страницы
  терялась бы глубокая ссылка.

## Чего ещё нет

- Реального проекта Supabase — пользователь создаст на supabase.com и применит
  миграции (инструкция: `supabase/README.md`). Авторизация этапа 3 проверена
  только юнит- и виджет-тестами на моках; живой прогон регистрации и входа
  (включая тексты ошибок триггеров) отложен до появления проекта.
- GitHub remote, Pages, deploy/keepalive/backup/seed workflow — этап 9.
- Каталог/страница задачи, Pyodide, отправка ответов, прогресс в профиле,
  админка — этапы 4–8. Профиль пока показывает только логин, роль и выход.

## Окружение машины разработчика

- Flutter 3.41.0 / Dart 3.11 через fvm: бинарники
  `~/fvm/versions/3.41.0/bin/flutter` и `~/fvm/versions/3.41.0/bin/dart`
  (в PATH их НЕТ; версия закреплена в `.fvmrc`). `fvm use` может зависнуть на
  интерактивном вопросе — не нужен, всё уже настроено.
- PostgreSQL 17 через Homebrew (`/opt/homebrew/opt/postgresql@17/bin`) — для
  RLS-тестов. Docker/colima есть, но не запущен; Supabase CLI не установлен —
  и не нужен.
- `python3` — это Python 3.9 (без match/case); эталоны и генераторы совместимы.

## Команды

```bash
FL=~/fvm/versions/3.41.0/bin/flutter
DA=~/fvm/versions/3.41.0/bin/dart
$FL gen-l10n                       # локализация
$DA run build_runner build         # кодогенерация riverpod
$FL analyze --fatal-infos --fatal-warnings
$DA run custom_lint
$FL test
find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' \
  -print0 | xargs -0 $DA format --output=none --set-exit-if-changed  # format-check
bash supabase/tests/run_local.sh   # миграции + RLS-тесты на временном PG
```
