# Состояние проекта

Обновлено: 2026-10-07. Полное ТЗ — [SPEC.md](SPEC.md) плюс две доработки
(справочник и мини-уроки; контент в базе и Content API — их тексты прислал
пользователь в чате, ключевое зафиксировано здесь и в `docs/content-api.md`).
Выполнены этапы 1–6 из 10, клиент справочника, серверная часть доработки
«контент в базе» и импорт открытого банка ФИПИ (2026-09-22 залит в боевую
базу, 2026-10-07 залиты 199 ответов и опубликованы 139 задач). Коммиты этапов: `0a3179c` (1, каркас), `b86adc4` (2, Supabase),
`e36dfd6` (3, авторизация), `44477ec` (4, каталог), `bacbead` (5, Python),
`dc3642d` (6, отправка ответа); доработки — `84d5b85` (контент в базе),
`05e6322` (справочник); импорт банка — `2bb85b6`, `482b5a0`.

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
  `admin_get_task`, `admin_check_slug_available`; с 2026-10-07 ещё
  `admin_set_task_answer` (см. «Заливка ответов банка ФИПИ»). Вспомогательные:
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
- **Файлы**: имя, размер, предпросмотр и копирование в буфер обмена.
  Предпросмотр обрезан дважды — 10 первых строк и не больше 10 000
  символов в строке: в задании 24 весь файл лежит одной строкой на миллион
  символов, и её отрисовка вешала страницу (`filePreview`).
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

## Импорт банка ФИПИ и темы как основная ось (готово)

Задание — `~/projects/ege-informatics-2027/docs/PROMPT_IMPORT.md`, подробный
разбор прогона — [IMPORT_REPORT.md](IMPORT_REPORT.md). Выгрузка банка лежит
вне репозитория (`~/projects/ege-informatics-2027`, 574 МБ) и в git не идёт.

- **Миграции** (продолжают нумерацию, применять по порядку имён):
  `20260921100000_fipi_schema.sql` — таблицы `themes` (46 строк: 45 КЭС ФИПИ
  плюс служебная `none`) и `task_themes`, уникальная колонка
  `reference_articles.theme_code`, представление `task_articles`; у `tasks`
  номер задания стал **необязательным**, добавлены `ege_number_source`,
  `fipi_id` (unique), `fipi_short_id`, `parent_task_id`,
  `condition_incomplete`, `duplicate_of`, а `origin` принимает `fipi`;
  у `task_files` — `storage_bucket`, `storage_path`, `content_type`,
  `source_url`, `kind`, `content` стал необязательным, `size_bytes` из
  вычисляемой колонки превратился в обычную с триггером; заводится бакет
  Storage `task-assets`;
  `20260921100001_fipi_rls.sql` — политики и привилегии новых таблиц,
  запись в бакет только администратору;
  `20260921100002_fipi_functions.sql` — Content API под новую схему.
- **«У задания всегда есть тема» держит база.** Два отложенных триггера-
  ограничения (`deferrable initially deferred`): после вставки задачи и после
  удаления строки `task_themes` проверяется, осталась ли у задачи хоть одна
  тема, и если нет — ставится `none`. Проверка отложена до конца транзакции
  намеренно: импорт вставляет задачи и темы разными командами, и в середине
  транзакции задача законно без темы.
- **Справка задачи выводится через темы.** `task_articles` (security_invoker)
  соединяет `task_themes` со статьёй по `theme_code`. `task_references`
  осталась для ручных исключений; обязанности заполнять её больше нет —
  предупреждение об отсутствии главной статьи теперь появляется, только если
  справки нет и по теме.
- **Content API изменился**: `admin_upsert_task` принимает `origin = 'fipi'`,
  пустой `ege_number`, массив `themes` и задачу **без ключа `answer`** (тогда
  она может быть только черновиком). Присланный пустой ответ по-прежнему
  отклоняется — `[bad_answer]`. Новые коды ошибок: `theme_not_found`,
  `bad_number_source`. `admin_upsert_article` принимает `theme_code`,
  `admin_get_task` отдаёт `themes` и `articles`.
