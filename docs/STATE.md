# Состояние проекта

Обновлено: 2026-09-17. Полное ТЗ — [SPEC.md](SPEC.md) плюс две доработки
(справочник и мини-уроки; контент в базе и Content API — их тексты прислал
пользователь в чате, ключевое зафиксировано здесь и в `docs/content-api.md`).
Выполнены этапы 1–3 из 10 и серверная часть доработки «контент в базе».
Коммиты: `0a3179c` (этап 1, каркас), `b86adc4` (этап 2, Supabase),
`e36dfd6` (этап 3, авторизация).

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
- **Seed**: Dart-пакет `supabase/seed/seed_tasks/` удалён вместе с доработкой
  «контент в базе» (он писал в таблицы напрямую и в колонки, которых больше
  нет). Его работу делает `tools/import_repo_tasks.py` через Content API.
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

## Доработка «контент в базе» — сервер (готово)

Источник истины по задачам и статьям — база, а не репозиторий. Писать в
таблицы напрямую нельзя никому: только через `admin_*` RPC, которые
проверяют payload, ведут журнал и работают одной транзакцией.

- **Миграции** (продолжают нумерацию, применять по порядку имён):
  `20260917130000_content_schema.sql` — у `tasks` появились `status`
  (`draft`/`review`/`published` вместо `is_published`), `reference_solution`,
  `answer_explanation`, `created_by`, `origin` (`human`/`ai`), `updated_at`,
  `reference_verified_at`; колонка `files` удалена; `ege_number` теперь 1–27;
  новые таблицы `task_files`, `reference_articles`, `task_references`,
  `audit_log`; представление `tasks_public`; настройка
  `content_writes_per_minute` (60);
  `20260917130001_content_rls.sql` — политики и привилегии;
  `20260917130002_content_functions.sql` — Content API и пересозданные
  функции этапа 2, где `is_published` заменился статусом (`submit_solution`,
  `get_user_progress`, `get_task_stats`).
- **Как закрыт эталон от учеников**: `revoke all on tasks`, затем
  `grant select` на перечисленные колонки — `reference_solution` и
  `answer_explanation` не выдаются вообще, даже прямым запросом; строки
  фильтрует RLS (`status = 'published'` или админ). Ученику предназначено
  представление `tasks_public` (`security_invoker = on`), админу — RPC
  `admin_get_task`.
- **Content API** (все security definer, роль admin проверяется внутри):
  `admin_upsert_task`, `admin_upsert_article`, `admin_verify_reference`,
  `admin_set_task_status`, `admin_delete_task`, `admin_list_tasks`,
  `admin_get_task`, `admin_check_slug_available`. Вспомогательные:
  `assert_content_admin` (роль + лимит 60 записей в минуту), `write_audit`,
  `is_task_visible`, `is_article_visible`, `touch_updated_at`.
- **Правило публикации**: `admin_upsert_task` не принимает `status:
  published`. Публикация только через `admin_set_task_status` и только после
  `admin_verify_reference`, где база сама сравнивает вывод эталона с ответом
  (`normalize_answer`). Любое изменение задачи снимает отметку проверки.
- **Ошибки** — прежний формат `[код] Русский текст`. Новые коды: bad_payload,
  bad_slug, bad_title, bad_summary, short_statement, short_content,
  bad_number, bad_ege_number, bad_difficulty, bad_answer_format, bad_answer,
  bad_status, bad_origin, bad_relevance, bad_level, bad_reading_minutes,
  missing_reference_solution, not_verified, bad_filename, file_too_large,
  files_too_large, article_not_found, not_found.
- **Лимиты**: файл ≤ 4 МБ (constraint), сумма файлов задачи ≤ 8 МБ (RPC),
  60 изменений контента в минуту на аккаунт (`app_settings`).
- **Инструменты**: `tools/content_client.py` — клиент API на стандартной
  библиотеке (CLI: list/get/upsert-task/upsert-article/verify/status/publish/
  delete/check-slug), доступы только из переменных окружения;
  `tools/import_repo_tasks.py` — разовый перенос банка из `tasks/` в базу:
  запускает эталон в папке задачи, сверяет вывод с `answers.local.json`,
  грузит через API, сверяет эталон на сервере и публикует. `--dry-run`
  проверяет всё локально (сейчас проходит: 10 задач, 6 файлов, 2,5 МБ).
