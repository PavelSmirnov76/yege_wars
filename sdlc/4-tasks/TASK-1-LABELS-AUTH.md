# TASK-1: Метки среза «авторизация и роли» и недостающие тесты

## Основание

- Регистрация — [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01), [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02), [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03), [UC-1-P-04](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-04), [UC-1-P-05](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-05).
- Профиль — [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01).
- Раздел администратора — [UC-5-P-01](../2-specs/use-cases/UC-5-ACTOR-2-EVT-5-ENT-2-SECTION-SHOWN-IN-AUTH.md#uc-5-p-01), [UC-5-P-02](../2-specs/use-cases/UC-5-ACTOR-2-EVT-5-ENT-2-SECTION-SHOWN-IN-AUTH.md#uc-5-p-02).
- Действие администратора без роли — [UC-6-P-01](../2-specs/use-cases/UC-6-ACTOR-2-EVT-6-ENT-2-ACTION-DENIED-IN-AUTH.md#uc-6-p-01).
- Открыть или закрыть регистрацию — [UC-7-P-01](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-01), [UC-7-P-02](../2-specs/use-cases/UC-7-ACTOR-3-EVT-7-ENT-4-REGISTRATION-SWITCHED-IN-MANAGEMENT.md#uc-7-p-02).
- Назначить или снять роль администратора — [UC-8-P-01](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-01), [UC-8-P-02](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-02), [UC-8-P-03](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-03), [UC-8-P-04](../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-04).
- Задать пароль пользователю — [UC-9-P-01](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01), [UC-9-P-02](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-02), [UC-9-P-03](../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-03).
- Вход — [UC-10-P-01](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01), [UC-10-P-02](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-02), [UC-10-P-03](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-03), [UC-10-P-04](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-04), [UC-10-P-05](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-05), [UC-10-P-06](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-06).
- Выход — [UC-11-P-01](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-01), [UC-11-P-02](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-02), [UC-11-P-03](../2-specs/use-cases/UC-11-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-11-p-03).
- Токены — [TOKEN-1](../3-design/design-system/TOKEN-1-COLOR.md), [TOKEN-2](../3-design/design-system/TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](../3-design/design-system/TOKEN-3-SPACING.md), [TOKEN-4](../3-design/design-system/TOKEN-4-RADIUS.md), [TOKEN-5](../3-design/design-system/TOKEN-5-BREAKPOINT.md), [TOKEN-6](../3-design/design-system/TOKEN-6-TAP.md); компоненты — [COMP-1](../3-design/design-system/COMP-1-AUTH-FORM-CARD.md), [COMP-2](../3-design/design-system/COMP-2-AUTH-MESSAGE.md), [COMP-3](../3-design/design-system/COMP-3-SUBMIT-BUTTON.md), [COMP-4](../3-design/design-system/COMP-4-NAVIGATION.md).
- Бизнес-задачи — [BT-1](../1-business-tasks/planning/BT-1-PLANNING-REGISTRATION.md), [BT-2](../1-business-tasks/planning/BT-2-PLANNING-SIGN-IN.md), [BT-3](../1-business-tasks/planning/BT-3-PLANNING-ROLE-ACCESS.md), [BT-4](../1-business-tasks/planning/BT-4-PLANNING-ACCOUNT-MANAGEMENT.md).

## Где работать

Первым шагом перейти в worktree задания: `EnterWorktree` с путём
`/Users/pavelsmirnov/projects/yege_wars-TASK-1`, ветка `task/TASK-1`. Все правки,
проверки и коммиты — только там. В `~/projects/yege_wars` ничего не менять и в
`main` не вливать: это делает постановщик после «принято». Сгенерированного
кода в worktree нет — начать с `pub get` и генерации из «Проверок части 1».

## Зачем

Проходы 1 и 2 описали срез «авторизация и роли» как построено: 27 путей в
UC выше, токены и компоненты. Но в коде и тестах нет ни одной метки, поэтому
сводка `sdlc/6-eval/DASHBOARD.md` показывает все 27 путей «НЕ
ПРОВЕРЕНО», а бизнес-задачи BT-1…BT-4 не закрываются. Метки связывают код и
тесты со спеками (закон `sdlc/AGENTS.md`, «Код ссылается на артефакты»).
Задание ставит метки и дописывает тесты путям, у которых их нет. Поведение
продукта не меняется.

Вне задания: расхождения с ТЗ из `sdlc/0-vibes/raw/2026-10-08/as-built-auth.md`
(чтение чужих профилей, экраны администратора) — их не чинить.

Прочитать перед работой: `CLAUDE.md`; закон `sdlc/AGENTS.md`, раздел «Код
ссылается на артефакты»; файлы UC из «Основания»; токены и компоненты
`sdlc/3-design/design-system/`; `sdlc_tool/README.md`, разделы «Метки в коде» и
«Прогон run» — как скрипт читает метки. Сдача — по `sdlc/5-results/AGENTS.md`,
прочитать до начала работы; номер сдачи — `python3 -m sdlc_tool next RESULT TASK-1`.

## Решения, принятые при постановке

| Когда | Вопрос | Решение |
|---|---|---|
| 2026-10-08 | Что входит кроме разметки? | Владелец: метки и недостающие тесты путям среза |
| 2026-10-08 | Метки в применённых миграциях? | Постановщик: нет — применённые миграции не редактируют. UC, реализованные только в базе (UC-6…UC-9), метятся только в тестах; «Где реализован» у них останется «не покрыто» |
| 2026-10-08 | Формат метки теста Dart | Постановщик: в начале описания — метки путей, которые тест проверяет, через запятую: `test('UC-10-P-02: неверный пароль …')`, `test('UC-10-P-01, UC-11-P-01: …')` |
| 2026-10-08 | Формат метки теста SQL | Постановщик: строка-комментарий `-- UC-n-P-nn` перед проверкой в `supabase/tests/rls_tests.sql` |
| 2026-10-08 | Метки в коде | Постановщик: `UC-n` — в doc-комментарии класса или функции, которая реализует UC (use case, экран, guard роутера, оболочка с меню); `TOKEN-n` — в doc-комментарии класса файла темы; `COMP-n` — в doc-комментарии класса виджета компонента |

## Исходное состояние (проверено 2026-10-08)

| Что | Состояние |
|---|---|
| Проверки | `analyze` и `custom_lint` — 0 замечаний; `dart format` — 0 изменений; `flutter test` — 271, все проходят; `run_local.sh` — `RLS OK`; `python3 -m sdlc_tool check` — 0 ошибок |
| Метки | в `lib/`, `test/`, `web/`, `supabase/` нет ни одной |
| Тесты среза | `test/features/auth/` (10 файлов), `test/features/profile/profile_screen_test.dart`, `test/app/router/app_router_test.dart`, `test/core/widgets/adaptive_navigation_scaffold_test.dart`; в `supabase/tests/rls_tests.sql` — разделы (а) регистрация, (и) `admin_*` под учеником, (л) `admin_reset_password` |
| Известные пути без тестов | UC-8 целиком: `admin_set_role` не проверяется ничем; UC-7: раздел (а) меняет `registration_open` суперпользователем, а не администратором через RLS, — нет проверки ни P-01 (администратор меняет флаг), ни P-02 (не-администратор — 0 строк, значение прежнее). Остальное — выяснить при разметке |
| Токены ↔ файлы темы | TOKEN-1 — `app_colors.dart`, TOKEN-2 — `app_typography.dart`, TOKEN-3 — `app_spacing.dart`, TOKEN-4 — `app_radius.dart`, TOKEN-5 — `app_breakpoints.dart`, TOKEN-6 — `app_theme.dart` (всё в `lib/app/theme/`) |
| Компоненты ↔ виджеты | COMP-1 — `AuthFormCard`, COMP-2 — `AuthMessage`, COMP-3 — `AuthSubmitButton` (`lib/features/auth/presentation/widgets/`), COMP-4 — `AdaptiveNavigationScaffold` (`lib/core/widgets/`) и `AppShell` (`lib/app/router/app_shell.dart`) |
| Ловушки | применённые миграции `supabase/migrations/` не редактировать; `run` скрипта конвейера не запускать — его прогоняет постановщик при приёмке |
| Worktree `~/projects/yege_wars-TASK-1`, ветка `task/TASK-1` от `main` | это задание закоммичено в `main` до запуска — его не менять. Доступы к боевой не нужны |

## Часть 1. Локально

### 1.1. Метки тестов Dart

Пройти тесты среза. Каждому тесту, который проверяет путь UC из «Основания»,
поставить метку этого пути в начало описания. Тест, который проверяет
устройство, а не путь (разбор DTO, отдельная функция), остаётся без метки.
Меняется только описание теста, не его тело.

### 1.2. Метки RLS-тестов

В `supabase/tests/rls_tests.sql` поставить `-- UC-n-P-nn` перед каждой
проверкой, которая проверяет путь среза: разделы (а), (и), (л) и другие, если
найдутся.

### 1.3. Недостающие тесты

Для каждого пути из «Основания», у которого после 1.1–1.2 нет ни одного теста
с меткой, написать тест — в Dart или в `rls_tests.sql`, где путь реализован. Как
минимум:

- UC-8: P-01 — администратор назначает и снимает роль; P-02 — снять роль с
  себя — `[self_demote]`; P-03 — `[bad_role]`; P-04 — `[user_not_found]`;
- UC-7: P-01 — администратор под своей ролью меняет `registration_open`, и
  `is_registration_open()` отдаёт новое значение; P-02 — ученик пытается
  изменить флаг: 0 строк, значение прежнее;
- UC-9: P-03 — `[user_not_found]`, если такой проверки нет.

Каждая новая проверка — с меткой, и она не холостая: если временно перевернуть
ожидание, проверка падает. Показать это в сдаче и вернуть как было. Путь,
который тестом не проверить (например, живая регистрация на боевой), — в сдачу
с причиной.

### 1.4. Метки в коде

- `UC-n` — у кода, который реализует UC среза в клиенте: use case, экраны
  входа, регистрации и профиля, guard роутера, оболочка с пунктом «Админка».
- `TOKEN-n` — в каждом из шести файлов темы, по таблице «Исходного состояния».
- `COMP-n` — у классов виджетов, по таблице «Исходного состояния».

Только комментарии: код не меняется.

### Проверки части 1

```bash
FL=~/fvm/versions/3.41.0/bin/flutter; DA=~/fvm/versions/3.41.0/bin/dart
$FL pub get
$FL gen-l10n && $DA run build_runner build --delete-conflicting-outputs
$FL analyze --fatal-infos --fatal-warnings      # 0 замечаний
$DA run custom_lint                             # 0 замечаний
$FL test                                        # все, не меньше 271
find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' \
  -print0 | xargs -0 $DA format --output=none --set-exit-if-changed
bash supabase/tests/run_local.sh                # RLS OK
python3 -m sdlc_tool views && python3 -m sdlc_tool check   # 0 ошибок
```

### СТОП 1

Сдача (черновик) и коротко в чат: что сделано, выводы проверок дословно,
таблица «путь → тесты с его меткой» и пути без тестов с причиной. Спросить
вопросом с вариантами, коммитить ли. Без ответа «да» дальше не идти.

Стоп-условия — остановиться и доложить, ничего не чиня:
- тест обнаруживает, что код ведёт себя не так, как написано в пути UC;
- путь нельзя проверить без изменения кода продукта.

## Часть 3. Git (только после подтверждения)

Все коммиты — в ветку `task/TASK-1`. Перед каждым коммитом —
`python3 -m sdlc_tool views` и `python3 -m sdlc_tool check` (0 ошибок).

1. **Коммит работы.** Сообщение на русском, в стиле истории. В него идут
   изменённые тесты, комментарии-метки в `lib/` и пересобранные производные
   файлы; сдача — нет. Файлы добавлять по именам: `git add -A` и `git add .` не
   использовать. Перед коммитом проверить `git status`: в индексе нет
   `reference/`, `supabase/seed/local/`, `supabase/.env.local`, `*.g.dart`,
   `lib/l10n/gen/`.
2. **Коммит — в сдачу**, раздел «Коммит работы».
3. **Отдельным коммитом — сдача** и пересобранные производные файлы, сообщение
   «Сдача TASK-1: RESULT-TASK-1-01, коммит <короткий хэш>». Отдельного
   подтверждения этот коммит не требует: он входит в уже подтверждённый.

Ничего не пушить.

## Самопроверка перед сдачей

Перед СТОПом 1 пройти самому:

- каждый пункт «Приёмки» ниже — своей командой, с выводом в сдачу;
- сдача по составу `sdlc/5-results/AGENTS.md`, «нет» написано явно, где нечего
  сказать; в «Выполнено» — таблица «путь → тесты с его меткой»;
- в сдаче и в `git diff` нет ответов задач, эталонов и значений переменных
  окружения.

## Чего не делать

- Не менять поведение кода: в `lib/` — только комментарии-метки.
- Не редактировать `supabase/migrations/`.
- Не переименовывать и не переносить файлы и классы.
- Не чинить найденное вне задания: записать в сдачу, раздел «Найдено вне
  задания».
- Не менять в `sdlc/` ничего, кроме своей сдачи и производных файлов.
- Не работать в основной копии `~/projects/yege_wars` и не трогать `main`.
- Не трогать `reference/`.
- Не коммитить без подтверждения.

## Приёмка

Постановщик проверит сам:

1. Полный набор проверок Dart зелёный, тестов не меньше 271 плюс новые;
   `run_local.sh` — `RLS OK` вместе с новыми проверками; новые проверки не
   холостые.
2. `git diff main...task/TASK-1` — изменены только тесты, комментарии в `lib/`,
   `supabase/tests/` и `sdlc/` (сдача и производные файлы); `supabase/migrations/`
   не тронут.
3. `python3 -m sdlc_tool check` — 0 ошибок.
4. `python3 -m sdlc_tool run` в worktree: на сводке у каждого из 27 путей
   вердикт `PASS`, кроме путей, перечисленных в сдаче с причиной.
5. Индексы: «Где реализован» — не «не покрыто» у UC-1, UC-4, UC-5, UC-10, UC-11,
   у TOKEN-1…TOKEN-6 и COMP-1…COMP-4; раздела «Файлы темы без метки» нет.
6. Сдача по составу `sdlc/5-results/AGENTS.md`; хэш в «Коммите работы»
   совпадает с `git log`.