- **Код импорта** `tools/fipi_import/` (`html_to_md.py`, `bank.py`, `sql.py`,
  `image_size.py`) и `tools/import_fipi_bank.py`: скрипт не ходит ни в сеть,
  ни в базу, а собирает самодостаточный SQL с блоками `COPY`. Один и тот же
  файл заливается и во временную проверочную базу, и в Supabase через Session
  Pooler. Зависимостей нет: HTML разбирается на `html.parser`, размер картинки
  читается по заголовку файла (bs4, lxml и Pillow на машине не установлены).
  Юнит-тесты — `tools/tests/test_fipi_import.py`, 82 штуки.
- **Конвертер HTML → Markdown** (`html_to_md.py`) разбирался двумя кругами
  проверки агентами, разбор каждого дефекта закреплён юнит-тестом. Правила,
  которые легко сломать обратно:
  * вёрсточная обёртка Word опознаётся **по структуре**, не по `border="0"`:
    две строки, значок в шапке, тело растянуто на всю ширину. Одной лишь
    строки во всю ширину мало — ею набран столбец «Си» в таблицах с
    программами на пяти языках;
  * из таблицы выносится **только листинг**, вложенная таблица или список;
    несколько коротких абзацев в ячейке склеиваются через пробел, иначе
    таблица рассыпается в столбик значений;
  * строку делает прозой не длина, а то, что в ней одни слова: строка со
    знаком `=`, скобкой индекса или фигурной скобкой — код. Точки с запятой
    и знаков сравнения в признаке кода нет: по-русски ими пишут «(4; 2)» и
    «3 < n < 2000»;
  * `<span>` и `<font>` распускаются перед отрисовкой, иначе соседние `<b>`
    дают прогон `****`, который Markdown печатает текстом;
  * пробельный текстовый узел сохраняется между инлайн-соседями и
    пропускается между блоками; `\xa0` для `strip()` тоже пробельный;
  * служебные значки сайта отсеиваются **по размеру** (не шире 256 и не выше
    64 пикселей), а не по числу повторов: настоящая иллюстрация может
    приехать в семь заданий, а значок — в одно.
- **Проверка** `bash supabase/tests/run_import_check.sh [каталог выгрузки]`
  (по умолчанию `~/projects/ege-informatics-2027`, можно задать `FIPI_DUMP`):
  поднимает временный PostgreSQL 17, применяет миграции, заливает выгрузку,
  печатает таблицу из 26 проверок и в конце `IMPORT OK`. Ничего после себя
  не оставляет. Сейчас все 26 пунктов проходят.
- **Идентификаторы.** `tasks.id` не случайный: он получен из 32-символьного
  GUID банка (`05318E7F…FC47` → `05318e7f-3a02-…`), поэтому связи «родитель»
  и «дубль» переносятся без промежуточных таблиц, а повторный импорт даёт те
  же строки. `slug` — `fipi-<short_id в нижнем регистре>`, статьи —
  `kes-<код с дефисом>` (`3.13` → `kes-3-13`: точка не проходит валидацию).
- **Вложения — в Storage, не в базе.** 1571 файл у 668 заданий (427,5 МБ:
  архивы, таблицы, картинки) в колонку `content text` не помещается ни по
  типу, ни по лимиту 4 МБ. В `task_files` попадает адрес (`storage_bucket` +
  `storage_path` вида `fipi/files/<id>_2.zip`), содержимое отправляет
  `tools/upload_fipi_assets.py`. **Файлы залиты 2026-09-22**: 1571 объект,
  427,5 МБ, ошибок нет.
- **Импорт идёт по `tasks.json`, а не обходом каталога.** Это важно: после
  пересборки выгрузки в `assets/` осталось 790 файлов от прошлой загрузки
  (388 МБ), побайтово совпадающих с нужными. В базу и в Storage они не
  попадают. `run_import_check.sh` печатает их число отдельной строкой.