- **Документация для агента**: `docs/content-api.md` (авторизация сервисного
  аккаунта `<логин>@ege.local`, схемы payload, таблица ошибок, примеры curl
  и Python, порядок работы: сгенерировать → запустить эталон → взять вывод
  как ответ → review → сверка → публикует человек).
- **Тесты** `supabase/tests/rls_tests.sql`: 63 проверки (было 37). Добавлены
  идемпотентность upsert, полная замена файлов и связей, транзакционность
  (ошибка в файле не оставляет ни задачи, ни ответа), валидация payload,
  запрет админских RPC ученику, недоступность эталона/разбора/черновиков
  ученику (напрямую, через представление и через RPC), видимость файлов и
  статей только для опубликованного, журнал и лимит частоты записи.

## Боевой проект Supabase (развёрнут)

- Проект `hzbfdupqouteerbrrikm`, регион **eu-central-1**. Все шесть миграций
  применены и проверены: 9 таблиц, представление `tasks_public`, 9 политик,
  15 admin-функций, оба триггера на `auth.users`.
- **Подключаться только через Session Pooler**: прямой хост
  `db.<ref>.supabase.co` резолвится лишь в IPv6, которого на машине
  разработчика нет. Рабочая строка —
  `postgresql://postgres.<ref>:<пароль>@aws-0-eu-central-1.pooler.supabase.com:5432/postgres`.
- Доступы лежат в `supabase/.env.local` (в `.gitignore`): `SUPABASE_URL`,
  `SUPABASE_ANON_KEY`, `SEED_DATABASE_URL`, `CONTENT_API_LOGIN`,
  `CONTENT_API_PASSWORD`. Адрес и публичный ключ также заданы значениями по
  умолчанию в `lib/core/config/env.dart` (по просьбе пользователя; ключ
  публичный, защита — RLS) и переопределяются через `--dart-define`.
- Проверено живьём: `is_registration_open` отвечает анониму `true`,
  `tasks_public` анониму — `42501 permission denied`.

### Что выяснилось про Supabase Auth

- **Ошибки триггеров БД доходят до клиента полностью.** Ответ GoTrue:
  `{"code":400,"error_code":"P0001","msg":"[invalid_username] Логин должен…"}`.
  Значит `AuthErrorMapper` разбирает код и показывает русский текст из базы —
  запасная ветка про «Database error saving new user» остаётся страховкой.
- **Подтверждение почты в проекте пока включено** — регистрация не работает:
  Supabase пытается отправить письмо на технический адрес и упирается в лимит
  (`over_email_send_rate_limit`). Выключается в панели:
  Authentication → Sign In / Providers → Email → Confirm email → Save.
- Валидатор адресов иногда отвечает `email_address_invalid` на `@ege.local`,
  а через минуту тот же адрес принимает. Если поведение станет постоянным,
  придётся сменить технический домен на существующий (тогда меняется только
  константа `SupabaseAuthRemoteDataSource.emailDomain` и документация).
- Сервисный аккаунт `ai_author` ещё не заведён: создать обычной регистрацией
  после выключения подтверждения почты, затем
  `update profiles set role = 'admin' where username = 'ai_author';`.

## Справочник — клиент (готово)

Серверная часть (таблицы, RLS, `admin_upsert_article`, связи с задачами)
описана выше. Здесь — то, что видит ученик.

- **Разметка** `lib/core/markdown/`: `AppMarkdown` — единый рендерер для
  условий задач и статей (пакет `flutter_markdown_plus`, форк свёрнутого
  `flutter_markdown`); `PythonHighlighter` — свой разбор Python на токены
  (готовые пакеты подсветки заброшены, а язык нужен ровно один);
  `CodeBlock` — блок кода с горизонтальной прокруткой (перенос строк в коде
  менял бы смысл отступов); `WikiLinkSyntax` — ссылки `[[slug]]`.
