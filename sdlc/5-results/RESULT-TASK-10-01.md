# RESULT-TASK-10-01: Кнопки не ниже 44 на компьютере, подпись ошибки поля — целиком

## Задание

[TASK-10](../4-tasks/TASK-10-BUTTON-HEIGHT-FIELD-ERRORS.md).

## Коммит работы

`2f46294` — «TASK-10: кнопки не ниже 44 на компьютере, подпись ошибки поля
целиком», ветка `task/TASK-10`, после «да» владельца на СТОПе 1
(«Обсуждение», п. 4). Индексы в этом коммите собраны без сдачи; сдача и
индексы с ней — отдельным коммитом. Push не было.

```
2f462949efe949b6c30a2712ba5b5ae92ab65f99
TASK-10: кнопки не ниже 44 на компьютере, подпись ошибки поля целиком

 lib/app/theme/app_theme.dart                       | 14 ++++++
 sdlc/3-design/design-system/INDEX.md               |  2 +-
 test/app/theme/app_theme_test.dart                 | 42 +++++++++++++++++
 .../auth/presentation/login_screen_test.dart       | 52 ++++++++++++++++++++++
 .../auth/presentation/register_screen_test.dart    | 46 +++++++++++++++++++
 test/features/profile/profile_screen_test.dart     | 22 +++++++++
 test/helpers/button_height.dart                    | 11 +++++
 7 files changed, 188 insertions(+), 1 deletion(-)
```

## Выполнено

### 1.1. Кнопки не ниже 44 на любой платформе

- `lib/app/theme/app_theme.dart`: `visualDensity: VisualDensity.standard` в
  `ButtonStyle` тем `filledButtonTheme`, `outlinedButtonTheme`,
  `textButtonTheme`; у первой — комментарий, зачем. `ThemeData.visualDensity`,
  `minimumSize`, `materialTapTargetSize` и константы токенов не менялись.
- Новый `test/helpers/button_height.dart`: `minTapTarget = 44` (TOKEN-6) и
  `visibleButtonHeight` — высота подложки `Material` кнопки, без прозрачных
  полей области нажатия («Обсуждение», п. 2, 3).
- Тест темы: «TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже
  тап-цели 44» (`app_theme_test.dart`), `TargetPlatformVariant` — macOS,
  Windows, Linux, Android, iOS. Тема собирается в теле теста, чтобы
  плотность по умолчанию бралась из платформы варианта.

### 1.2. Подпись ошибки поля — целиком

- `lib/app/theme/app_theme.dart`: константа `_errorMaxLines = 4` с dartdoc
  (в задании — 3, «Обсуждение», п. 1; «Отступления»), в
  `inputDecorationTheme` — `errorMaxLines: _errorMaxLines` с комментарием.
  Поля входа и регистрации не менялись: берут значение из темы.

### Пути UC