- **Картинки в условиях** записаны относительным путём внутри Storage
  (`task-assets/fipi/images/…`). Адрес проекта подставляет клиент:
  `Env.storagePublicBase` → `imageDirectory` у `AppMarkdown`. Так содержимое
  базы не привязано к конкретному проекту Supabase. Все 710 ссылок на
  вложения в условиях ведут в Storage: 608 картинок, которых не хватало в
  первой выгрузке, докачаны при пересборке 2026-09-21. Служебные значки
  сайта банка (849 вхождений) в условие не вставляются, в `task_files`
  остаются.
- **Клиент**: `TaskBrief.egeNumber` теперь `int?`, каталог и страница задачи
  показывают группу «Без номера» (`egeGroupLabel`, строка
  `catalogEgeGroupNone`). Навигации по темам в интерфейсе пока нет — сделана
  только серверная часть.
- **Известный брак выгрузки.** У 36 заданий вместо знака умножения стоит
  символ-замена `�` — он уже в `condition_html_local`, поэтому доезжает
  до `statement_md` (36) и до `title` (10). Подставлять `∙` по догадке не
  стали. Заголовок берётся из `condition_text`, и выгрузку из-за этого уже
  правили дважды: скобки в путях вложений и потерянные `<sup>`/`<sub>`
  (`221 бит` вместо `2^21`). Перезаливка чинит заголовки сама.
- **Всё импортированное — `draft`.** Ответов в банке ФИПИ нет ни у одного
  задания (`solve.php` только проверяет присланный ответ), а публикация без
  проверенного эталона запрещена схемой. Статьи справочника (45 штук из
  `handbook.json`) при этом опубликованы: ответов в них нет.
- **Тесты**: `rls_tests.sql` — 72 проверки (было 63), новый раздел
  «(о) Темы кодификатора». Тестов Flutter — 238 (было 232).

### Нумерация 2026 против ТЗ

В [SPEC.md](SPEC.md) (строки 44–48) записана нумерация КЕГЭ-2027: задание 10 —
маска подсети, 13 — анализ хода алгоритма. Импортирована нумерация **2026**,
восстановленная по спецификации ЕГЭ-2026: там задание 10 — «Поиск в текстовом
документе» (КЭС 4.6), а маска подсети — задание 13 (КЭС 1.2). Причина простая:
документов ЕГЭ-2027 у ФИПИ на дату выгрузки (2026-09-17) нет.

Чтобы пересчёт не затёр ручные правки, у задачи есть `ege_number_source`:
`fipi-spec-2026` — номер восстановлен по спецификации, `manual` — проставлен
человеком. Номер есть у 2018 заданий, у 457 его нет вовсе: это типы, которых
в действующей структуре КИМ не осталось (язык запросов поискового сервера,
трассировка массива A и подобное). Такие задания доступны только через темы.

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
- Импортирована нумерация заданий ЕГЭ-2026, а не 2027 из ТЗ: документов 2027
  у ФИПИ нет. Источник номера хранится в `tasks.ege_number_source`.
- Вложения банка ФИПИ лежат в Supabase Storage, а не в `task_files.content`:
  427,5 МБ архивов и таблиц в колонку `text` не помещаются. Текстовые файлы
  собственных задач по-прежнему в базе — так они попадают в дамп при бэкапе.
- `admin_upsert_task` принимает задачу без ключа `answer` (только черновиком):
  иначе администратор не смог бы сохранить ни одну задачу банка, где ответов
  нет ни у одной. Присланный пустой ответ отклоняется как прежде.
- Заголовок статьи справочника взят из первой строки `article_markdown`,
  а не из поля `title` выгрузки: там полная формулировка КЭС до 607 символов,
  она не помещается ни в карточку, ни в ссылку `[[slug]]`. Полная
  формулировка лежит в `themes.title`.

## Боевая база: банк залит 2026-09-22