- **Правила ссылок `[[slug]]`**: известный slug превращается в ссылку с
  заголовком статьи, неизвестный — в обычный текст; внутри блоков и участков
  кода подстановка не работает. Заголовки берутся из `articleTitlesProvider`.
  Тонкость: `MarkdownBody` разбирает текст заново только при смене `data`,
  поэтому у него ключ, учитывающий словарь заголовков, — иначе приехавший
  позже словарь не применился бы.
- **Фича** `lib/features/reference/`: domain (`ArticleBrief`,
  `ReferenceArticle`, `ArticleFilter`, `ArticleLevel`, `ArticleFacets`,
  репозиторий, три use case'а), data (DTO, datasource поверх
  `reference_articles`, репозиторий), presentation (контроллер фильтра,
  провайдеры списка, статьи, заголовков и значений фильтров; экраны списка
  и статьи; карточка, сведения, панель фильтров, сообщение об ошибке).
- **Отбор считает база**: `contains` по `ege_numbers` и `tags`, `eq` по
  уровню, `or(ilike)` по заголовку и описанию; строка поиска очищается от
  символов, ломающих синтаксис PostgREST. Ввод в поиске задерживается на
  300 мс, чтобы не дёргать базу на каждую букву.
- **Маршруты**: `/reference` и `/reference/<slug>` в отдельной ветке
  оболочки; пункт «Справочник» стоит между каталогом и профилем, админская
  ветка по-прежнему последняя (на этом держится скрытие пункта у учеников).
- **Общий маппер ошибок**: `lib/core/network/supabase_error_mapper.dart` —
  сеть, PostgREST и формат `[код] Текст`; `AuthErrorMapper` теперь только
  добавляет коды GoTrue и падает в общий маппер.
- **Тесты**: 168 всего (было 139). Новое: разбор Python (11 проверок),
  ссылки `[[slug]]` (5), виджет разметки (4), DTO и поиск (7), репозиторий
  (9), фильтр и его контроллер (5), экран списка (6), страница статьи (3).

### Чего в справочнике ещё нет

- Статей — их пишет отдельный агент через `admin_upsert_article`;
  раздел проверен на фикстурах, на живых данных не отлаживался.
- Блока «Задачи по этой теме» на странице статьи и вкладки «Справка» на
  странице задачи: обе части упираются в каталог и страницу задачи (этап 4).
- Кнопки «Скопировать в редактор» у примеров кода — нужен редактор (этап 5).
- Счётчика прочитанных статей в профиле (этап 7).

## Этап 4 — каталог и страница задачи (готово)

- **Domain** `lib/features/tasks/domain/`: `TaskBrief`, `TaskDetail`,
  `TaskFile`, `TaskArticleLink` (+ `ArticleRelevance`), `CatalogItem`
  (задача + мой прогресс + статистика), `TaskDifficulty`, `TaskProgress`,
  `TaskStats`, `TaskFilter`; репозиторий и три use case'а (каталог, задача,
  номера заданий).
- **Data**: datasource поверх представления `tasks_public`, таблиц
  `task_files`, `task_references`, `submissions` и функции `get_task_stats`.
  Каталог собирается из трёх запросов, пущенных одновременно
  (`Future.wait`): задачи, статистика, мои попытки.
- **Прогресс по задаче** считается по своим попыткам (`не начата` /
  `есть попытки` / `решено`). В базе такого признака нет, поэтому отбор по
  нему выполняется на клиенте — это единственный фильтр, который не считает
  база; остальные (`ege_number`, `difficulty`, поиск по названию) уходят в
  запрос. Попытки запрашиваются с явным `user_id = auth.uid()`: политика
  пускает ещё и к чужим опубликованным решениям.
- **Presentation**: каталог с поиском (задержка ввода 300 мс), чипами
  номеров, сложности и состояния решения, карточками с меткой сложности,
  статусом и процентом решивших, группировкой по номеру задания; страница
  задачи — на широком экране две колонки (условие и правая панель), на узком
  вкладки «Условие / Справка / Файлы».
- **Справка на странице задачи**: статьи из `task_references`, главные по
  теме идут первыми и раскрыты, остальные свёрнуты; переход ведёт в раздел
  «Справочник». Условие рисуется тем же `AppMarkdown`, что и статьи, поэтому
  в нём работают ссылки `[[slug]]`.