| Путь | Новые тесты с его меткой (файл) |
|---|---|
| [UC-38-P-01](../2-specs/use-cases/UC-38-ACTOR-1-EVT-2-ENT-17-TEST-SESSION-STARTED-IN-AUTH.md#uc-38-p-01) | «UC-38-P-01: на компьютере «Войти» и «Тестовый вход» не ниже тап-цели 44», macOS (`login_screen_test.dart`) |
| [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) | «UC-1-P-01: на компьютере «Зарегистрироваться» не ниже тап-цели 44», macOS (`register_screen_test.dart`) |
| [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01) | «UC-13-P-01: на компьютере «Выйти» не ниже тап-цели 44», macOS (`profile_screen_test.dart`) |
| [UC-10-P-03](../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-03) | «UC-10-P-03: на окне 360×800 ошибки полей видны целиком», «… 1440×900 …» (`login_screen_test.dart`) |
| [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02) | «UC-1-P-02: на окне 360×800 ошибки полей видны целиком», «… 1440×900 …» (`register_screen_test.dart`) |

Тесты ошибок: окно задаётся `setSurfaceSize`, логин `a-b`, пароль `123`,
отправка формы; у `RenderParagraph` текстов `authUsernameInvalid` и
`authPasswordInvalid` — `didExceedMaxLines == false`.

Прежние тесты не менялись. Новых тестов — 12 (тест TOKEN-6 — пять
вариантов), всего 389.

## Не выполнено

Нет.

## Проверки

Локально, 2026-10-27, worktree `~/projects/yege_wars-TASK-10`, до коммита.

```
$ flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
Got dependencies!
  Built with build_runner/aot in 16s; wrote 28 outputs.
$ flutter analyze --fatal-infos --fatal-warnings
No issues found! (ran in 9.4s)
$ dart run custom_lint
No issues found!
$ flutter test
+389: All tests passed!
$ find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' -print0 | xargs -0 dart format --output=none --set-exit-if-changed
Formatted 205 files (0 changed) in 0.20 seconds.
format exit=0
$ python3 -m sdlc_tool views
обновлено: sdlc/3-design/design-system/INDEX.md
обновлено: sdlc/4-tasks/INDEX.md
обновлено: sdlc/5-results/INDEX.md
$ python3 -m sdlc_tool check
Итог: 0 ошибок, 142 предупреждения
```

Предупреждения `check` — ссылки прежних артефактов на похороненные id
(например, `ACC-TASK-5-01.md`), этой работой не задеты.

### Новые тесты на теме из `main` и на теме задания

Весь `flutter test --reporter json`, сводка скриптом в scratchpad по тестам,
в имени которых `TOKEN-6`, «тап-цели 44» или «видны целиком». Тема из
`main` — подменой `lib/app/theme/app_theme.dart` на `git show
main:lib/app/theme/app_theme.dart`, после прогона файл возвращён (хэш
совпал).

Тема из `main`:

```
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.android)
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.iOS)
error    AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.linux)
error    AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.macOS)
error    AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.windows)
error    UC-1-P-01: на компьютере «Зарегистрироваться» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
error    UC-1-P-02: на окне 1440×900 ошибки полей видны целиком
error    UC-1-P-02: на окне 360×800 ошибки полей видны целиком
error    UC-10-P-03: на окне 1440×900 ошибки полей видны целиком
error    UC-10-P-03: на окне 360×800 ошибки полей видны целиком
error    UC-13-P-01: на компьютере «Выйти» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
error    UC-38-P-01: на компьютере «Войти» и «Тестовый вход» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
всего: 389, success 379, failure 0, error 10
```

Причины падений (тот же прогон в `--reporter expanded`): у тестов высоты —
`Expected: a value greater than or equal to <44.0>`, `Actual: <36.0>` (в
тесте темы первой падает `FilledButton`); у тестов ошибок — `Expected:
false`, `Actual: <true>` на тексте `authUsernameInvalid`. Варианты Android и
iOS теста TOKEN-6 проходят и на теме из `main`: там плотность и так
`standard`.

Тема задания:

```
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.android)
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.iOS)
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.linux)
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.macOS)
success  AppTheme.dark TOKEN-6: FilledButton, OutlinedButton и TextButton не ниже тап-цели 44 (variant: TargetPlatform.windows)
success  UC-1-P-01: на компьютере «Зарегистрироваться» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
success  UC-1-P-02: на окне 1440×900 ошибки полей видны целиком
success  UC-1-P-02: на окне 360×800 ошибки полей видны целиком
success  UC-10-P-03: на окне 1440×900 ошибки полей видны целиком
success  UC-10-P-03: на окне 360×800 ошибки полей видны целиком
success  UC-13-P-01: на компьютере «Выйти» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
success  UC-38-P-01: на компьютере «Войти» и «Тестовый вход» не ниже тап-цели 44 (variant: TargetPlatform.macOS)
всего: 389, success 389, failure 0, error 0
```

### Стоп-условие «на 360 подписи ошибки не хватает трёх строк»

С `_errorMaxLines = 3`, как в задании, четыре файла тестов, `flutter test
--reporter expanded`:

```
00:00 +10 -1: test/features/auth/presentation/login_screen_test.dart: UC-10-P-03: на окне 360×800 ошибки полей видны целиком [E]
00:01 +18 -2: test/features/auth/presentation/register_screen_test.dart: UC-1-P-02: на окне 360×800 ошибки полей видны целиком [E]
00:02 +39 -2: Some tests failed.
```

Причина обоих — `Expected: false`, `Actual: <true>` на тексте
`authUsernameInvalid`. Весь набор с тремя строками — `+387 -2`: падали только
эти два, тесты других экранов — нет.

Замер временным тестом (удалён после замера): экран входа после «Войти» с
`a-b` / `123`, подпись `authUsernameInvalid`; `linesNeeded` — число строк той
же подписи без ограничения на той же ширине:

```
window=360.0 width=240.0 height=48.0 maxLines=3 font=Inter_regular size=12.0 linesNeeded=4 lineWidths=[136, 124, 211, 161]
window=1440.0 width=312.0 height=48.0 maxLines=3 font=Inter_regular size=12.0 linesNeeded=3 lineWidths=[273, 211, 161]
```

Inter в тестах не загружается (`test/flutter_test_config.dart`:
`GoogleFonts.config.allowRuntimeFetching = false`), текст рисуется тестовым
шрифтом. В браузере, по раунду 2026-10-27 `TC-3`, шаг 2, до многоточия в одну
строку помещалось «Логин: 3–20 символов — латиница, цифры и по» на 1440 и
«Логин: 3–20 символов — латиница, » на 360 — там подписи нужно две строки.

### Самопроверка по «Приёмке» после коммита работы

1. Состав коммита работы:

```
$ git diff main...task/TASK-10 --stat
 lib/app/theme/app_theme.dart                       | 14 ++++++
 sdlc/3-design/design-system/INDEX.md               |  2 +-
 test/app/theme/app_theme_test.dart                 | 42 +++++++++++++++++
 .../auth/presentation/login_screen_test.dart       | 52 ++++++++++++++++++++++
 .../auth/presentation/register_screen_test.dart    | 46 +++++++++++++++++++
 test/features/profile/profile_screen_test.dart     | 22 +++++++++
 test/helpers/button_height.dart                    | 11 +++++
 7 files changed, 188 insertions(+), 1 deletion(-)
```

2. Тема:

```
$ grep -n "visualDensity\|errorMaxLines" lib/app/theme/app_theme.dart
21:  static const int _errorMaxLines = 4;
112:        errorMaxLines: _errorMaxLines,
148:          visualDensity: VisualDensity.standard,
168:          visualDensity: VisualDensity.standard,
189:          visualDensity: VisualDensity.standard,
```

Строки 148, 168, 189 — `ButtonStyle` тем `filledButtonTheme`,
`outlinedButtonTheme`, `textButtonTheme`; у `ThemeData` `visualDensity` нет.

3. Проверки Dart — «Проверки» выше: 0 замечаний, `+389: All tests passed!`.
4. Тесты с метками и их падение на теме из `main` — «Новые тесты на теме из
   `main` и на теме задания» выше.
5. Ручные кейсы — не прогонялись: их прогоняет тестировщик постановщика.
6. Перед коммитом сдачи `python3 -m sdlc_tool views` пересобрал
   `sdlc/4-tasks/INDEX.md` и `sdlc/5-results/INDEX.md`;
   `python3 -m sdlc_tool check` — `Итог: 0 ошибок, 142 предупреждения`.

В `git diff` и в сдаче нет ответов задач, эталонов и значений переменных
окружения.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — нет.

По ходу:

1. 2026-10-27, СТОП по стоп-условию «на 360 подписи ошибки не хватает трёх
   строк». Вопрос: «В тестах на окне 360 подписи ошибки нужно 4 строки (там
   тестовый шрифт), в браузере — 2. Как быть?» Варианты: «`_errorMaxLines =
   4`» — поднять константу, тесты 360 и 1440 оставить; «Inter в тестах» —
   оставить 3 и грузить в тестах настоящий шрифт, файл шрифта в репозитории;
   «Стоп, к постановщику». Ответ владельца: «`_errorMaxLines = 4`».
2. Выбор исполнителя: высота кнопки в тестах — видимая, по подложке
   `Material`, а не размер виджета кнопки: размер виджета включает
   прозрачные поля области нажатия (48 при `standard`) и прошёл бы 44 при
   видимой высоте 36 с плотностью `standard` и меньшим `minimumSize`.
3. Выбор исполнителя: помощник высоты и константа 44 — в новом
   `test/helpers/button_height.dart`, общем для четырёх файлов тестов;
   окна 360×800 и 1440×900 — через `setSurfaceSize`, как в
   `task_screen_test.dart`. «Выйти» — `OutlinedButton.icon`, у него свой
   подкласс, поэтому в тесте профиля он ищется предикатом `is
   OutlinedButton`, а не `find.byType`.
4. 2026-10-27, СТОП 1. Вопрос: «Коммитить работу в task/TASK-10 (тема,
   тесты, индексы без сдачи), затем сдачу отдельным коммитом?» Варианты:
   «Да», «Нет». Ответ владельца: «Да».

## Отступления от задания

1. `_errorMaxLines = 4` вместо 3 — по решению владельца на стоп-условии
   («Обсуждение», п. 1). Dartdoc константы — по фактам замера: две строки
   шрифтом Inter, четыре — тестовым шрифтом.

## Найдено вне задания

1. Текст в тестах рисуется тестовым шрифтом, а не Inter
   (`test/flutter_test_config.dart`, `allowRuntimeFetching = false`): на
   ширине 240 подпись `authUsernameInvalid` в тесте занимает четыре строки,
   в браузере — две. Тесты, которые меряют строки и ширину текста, проверяют
   раскладку тестового шрифта, а не вида в браузере. Не чинилось.