- Три миграции банка применены к проекту `hzbfdupqouteerbrrikm`
  (`20260921100000_fipi_schema`, `..._fipi_rls`, `..._fipi_functions`).
  Журнала миграций в проекте нет, они применяются вручную через psql
  по Session Pooler.
- Залито 2475 заданий, 46 тем, 7071 связь, 45 статей справочника,
  1571 запись о вложениях. Все задания — `draft`. База занимает 21 МБ.
- В Storage `task-assets` 1571 объект, 427,5 МБ — 43% бесплатного гигабайта.
  Публичные адреса работают, клиент собирает их из `Env.storagePublicBase`.
- В базе с 2026-09-18 лежала одна ручная задача `e24-longest-run`
  (`origin = 'human'`, опубликована). Импорт её не трогает — удаляются только
  строки с `origin = 'fipi'`. Из-за неё шесть пунктов `import_checks.sql`
  на боевой дают +1: файл написан под пустую базу и считает все задачи,
  а не только импортированные. Подробности и разбивка по происхождению —
  в `docs/DEPLOY_REPORT.md`.
- Дамп базы до заливки: `~/backups/yege_wars/before-fipi-20260922-180036.sql`
  (вне репозитория).

## Закрытие импорта банка (2026-10-06)

Задание — [PROMPT_CLOSE_IMPORT.md](PROMPT_CLOSE_IMPORT.md).

- **Шим повторяет права по умолчанию Supabase.** В `shim_local.sql` добавлены
  три строки `pg_default_acl` боевой базы — владелец `postgres`, схема
  `public`: все права на таблицы, последовательности и функции для `anon`,
  `authenticated`, `service_role`. Права остальных владельцев и схем
  не переносились. Локальная матрица прав после миграций совпала с боевой
  построчно.
- **Лишние права оказались не только у `task_articles`.** У `authenticated`
  остались запись в `profiles`, `app_settings`, `tasks_public`;
  TRUNCATE, REFERENCES, TRIGGER, MAINTAIN — у всех таблиц; всё на
  `audit_log_id_seq` у обеих ролей; EXECUTE на служебные функции
  (`assert_content_admin`, триггерные, `ensure_task_has_theme`) — частью
  от Supabase, частью от PUBLIC. Дыры через API не было: запись отсекали RLS
  и права на `tasks`, TRUNCATE и последовательности через REST недоступны.
- **Миграция** `20261006100000_revoke_excess_privileges.sql` снимает у
  `anon` и `authenticated` всё с 11 таблиц и представлений, последовательности
  и 8 служебных функций, затем выдаёт задуманное. Итог: 11 объектов на чтение
  (`app_settings` — ещё update), колонки `tasks`, 25 функций (анониму — только
  `is_registration_open`). Права по умолчанию на будущие объекты не менялись:
  новая миграция должна снимать лишнее сама.
- **Тест `rls_tests.sql`, раздел (п)**: права на `task_articles` и полная
  матрица прав обеих ролей на объекты `public`. Новая таблица или функция
  без явных прав этот тест не пройдёт — ожидаемое дописывается в тест.
  Проверок 75 (было 72). Без миграции тест падает.
- **Темы задач проекта.** В `task.yaml` всех 10 задач — `themes` (КЭС номера
  по плану КИМ-2026). `tools/import_repo_tasks.py` передаёт их в payload,
  без тем подготовка падает с ошибкой, в том числе в `--dry-run`. Тесты —
  `tools/tests/test_import_repo_tasks.py`. Чтобы работала команда
  `python3 -m unittest discover -s tools/tests -t .`, у `tools/` и
  `tools/tests/` появились пустые `__init__.py`; тестов 85.
- **`import_checks.sql` верна на любой базе**, а не только на пустой: пункты,
  сверяющие число с выгрузкой, считают только банк (`origin = 'fipi'`,
  статьи с темой), инварианты — всю базу. Что считает пункт, видно в колонке
  «Охват». Ожидаемые числа не менялись.