- **Файлы**: имя, размер, первые строки и копирование в буфер обмена.
  Скачивание файла и запись в виртуальную ФС Pyodide — этап 5.
- **Маршрут** задачи: `/task/<slug>` внутри ветки каталога.
- **Проверено на живой базе** (под токеном `ai_author`): каталог,
  `get_task_stats`, свои попытки, файлы задачи и вложенная выборка
  `task_references → reference_articles` — PostgREST принимает связь по
  внешнему ключу, отдельный запрос не нужен.
- **Тесты**: 190 всего (было 168). Новое: репозиторий каталога (8 проверок),
  экран каталога (7), страница задачи и размер файла (7).

### Чего на странице задачи ещё нет

- Редактора кода, запуска и консоли (этап 5) — на широком экране под них
  уже выделена правая колонка с пояснением.
- Отправки ответа, истории попыток и чужих решений (этап 6).
- Скачивания файла: на вебе это отдельная возня с Blob, а файлы всё равно
  понадобятся Pyodide на этапе 5 — сделаю там заодно.

## Этап 5 — выполнение Python (готово)

- **Воркер** `web/pyodide_worker.js`: **модульный** Web Worker
  (`type: 'module'`), тянет Pyodide **314.0.7** (Python 3.14) с jsDelivr
  через динамический `import('pyodide.mjs')`, при неудаче — с unpkg. Протокол
  сообщений: `{id, type: 'run', code, stdin, files}` в воркер,
  `{type:'loading'} | {type:'ready'} | {id, type:'result', stdout, stderr,
  failed}` обратно. Файлы задания пишутся в виртуальную ФС под настоящими
  именами (`open('24.txt')` работает как на экзамене), файлы прошлого
  запуска удаляются.
- **Интерфейс** `lib/core/python_runtime/`: `PythonRuntime`
  (`states`, `state`, `run`, `stop`, `dispose`) и `RunResult` с исходом
  `finished` / `failed` / `timedOut` / `stopped`. Реализация выбирается
  условным импортом: в браузере `PyodideRuntime`, на виртуальной машине
  Dart — заглушка (иначе тесты не собрались бы).
- **Остановка и таймаут**: прервать Pyodide изнутри нельзя — для этого нужен
  SharedArrayBuffer и заголовки COOP/COEP, которых на GitHub Pages нет.
  Поэтому «Стоп» и таймаут (60 с по умолчанию) убивают воркер и создают
  новый; сам Pyodide браузер потом берёт из своего кеша.
- **Редактор** `lib/features/editor/`: своё поле ввода с подсветкой —
  `PythonEditingController` поверх уже написанного `PythonHighlighter`.
  Пакеты-редакторы (`flutter_code_editor`, `re_editor`) не брал: подсветка
  у нас уже есть, а обычный `TextField` работает в любом мобильном браузере.
  Ctrl/Cmd+Enter запускает программу.
- **Черновики**: сохраняются локально (`shared_preferences`, ключ
  `draft.<slug>`) с задержкой 600 мс и подставляются при открытии задачи.
  В базу черновики не попадают — туда идут только отправленные попытки.
- **Скачивание файлов** `lib/core/download/`: в браузере через Blob и
  временную ссылку, вне браузера — заглушка. Содержимое уже в памяти, файл
  повторно не запрашивается.
- **Проверено на настоящем Pyodide** (Node, тот же код, что в воркере):
  чтение файла задания, удаление файлов прошлого запуска, `input()` из
  stdin, `EOFError` при пустом вводе, трассировка в сообщении об ошибке,
  разделение stdout и stderr, стандартная библиотека и
  `sys.setrecursionlimit`.
- **Тесты**: 208 всего (было 190). Новое: результат запуска, подсветка в
  поле ввода, хранилище черновиков, контроллер запуска, подписи состояний
  (14 проверок) и панель редактора на странице задачи (4).

### Почему воркер модульный (важно не откатить)

Первая версия была классическим воркером с `importScripts` — и не работала.
Проверка в настоящем Chrome 153 показала две вещи:

- `importScripts` с другого домена не выполняется вообще: падает даже
  посторонний крошечный скрипт, хотя `fetch` того же адреса отдаёт 200;
