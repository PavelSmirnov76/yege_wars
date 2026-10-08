# RESULT-TASK-4-02: Метки среза «задачи и решение» и недостающие тесты — после возврата

## Задание

[TASK-4](../4-tasks/TASK-4-LABELS-PROBLEMS.md); возврат —
[ACC-TASK-4-01](../6-eval/acceptance/ACC-TASK-4-01.md); прошлая сдача —
[RESULT-TASK-4-01](RESULT-TASK-4-01.md).

## Коммит работы

`5853c2a` — «TASK-4 по возврату ACC-TASK-4-01: экран сбоя загрузки и в
AsyncError», ветка `task/TASK-4`, после «да» владельца на СТОПе 1
(Обсуждение, п. 1). Индексы не менялись; сдача и индексы с ней — отдельным
коммитом. Работа прошлой сдачи — `3798858` (RESULT-TASK-4-01).

```
5853c2a979fb6c2553f5eafd67b6e7465a2e3506
TASK-4 по возврату ACC-TASK-4-01: экран сбоя загрузки и в AsyncError

 test/features/submissions/solutions_list_test.dart | 40 +++++++++++++++-------
 test/features/submissions/submit_panel_test.dart   | 28 +++++++++++----
 test/helpers/pump_app.dart                         | 22 ++++++++++++
 3 files changed, 71 insertions(+), 19 deletions(-)
```

## Выполнено

Worktree `~/projects/yege_wars-TASK-4`, ветка `task/TASK-4` на коммите
приёмки `ed52b36`. Исправлено то, что перечислено в «Что исправить»
ACC-TASK-4-01; остальное приёмка приняла как есть, и оно не менялось: метки
тестов и кода, 7 других новых тестов Dart, раздел (у) в `rls_tests.sql`,
комментарии `TaskScreen` и `EditorPanel`. Пункты задания 1.1–1.4 и таблица
«путь → тесты с его меткой» — как в RESULT-TASK-4-01: имена тестов не
менялись, таблица, собранная заново по JSON-отчёту итогового `flutter test`
разборщиками `sdlc_tool run`, совпала с прошлой построчно; 33 пути, все
строки — `success`.

### Что исправить, п. 1: экран и в `AsyncError`

Тесты [UC-21-P-03](../2-specs/use-cases/obsolete/UC-21-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-21-p-03)
(«сбой загрузки попыток — ни списка, ни сообщения»,
`submit_panel_test.dart`) и
[UC-22-P-04](../2-specs/use-cases/obsolete/UC-22-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-22-p-04)
(«сбой загрузки решений — индикатор загрузки без сообщения»,
`solutions_list_test.dart`) проверяют экран дважды:

1. Пока Riverpod повторяет загрузку: тест утверждает, что провайдер
   (`myAttemptsProvider` или `publishedSolutionsProvider` задачи) —
   `AsyncLoading<List<Submission>>`, а `error` — та же `NetworkFailure`; затем
   проверки экрана пути.
2. После последнего повтора: помощник `pumpUntilRetriesEnd` прокручивает
   время шагами по 1 с, пока провайдер не станет `AsyncError`, не дольше
   1 мин; тест утверждает, что провайдер — `AsyncError<List<Submission>>`;
   затем те же проверки экрана.

Проверки экрана вынесены в локальные функции теста: UC-21-P-03 —
`expectNoAttempts` (заголовок «Мои попытки» есть; «Попыток пока не было»,
переключателя и текста сбоя нет), UC-22-P-04 — `expectSpinnerOnly` (в
`SolutionsList` индикатор загрузки; текста сбоя и «Пока никто не
опубликовал своё решение» нет). Сами проверки те же, что в прошлой сдаче.

Помощник `pumpUntilRetriesEnd` — в `test/helpers/pump_app.dart`, рядом с
`containerOf`. `pumpAndSettle` для этого не годится: между повторами кадров
нет. Политика повторов Riverpod 3.1.0 — `ProviderContainer.defaultRetry`: 10
повторов, пауза 0,2 с, удваивается до 6,4 с.

Нехолостость — порчей кода виджетов, как просит приёмка: ветка `AsyncError`
перед `_ =>` в `AttemptsList` и в `SolutionsList`, по одной порче за запуск.
Все 4 порчи пойманы, и каждый раз — второй, после `AsyncError`, проверкой
экрана: `submit_panel_test.dart:324` и `solutions_list_test.dart:132`.
Файлы `lib/` возвращены, `sha256` совпали. Выводы — в «Проверках».

### Что исправить, п. 2: состояние провайдера в момент проверок

В RESULT-TASK-4-01 было неверно написано, что тесты проверяют «что провайдер
в ошибке»: `error` есть и у `AsyncLoading`, пока идёт повтор. Состояние
провайдера в момент каждой проверки теперь такое:

| Тест | Проверки экрана | Состояние провайдера |
|---|---|---|
| UC-21-P-03 | первый вызов `expectNoAttempts` — сразу после `openSolve` (`pumpAndSettle`) | `myAttemptsProvider` — `AsyncLoading` с ошибкой `NetworkFailure`, идут автоповторы; утверждается в тесте |
| UC-21-P-03 | второй вызов `expectNoAttempts` — после `pumpUntilRetriesEnd` | `AsyncError` — повторов больше не будет; утверждается в тесте |
| UC-22-P-04 | первый вызов `expectSpinnerOnly` — после открытия вкладки конечным числом кадров | `publishedSolutionsProvider` — `AsyncLoading` с ошибкой `NetworkFailure`, идут автоповторы; утверждается в тесте |
| UC-22-P-04 | второй вызов `expectSpinnerOnly` — после `pumpUntilRetriesEnd` | `AsyncError`; утверждается в тесте |

## Не выполнено

- `python3 -m sdlc_tool run` не запускался: по заданию его прогоняет
  постановщик при приёмке.
- Части путей с метками, не проверенные тестами, и код без меток — как в
  RESULT-TASK-4-01 («Найдено вне задания», пп. 1–2) и в ACC-TASK-4-01: в
  «Что исправить» их нет, не менялись.

## Проверки

Итоговое состояние — рабочее дерево перед коммитом `5853c2a`, вошло в него
без изменений:

- `flutter pub get`, `flutter gen-l10n`,
  `dart run build_runner build --delete-conflicting-outputs` — код 0;
  последняя строка: `Built with build_runner/aot in 0s; wrote 0 outputs.`
- `flutter analyze --fatal-infos --fatal-warnings`:
  `No issues found! (ran in 2.7s)`
- `dart run custom_lint`: `No issues found!`
- `flutter test`: `00:10 +300: All tests passed!` — число тестов прежнее,
  менялись два теста
- `find lib test … | xargs -0 dart format --output=none --set-exit-if-changed`:
  `Formatted 190 files (0 changed) in 0.18 seconds.`, код 0
- `bash supabase/tests/run_local.sh`: `RLS TESTS PASSED`, `RLS OK` —
  `rls_tests.sql` не менялся
- `python3 -m sdlc_tool views`, затем `python3 -m sdlc_tool check`:
  `Итог: 0 ошибок, 6 предупреждений` — все 6 о ссылках TASK-1 и
  RESULT-TASK-1-01 на похороненные UC-11-P-01…UC-11-P-03, как в исходном
  состоянии.
- Изменены только `test/features/submissions/submit_panel_test.dart`,
  `test/features/submissions/solutions_list_test.dart`,
  `test/helpers/pump_app.dart`; `lib/`, `web/`, `supabase/` не тронуты.

Нехолостость — порча кода виджета, запуск
`flutter test <файл> --plain-name <путь>`, файл возвращён:

| Путь | Порча | Вывод |
|---|---|---|
| UC-21-P-03 | `AttemptsList`: `AsyncError(:final error) => Text((error as dynamic).message as String)` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Нет соединения с сервером. Проверьте` / `test/features/submissions/submit_panel_test.dart:324` / `Some tests failed.` |
| UC-21-P-03 | `AttemptsList`: `AsyncError() => Text(l10n.attemptsEmpty)` | `Expected: no matching candidates` / `Actual: _TextWidgetFinder:<Found 1 widget with text "Попыток пока не было": [` / `test/features/submissions/submit_panel_test.dart:324` / `Some tests failed.` |
| UC-22-P-04 | `SolutionsList`: `AsyncError(:final error) => Text((error as dynamic).message as String)` | `Expected: exactly one matching candidate` / `Actual: _DescendantWidgetFinder:<Found 0 widgets with type "CircularProgressIndicator" descending` / `test/features/submissions/solutions_list_test.dart:132` / `Some tests failed.` |
| UC-22-P-04 | `SolutionsList`: `AsyncError() => Text(l10n.solutionsEmpty, style: hintStyle)` | `Expected: exactly one matching candidate` / `Actual: _DescendantWidgetFinder:<Found 0 widgets with type "CircularProgressIndicator" descending` / `test/features/submissions/solutions_list_test.dart:132` / `Some tests failed.` |

Код выхода `flutter test` — 1 в каждой порче. Строки 324 и 132 — второй
вызов проверки экрана, после `AsyncError`; первый вызов (строки 316 и 124)
при этих порчах проходит. После всех порч: `файлы возвращены как были: True`.

## Применено к боевой

Нет.

## Обсуждение

До начала работы — нет.

По ходу:

1. 2026-10-08, СТОП 1. Вопрос: коммитить работу в `task/TASK-4`? Варианты:
   коммитить; не коммитить. Выбрано: **коммитить**.

Выбор исполнителя там, где задание и приёмка его не предписывали:

2. Экран в `AsyncError` проверяется прокруткой автоповторов с настройками
   Riverpod по умолчанию, а не отключением повторов в тесте: так тест идёт
   через те же состояния, что и приложение, и проверяет оба — до и после
   последнего повтора.
3. Помощник `pumpUntilRetriesEnd` — в `test/helpers/pump_app.dart`: он
   нужен двум файлам тестов и опирается на `containerOf` оттуда же.

## Отступления от задания

Нет.

## Найдено вне задания

Нового нет. Прежние находки — RESULT-TASK-4-01, «Найдено вне задания», и
ACC-TASK-4-01, «Найдено вне задания».