- `docs/content-api.md` описывает `themes` у задачи и `theme_code` у статьи.
- **Боевая база, 2026-10-06**: миграция применена, `e24-longest-run`
  перезалита через Content API с темой 3.9 (тот же `id`, `published`, эталон
  сверен, содержимое не менялось). Матрица прав — 37 строк, как в тесте;
  `import_checks.sql` — 26 из 26. Дамп до изменений (с правами):
  `~/backups/yege_wars/before-close-import-20261006-133821.sql`. Выводы «до»
  и «после» — `docs/DEPLOY_REPORT.md`, «Хвосты закрыты».

## Заливка ответов банка ФИПИ (2026-10-07)

Задание — [PROMPT_IMPORT_ANSWERS.md](PROMPT_IMPORT_ANSWERS.md), отчёт —
[IMPORT_ANSWERS_REPORT.md](IMPORT_ANSWERS_REPORT.md). Ответы покрывающего
набора решены и подтверждены банком раньше
([SOLVE_REPORT.md](SOLVE_REPORT.md)); они лежат только в выгрузке
`~/projects/ege-informatics-2027/solutions.json`, в git их нет.

- **RPC `admin_set_task_answer(payload)`** (миграция
  `20261007100000_set_task_answer.sql`): `slug`, `answer`, `answer_format`,
  `reference_solution`, `answer_explanation` (нет ключа — разбор не
  меняется). Меняет только формат, эталон, разбор и ответ в `task_answers`,
  снимает отметку сверки; опубликованная задача уходит в `review`, черновик
  остаётся черновиком. Файлы, темы, связи, условие не трогает — в отличие
  от `admin_upsert_task`, который у задачи банка стёр бы ссылки на вложения
  в Storage. Ошибки — существующие коды (`bad_payload`, `not_found`,
  `bad_answer_format`, `bad_answer`, `missing_reference_solution`), ответ
  в текст ошибки не попадает. Пишет `audit_log` как `set_answer`.
- **Тесты**: раздел (р) в `rls_tests.sql` — права, неизменность файлов
  (с адресом в Storage) и тем, статусы, каждая ошибка, закрытость ответа
  для ученика; функция в матрице (п). Проверок 104 (было 75).
- **`import_checks.sql`**: пункты 23–25 ждут параметры `published_fipi`
  (23, 25) и `answered_fipi` (24); `run_import_check.sh` передаёт 0 и 0.
- **`tools/import_fipi_answers.py`** (стандартная библиотека, через
  `ContentClient.set_answer`): для каждой из 199 подтверждённых —
  `set_answer`, запуск эталона (`python3 -I`, каталог `assets/files/`,
  60 с), `verify_reference` — несовпадение останавливает скрипт. Уже залитая
  и сверенная задача пропускается: повторный запуск ничего не пишет и не
  снимает публикацию. `--publish` публикует по правилу (подтверждена, в
  `tasks.json` нет `assets`, `parent_id`, `condition_incomplete`,
  `duplicate_of`) — ровно 139, иначе ничего; перед первой публикацией
  проверяет у всех, что файлов в базе нет, а ответ залит и сверен.
  `--slug`, `--dry-run` (без сети). Темп — не больше 50 вызовов `admin_*`
  в минуту, на `[rate_limit]` пауза 60 с. Ответы и эталоны не печатает.
  Тесты — `tools/tests/test_import_fipi_answers.py` (23), всего 108.
- **Форматы.** Табличные ответы (22) — `multi`, числа через пробел по
  строкам таблицы; последовательность 95F274 — `string`. В банке после
  заливки `multi` 29, `single` 174, `string` 2272.