- загрузчик `pyodide.js` — небольшая обёртка, которая тянет свои части
  динамическим `import()`, а его в классическом воркере нет.

Модульный воркер с `await import(indexURL + 'pyodide.mjs')` решает обе
проблемы. Проверено сквозным прогоном в Chrome (puppeteer-core + системный
браузер): Pyodide загрузился, `open('24.txt')` вернул длину файла, `input()`
прочитал stdin, ошибок нет.

### Ограничение вывода

Воркер отдаёт не больше 20 000 символов вывода и дописывает, сколько
скрыто. Без этого `print(data)` на файле задания 24 слал в интерфейс
миллион символов, и рисование такого текста вешало страницу намертво.
Замерено в браузере: сам запуск при этом занимает 21 мс, виснет именно
отрисовка.

### Что видно в журнале

`lib/core/logging/app_logger.dart` (через `dart:developer`) пишет ход
загрузки среды и запусков; сообщения воркера пересылаются туда же. Ошибку
воркера приложение показывает целиком — с текстом браузера и адресом файла,
а не общей фразой «проверьте соединение».

### Чего в этапе 5 ещё нет

- Заглушки `turtle` для задания 6 (в Pyodide модуля нет).
- Отправки ответа и истории попыток — этап 6.

## Этап 6 — отправка ответа и решения (готово)

- **Фича** `lib/features/submissions/`: domain (`Submission`,
  `SubmitResult`, репозиторий, use case с проверкой пустого ответа), data
  (datasource поверх RPC `submit_solution` и `set_solution_published` плюс
  чтение `submissions`), presentation (контроллеры отправки и публикации,
  провайдеры своих попыток и чужих решений).
- **Проверяет ответ база**: эталон клиенту недоступен, RPC нормализует
  ответ (лишние пробелы и ведущие нули значения не имеют) и сама пишет
  попытку. Клиент показывает вердикт и ошибки в формате `[код] Текст`
  (например, лимит отправок).
- **UI**: поле ответа с кнопкой «Взять из вывода» (подставляет последнюю
  непустую строку вывода программы), крупная индикация «Верно / Неверно»,
  блок «Задача решена!» с публикацией или «Не сейчас», список своих попыток
  с переключателем публикации, вкладка и раздел «Решения».
- **Чужие решения** открываются только после своего верного ответа — это
  решает политика доступа, а не клиент. Пока ответа нет, показываем не
  «пусто», а объяснение, почему список закрыт. Свои решения из чужих
  исключаются запросом.
- **После отправки** сбрасываются кэши своих попыток, чужих решений и
  каталога: статусы «решено / есть попытки» и процент решивших
  пересчитываются сразу.
- **Проверено на живой базе** (под сервисным аккаунтом, попытки потом
  удалены): неверный ответ, верный ответ с лишними пробелами, публикация
  верного решения, отказ `[not_correct]` на публикацию неверного, чтение
  своих попыток и вложенная выборка автора `submissions → profiles`.
- **Тесты**: 228 всего (было 208). Новое: репозиторий и контроллеры
  отправки (13 проверок), панель отправки (5), список чужих решений (3).

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

- Живого прогона регистрации и входа из приложения ещё не было: ждём, когда
  в панели выключат подтверждение почты. Банк задач в базу не залит
  (`tools/import_repo_tasks.py` готов, вхолостую проходит).
- GitHub remote, Pages, deploy/keepalive/backup/seed workflow — этап 9.
- Каталог/страница задачи, Pyodide, отправка ответов, прогресс в профиле,
  админка — этапы 4–8. Профиль пока показывает только логин, роль и выход.
- Клиентской части доработок нет совсем: каталог читает `tasks_public`,
  вкладка «Справка», раздел «Справочник», редактор задач и статей в админке,
  очередь «Ждут проверки», кнопка «Проверить эталон» (Pyodide) — впереди.
- Статей справочника ещё не написано ни одной (нужны минимум file-reading,
  regex-basics, recursion-memo, graph-paths, sorting-key).
- Еженедельная выгрузка базы в git (бэкап банка задач) — этап 9.

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
