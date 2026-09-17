# Состояние проекта

Обновлено: 2026-09-17. Полное ТЗ — [SPEC.md](SPEC.md). Выполнены этапы 1–2 из 10.
Коммиты: `0a3179c` (этап 1, каркас), `b86adc4` (этап 2, Supabase).

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

## Чего ещё нет

- Реального проекта Supabase — пользователь создаст на supabase.com и применит
  миграции (инструкция: `supabase/README.md`). До этого живая проверка
  авторизации невозможна — код этапа 3 тестируется юнит/виджет-тестами на моках.
- GitHub remote, Pages, deploy/keepalive/backup/seed workflow — этап 9.
- Каталог/страница задачи, Pyodide, отправка ответов, профиль, админка — этапы 4–8.

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
