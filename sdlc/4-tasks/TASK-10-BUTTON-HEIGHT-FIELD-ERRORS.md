# TASK-10: Кнопки не ниже 44 на компьютере, подпись ошибки поля — целиком

## Основание

- Брак против живого дизайна (закон, «Находка — не задание»): тап-цель
  кнопок `AppTheme._minTapTarget` = 44 — [TOKEN-6](../3-design/design-system/TOKEN-6-TAP.md),
  кнопка отправки «высотой не меньше тап-цели» — [COMP-3](../3-design/design-system/COMP-3-SUBMIT-BUTTON.md);
  подпись ошибки под полем целиком — экраны [FIG-19](../3-design/FIG-19-LOGIN.md)
  «Вход» и [FIG-2](../3-design/FIG-2-REGISTER.md) «Регистрация»; «Выйти» —
  экран [FIG-10](../3-design/FIG-10-PROFILE.md) «Профиль».
- Пути UC, на экранах которых виден брак: подпись —
  [UC-10-P-03](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-03),
  [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02);
  кнопки — [UC-38-P-01](../2-specs/use-cases/UC-38-ACTOR-1-EVT-2-ENT-17-TEST-SESSION-STARTED-IN-AUTH.md#uc-38-p-01)
  («Войти», «Тестовый вход»),
  [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01)
  («Зарегистрироваться»),
  [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01)
  («Выйти»).
- Где найден брак — раунды `sdlc/6-eval/manual/2026-10-27/` (TC-3, TC-5,
  TC-6, TC-7, TC-8) и заметка `sdlc/0-vibes/raw/2026-10-27/tc-auth-slice-runs.md`.
  Бизнес-задачи нет: брак вида ставится прямо на нарушенный артефакт.

## Где работать

Первым шагом перейти в worktree задания: `EnterWorktree` с путём
`/Users/pavelsmirnov/projects/yege_wars-TASK-10`, ветка `task/TASK-10`. Все
правки, проверки и коммиты — только там. В `~/projects/yege_wars` ничего не
менять и в `main` не вливать: это делает постановщик после «принято».
Сгенерированного кода в worktree нет — начать с `pub get` и генерации из
«Проверок части 1».

## Зачем

Ручные прогоны среза «вход и роли» 2026-10-27 на локальной сборке `main`
с тестовым проектом нашли два брака вида; по поведению срез верен.

1. **Кнопки на компьютере — 36 вместо 44.** На 1440 (Chrome на macOS)
   «Войти», «Тестовый вход», «Зарегистрироваться» и «Выйти» — 36 px видимой
   высоты, область нажатия 40; у «Нет аккаунта? Зарегистрируйтесь» область
   40. На телефоне (360, Android) — 44 и 48. Тема задаёт `minimumSize` 44, но
   плотность не задана, и Flutter берёт плотность платформы: на компьютере
   она уменьшает кнопку на 8. Тесты гоняются на платформе Android и этого не
   видят — поэтому «высота не меньше 44» в
   [RESULT-TASK-8-01](../5-results/RESULT-TASK-8-01.md) верно только для
   телефона.
2. **Подпись ошибки под полем обрезана.** После неверного логина под полем —
   «Логин: 3–20 символов — латиница, цифры и по…» на 1440 и «Логин: 3–20
   символов — латиница, …» на 360, на входе и на регистрации. FIG-19 и FIG-2
   дают текст `authUsernameInvalid` целиком. Число строк ошибки не задано
   нигде, и Flutter рисует её в одну строку с многоточием. Ученики видят это
   и на опубликованном сайте.

Итог: на любой платформе кнопки темы не ниже 44, подпись ошибки любого поля
видна целиком; тесты на платформе компьютера это держат.

Вне задания: плотность остальных элементов на компьютере (чипы, поля,
навигация, `IconButton`); экраны вне среза входа — их проверят срезы
каталога, задачи и справочника; другие находки прогонов (повторные запросы,
история вкладки, доступность сообщений); дизайн-артефакты `sdlc/3-design/`.

Прочитать перед работой:
- `CLAUDE.md`; закон `sdlc/AGENTS.md`, раздел «Код ссылается на артефакты»;
- файлы основания; журналы раундов `sdlc/6-eval/manual/2026-10-27/TC-3/`
  (шаг 2, снимки 05–06) и `TC-5/`;
- код: `lib/app/theme/app_theme.dart`; `lib/features/auth/presentation/`
  (`screens/login_screen.dart`, `screens/register_screen.dart`,
  `widgets/auth_submit_button.dart`, `widgets/auth_form_card.dart`,
  `auth_field_validators.dart`);
  `lib/features/profile/presentation/screens/profile_screen.dart`;
- тесты: `test/app/theme/app_theme_test.dart`,
  `test/features/auth/presentation/login_screen_test.dart`,
  `register_screen_test.dart`, `test/features/profile/profile_screen_test.dart`,
  `test/helpers/pump_app.dart`.

Сдача — по `sdlc/5-results/AGENTS.md`, прочитать до начала работы; номер
сдачи — `python3 -m sdlc_tool next RESULT TASK-10`.

## Решения, принятые при постановке

| Когда | Вопрос | Решение |
|---|---|---|
| 2026-10-27 | Кнопки 36 px на компьютере | Владелец: «Задание: 44 везде» — брак против TOKEN-6 и COMP-3, без прохода дизайна |
| 2026-10-27 | Обрезанная подпись ошибки | Владелец: «Одно задание с 36 px» — обе правки в теме, одна приёмка |
| 2026-10-27 | Кейс взамен TC-6 | Владелец: «Да, с заданием» — [TC-10](../6-eval/manual/TC-10-REGISTRATION.md) с `supersedes: TC-6`: в шаге 8 допустим и текст сбоя запроса, как в FIG-2 |
| 2026-10-27 | Экраны вне среза входа (задача, каталог, справочник, 404) | Владелец: «Срезами позже» — в задании только кейсы входа и тесты высоты; эти экраны проверят их срезы до публикации |
| 2026-10-27 | Как поднять кнопки | Постановщик: `visualDensity: VisualDensity.standard` в `ButtonStyle` трёх тем кнопок — `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`. `ThemeData.visualDensity` не трогать: он поменял бы на компьютере чипы, поля и навигацию, а решение владельца — про кнопки |
| 2026-10-27 | Где задать строки ошибки | Постановщик: `errorMaxLines` в `inputDecorationTheme`, константа `AppTheme._errorMaxLines = 3`. Самая длинная ошибка полей, `authUsernameInvalid`, в поле карточки шириной до 400 (COMP-1) занимает две строки; третья — запас под увеличенный шрифт браузера. Число строк — поведение текста, а не значение вида: токен не нужен |
| 2026-10-27 | Какие кейсы прогоняет приёмка | Постановщик: TC-2, TC-3, TC-4, TC-5, TC-7, TC-8, TC-10 — каждый открывает вход, регистрацию или профиль; TC-2 и TC-4 получили `PASS` до того, как прогоны начали мерить кнопки. TC-9 — только API |
| 2026-10-27 | Доступы к боевой | Постановщик: не нужны — миграций нет, ссылки на `supabase/.env.local` в worktree нет |

## Исходное состояние (проверено 2026-10-27)

| Что | Состояние |
|---|---|
| Тема кнопок | `lib/app/theme/app_theme.dart` (метка TOKEN-6): `_minTapTarget = 44`; `minimumSize: Size(_minTapTarget, _minTapTarget)` в `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`; `materialTapTargetSize: MaterialTapTargetSize.padded`; `visualDensity` не задан ни в `ThemeData`, ни в стилях кнопок |
| Плотность во Flutter 3.41 | `ThemeData`: `visualDensity ??= VisualDensity.defaultDensityForPlatform(platform)` — `standard` на Android, iOS, Fuchsia, `compact` (−2, −2) на macOS, Windows, Linux. `ButtonStyleButton` берёт `visualDensity` из стиля виджета, затем из темы кнопки, затем из `ThemeData`; `compact` уменьшает `minimumSize` 44 до 36 и область нажатия 48 до 40. В вебе платформа — от браузера: на компьютере macOS, Windows или Linux |
| Замеры раундов 2026-10-27 | 1440, Chrome на macOS: «Войти», «Тестовый вход», «Зарегистрироваться», «Выйти» — 36, область 40; «Нет аккаунта? Зарегистрируйтесь» — область 40 (TC-5…TC-8). 360, платформа Android: 44, область 48 |
| Подпись ошибки | `inputDecorationTheme` без `errorMaxLines`; поля входа и регистрации — `InputDecoration(labelText: …)` с `validator` из `AuthFieldValidators`, своего `errorMaxLines` нет. Ошибка — одна строка с многоточием (TC-3, снимки 05–06; TC-6, шаг 2) |
| Карточка формы | `AuthFormCard`: ширина не больше 400 (COMP-1) |
| Кнопки темы вне среза входа | `not_found_screen.dart`, `editor_panel.dart`, `submit_panel.dart`, `task_files_panel.dart`, `catalog_filters_bar.dart`, `article_filters_bar.dart`, `reference_error_view.dart` — на компьютере они тоже станут 44 |
| Проверки на `main` `c32947d` | `flutter test` — 377 проходят; `flutter analyze --fatal-infos --fatal-warnings` и `dart run custom_lint` — 0 замечаний. Высоту кнопок не мерит ни один тест; `flutter_test` по умолчанию — платформа Android |
| Worktree `~/projects/yege_wars-TASK-10`, ветка `task/TASK-10` от `main` | это задание и TC-10 закоммичены в `main` до запуска — их не менять. Ссылки на `supabase/.env.local` нет: задание боевую не трогает |

## Часть 1. Локально

### 1.1. Кнопки не ниже 44 на любой платформе

В `app_theme.dart` — `visualDensity: VisualDensity.standard` в стилях
`filledButtonTheme`, `outlinedButtonTheme` и `textButtonTheme`.
`ThemeData.visualDensity`, `minimumSize`, `materialTapTargetSize` и
константы токенов не менять.

Тесты:

- тема, `app_theme_test.dart`: `FilledButton`, `OutlinedButton` и
  `TextButton` в `AppTheme.dark()` на платформах macOS, Windows, Linux,
  Android и iOS (`TargetPlatformVariant`) — высота не меньше 44; в имени
  теста — метка `TOKEN-6`;
- экраны на платформе macOS: `UC-38-P-01` — «Войти» и «Тестовый вход» не ниже
  44 (`login_screen_test.dart`); `UC-1-P-01` — «Зарегистрироваться» не ниже 44
  (`register_screen_test.dart`); `UC-13-P-01` — «Выйти» не ниже 44
  (`profile_screen_test.dart`).

Каждый новый тест падает на теме из `main` — вывод падения в сдачу.

### 1.2. Подпись ошибки поля — целиком

В `inputDecorationTheme` — `errorMaxLines: _errorMaxLines`, константа
`static const int _errorMaxLines = 3` с dartdoc. Полям входа и регистрации
свой `errorMaxLines` не задавать: они берут его из темы.

Тесты на окнах 360×800 и 1440×900:

- `UC-10-P-03`: на входе логин `a-b`, пароль `123`, «Войти» — у текстов
  `authUsernameInvalid` и `authPasswordInvalid` `RenderParagraph`
  с `didExceedMaxLines == false` (`login_screen_test.dart`);
- `UC-1-P-02`: то же на регистрации, «Зарегистрироваться»
  (`register_screen_test.dart`).

Тесты падают на теме из `main` — вывод падения в сдачу.

### Проверки части 1

```bash
FL=~/fvm/versions/3.41.0/bin/flutter; DA=~/fvm/versions/3.41.0/bin/dart
$FL pub get && $FL gen-l10n && $DA run build_runner build --delete-conflicting-outputs
$FL analyze --fatal-infos --fatal-warnings      # 0 замечаний
$DA run custom_lint                             # 0 замечаний
$FL test                                        # все проходят, больше 377
find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' \
  -print0 | xargs -0 $DA format --output=none --set-exit-if-changed
```

### СТОП 1

Сдача (черновик) и коротко в чат: что сделано, выводы проверок дословно,
новые тесты на теме из `main` (падают) и на теме задания (проходят).
Спросить вопросом с вариантами, коммитить ли. Без ответа «да» дальше не
идти.

Стоп-условия — остановиться и доложить, ничего не чиня самостоятельно:

- `visualDensity` в стиле кнопок не даёт 44 на платформе компьютера;
- правка меняет размеры не только кнопок темы — падают тесты других экранов;
- на 360 подписи ошибки не хватает трёх строк.

## Часть 3. Git (только после подтверждения)

Перед каждым коммитом — `python3 -m sdlc_tool views` и
`python3 -m sdlc_tool check` (0 ошибок).

Все коммиты — в ветку `task/TASK-10`.

1. **Коммит работы.** Сообщение на русском, в стиле истории. В него идут
   `lib/app/theme/app_theme.dart`, изменённые тесты и пересобранные
   производные файлы; сдача — нет. Файлы добавлять по именам: `git add -A` и
   `git add .` не использовать. Перед коммитом проверить `git status`: в
   индексе нет `reference/`, `supabase/seed/local/`, `supabase/.env.local`,
   `*.g.dart`, `lib/l10n/gen/`.
2. **Коммит — в сдачу**, раздел «Коммит работы».
3. **Отдельным коммитом — сдача** и пересобранные производные файлы,
   сообщение «Сдача TASK-10: RESULT-TASK-10-{NN}, коммит <короткий хэш>».
   Отдельного подтверждения этот коммит не требует: он входит в уже
   подтверждённый.

Ничего не пушить.

## Самопроверка перед сдачей

Перед последним СТОПом пройти самому:

- каждый пункт «Приёмки» ниже, кроме ручных кейсов, — своей командой, с
  выводом в сдачу;
- сдача по составу `sdlc/5-results/AGENTS.md`, «нет» написано явно, где
  нечего сказать;
- тесты помечены путями и `TOKEN-6`, как в части 1;
- в сдаче и в `git diff` нет ответов задач, эталонов и значений переменных
  окружения.

## Чего не делать

- Не задавать `ThemeData.visualDensity` и плотность отдельных виджетов; не
  трогать чипы, поля, навигацию, `IconButton`.
- Не менять токены и их константы (`_minTapTarget` и другие), файлы
  `sdlc/3-design/`.
- Не менять тексты l10n и код экранов входа, регистрации и профиля — только
  тему и тесты.
- Не прогонять ручные кейсы и не публиковать сайт: кейсы в приёмке прогоняет
  тестировщик постановщика.
- Не чинить найденное вне задания: записать в сдачу, раздел «Найдено вне
  задания».
- Не менять в `sdlc/` ничего, кроме своей сдачи и производных файлов.
- Не работать в основной копии `~/projects/yege_wars` и не трогать `main`.
- Не трогать `reference/`.
- Не коммитить без подтверждения.

## Приёмка

Постановщик проверит сам:

1. `git diff main...task/TASK-10 --stat` — в коммите работы только
   `lib/app/theme/app_theme.dart`, тесты в `test/` и производные файлы.
2. В `app_theme.dart` — `visualDensity: VisualDensity.standard` в трёх темах
   кнопок и `errorMaxLines: _errorMaxLines` в теме полей; `visualDensity`
   у `ThemeData` не задан.
3. Проверки Dart из «Проверок части 1» — 0 замечаний, все тесты проходят,
   их больше 377.
4. Тесты с метками `TOKEN-6`, `UC-38-P-01`, `UC-1-P-01`, `UC-13-P-01`,
   `UC-10-P-03`, `UC-1-P-02` есть и проходят; с `app_theme.dart` из `main` они
   падают — постановщик проверит подменой файла в копии ветки.
5. Ручные кейсы TC-2, TC-3, TC-4, TC-5, TC-7, TC-8 и TC-10 на локальной сборке
   ветки `task/TASK-10` с тестовым проектом `yege_wars_dev` — `PASS` у
   каждого: на 1440 кнопки входа, регистрации и профиля не ниже 44, подпись
   ошибки логина целиком на 360 и 1440.
6. Сдача по составу `sdlc/5-results/AGENTS.md`; хэш в «Коммите работы»
   совпадает с `git log`; `python3 -m sdlc_tool check` — 0 ошибок.
