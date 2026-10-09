# Находки приёмки TASK-6

2026-10-09, приёмка [ACC-TASK-6-01](../../../6-eval/acceptance/ACC-TASK-6-01.md)
сдачи [RESULT-TASK-6-01](../../../5-results/RESULT-TASK-6-01.md).

1. Без теста две строки. Вызов `runtimeStateOnReady` в
   `PyodideRuntime._onMessage`: класс только для браузера, на VM его не
   создать, а переход `ready` → `running` вынесен в функцию с юнит-тестом.
   `retry: noProviderRetry` в `main.dart`: `main_test.dart` проверяет только
   запуск без параметров сборки, до `ProviderScope` с `retry` он не доходит.
2. [COMP-12](../../../3-design/design-system/COMP-12-ERROR-RETRY.md) — виджет
   `ReferenceErrorView` в `lib/features/reference/presentation/widgets/`; им
   пользуются страница задачи, каталог, «Мои попытки» и «Решения». Имя и место
   — от справочника.
3. Выход из учётной записи со страницы задачи: черновик при снятии страницы
   пишется уже без сессии — datasource бросает `AuthSessionMissingException`,
   запись молча не проходит. Это пункт пула доработок черновика «сохранение
   при выходе из учётной записи» (`release-for-students.md`).
4. Широкий экран, свои попытки не загрузились: COMP-12 стоит дважды — в «Моих
   попытках» и в «Решениях» — с одним текстом. Следствие решения владельца:
   при сбое своих попыток в «Решениях» тоже COMP-12
   ([UC-35-P-04](../../../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-04)).

Источник пп. 1–4 — сдача, раздел «Найдено вне задания»; подтверждено по коду.