- **Боевая база, 2026-10-07**: миграция применена, 199 ответов залиты
  и сверены, опубликованы 139 задач банка — без вложений и без ссылки на
  задание 19. Все 199 ответов и форматов совпадают с `solutions.json` по
  `normalize_answer`; контрольные суммы `task_files` и `task_themes` банка
  до и после те же; `import_checks.sql` с `published_fipi=139`,
  `answered_fipi=199` — 26 из 26; матрица прав — 39 строк, как в тесте.
  Ученику видно 140 задач: 139 банка и `e24-longest-run`. Дамп до изменений:
  `~/backups/yege_wars/before-answers-20261007-014001.sql`.

## Чего ещё нет

- Живого прогона регистрации и входа из приложения ещё не было: ждём, когда
  в панели выключат подтверждение почты.
- Этапы 7–10. Профиль пока показывает только логин, роль и выход; экран
  админки — заглушка.
- Клиентской части доработки «контент в базе» нет: редактора задач и статей
  в админке, очереди «Ждут проверки», кнопки «Проверить эталон» (Pyodide).
- Справка на странице задачи читает старую таблицу `task_references`
  (в боевой базе в ней 0 строк), а не представление `task_articles`, через
  которое справка идёт после импорта. Поэтому у 139 опубликованных заданий
  банка справки на странице нет.
- Навигации по темам в интерфейсе нет: экранов «тема → задания» и блока
  «Задачи по этой теме» на странице статьи. Сделана только серверная часть.
- Из 199 задач банка с ответами опубликованы 139. Остальные 60 со
  сверенными эталонами ждут клиента, который умеет файлы из Storage
  (56 задач с вложениями: файлы и картинки условия) и задание 19 (4 задачи
  номеров 20–21 ссылаются на его условие). Файлы банка почти всегда в
  архивах (`<id>_3.zip`), а условие говорит про `17.txt` — как отдавать их
  ученику, нужно решить до публикации. Три эталона читают распакованный
  RAR и на платформе без правки не запустятся (EBA2F3, 2F9ABA, 0348F9).
  Остальные 2276 заданий банка ответов не имеют.
- Подсказки о форме ответа нет. Платформа сравнивает такие ответы строкой:
  «через запятую» без пробела, цифры слитно, строчные латинские буквы
  в номере 2, кириллица в последовательности. «Взять из вывода» берёт
  последнюю строку — у табличных ответов (номер 25, до 9 строк) этого мало.
- `normalize_answer` срезает с краёв только пробелы: ответ с переводом
  строки на конце для числового формата не совпадёт, для `string` получит
  пробел на конце. Клиент отправляет ответ как есть.
- Из задач проекта в боевой базе только `e24-longest-run`; остальные девять
  лежат в `tasks/`, `tools/import_repo_tasks.py --dry-run` по ним проходит.
- Статей справочника проекта не написано ни одной (нужны минимум
  file-reading, regex-basics, recursion-memo, graph-paths, sorting-key).
  45 статей по темам кодификатора приехали с импортом банка ФИПИ.
  Черновики `file-reading` и `string-scan` лежат в `reference/` в корне,
  вне git, и ни к чему не подключены.
- GitHub remote, Pages, deploy/keepalive/backup/seed workflow и
  еженедельная выгрузка базы в git (бэкап банка задач) — этап 9.

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

# импорт банка ФИПИ (выгрузка вне репозитория)
python3 tools/tests/test_fipi_import.py            # юнит-тесты импорта
bash supabase/tests/run_import_check.sh            # миграции + импорт + приёмка
python3 tools/import_fipi_bank.py --out /tmp/fipi.sql   # собрать SQL импорта
psql "$SEED_DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/fipi.sql
set -a; . supabase/.env.local; set +a
python3 tools/upload_fipi_assets.py --dry-run      # заливка вложений в Storage

# ответы банка ФИПИ (solutions.json выгрузки, вне репозитория)
python3 -m unittest discover -s tools/tests -t .   # все тесты tools/
python3 tools/import_fipi_answers.py --dry-run     # эталоны без сети: 199 и 139
python3 tools/import_fipi_answers.py               # заливка; повтор безопасен
python3 tools/import_fipi_answers.py --publish     # публикация 139
```
