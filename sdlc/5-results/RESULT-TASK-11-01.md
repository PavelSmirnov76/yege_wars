# RESULT-TASK-11-01: Области нажатия чипов каталога

## Задание

[TASK-11](../4-tasks/TASK-11-CATALOG-CHIP-TAP-TARGETS.md).

## Коммит работы

```
3cc2ba416324bbeffbe24baec9dec51e1880ae87
Исправить области нажатия чипов каталога

 .../presentation/widgets/catalog_filters_bar.dart  |   5 +
 sdlc/3-design/design-system/INDEX.md               |   2 +-
 .../presentation/catalog_chip_targets_test.dart    | 167 +++++++++++++++++++++
 3 files changed, 173 insertions(+), 1 deletion(-)
```

## Выполнено

- Трём группам чипов каталога задана стандартная плотность; общая тема не менялась.
- UC-14-P-02: проверены выбор и повторное снятие чипов, замена значения в группе, сочетание групп, сброс и прокрутка ряда номеров.
- Для UC-14-P-01 и UC-14-P-03 прошли существующие автоматические тесты каталога. Ручная проверка этих путей передана постановщику.
- Реальные области восьми чипов проверены в выбранном и невыбранном состояниях, верхний и нижний края — действиями и состоянием фильтра на пяти платформах.

## Не выполнено

Ручные TC-15, TC-12 и TC-14 на обеих ширинах выполняет тестировщик постановщика при приёмке; необходима локальная сборка ветки с `yege_wars_dev`. Коммит сдачи создаётся после коммита работы.

## Проверки

Команды выполнялись в `/Users/pavelsmirnov/projects/yege_wars-TASK-11`, ветка `task/TASK-11`.

- `flutter pub get`: `Got dependencies!`
- `flutter gen-l10n`: `Because l10n.yaml exists, the options defined there will be used instead.`
- `dart run build_runner build --delete-conflicting-outputs`: `Built with build_runner/aot in 16s; wrote 28 outputs.` Предупреждение: `These options have been removed and were ignored: --delete-conflicting-outputs`.
- Новые тесты до исправления, `flutter test test/features/tasks/presentation/catalog_chip_targets_test.dart --reporter expanded`: macOS, Windows, Linux — `Expected: a value greater than or equal to <44.0>`, `Actual: <40.0>` для № 17; Android и iOS — PASS. Итог: `+7 -3: Some tests failed.`
- После исправления та же команда: `+10: All tests passed!` — оба теста на macOS, Windows, Linux, Android, iOS. Ширины окна 1440×900 для desktop и 360×800 для mobile.
- Диагностический замер после исправления: все пять платформ дали одинаковые размеры, высота каждого чипа 48. Ширина невыбранного / выбранного: № 17 и № 24 — 90.4 / 110.4; «Простая», «Средняя», «Сложная» — 132.7 / 152.7; «Не начата» — 160.9 / 180.9; «Есть попытки» — 203.2 / 223.2; «Решено» — 118.6 / 138.6. Размеры в логических пикселях, шрифт тестового окружения. Временный диагностический вывод удалён.
- `flutter analyze --fatal-infos --fatal-warnings`: `No issues found! (ran in 2.5s)`.
- `dart run custom_lint`: `No issues found!`
- `flutter test --reporter expanded`: `+399: All tests passed!`
- Проверка форматирования: `Formatted 206 files (0 changed) in 0.20 seconds.`
- `python3 -m sdlc_tool views`: обновлены `sdlc/3-design/design-system/INDEX.md`, `sdlc/4-tasks/INDEX.md`, `sdlc/5-results/INDEX.md`.
- `python3 -m sdlc_tool check`: `Итог: 0 ошибок, 145 предупреждений`.
- `git diff --check`: без вывода, код 0.

## Применено к боевой

Нет.

## Обсуждение

До начала — нет.

По ходу: 2026-11-03, СТОП 1 — вопрос «Коммитить работу в `task/TASK-11`, затем сдачу отдельным коммитом?», варианты «Да» / «Нет, доработать»; ответ владельца: «да».

## Отступления от задания

Нет.

## Найдено вне задания

Нет.
