# Находки повторной приёмки TASK-7

2026-10-09, приёмка [ACC-TASK-7-02](../../../6-eval/acceptance/ACC-TASK-7-02.md)
сдачи [RESULT-TASK-7-02](../../../5-results/RESULT-TASK-7-02.md).

1. Упавшую сборку с `|| true` тест не ловит. Шаг сборки тест запускает
   только с поддельным `flutter`, который завершается успешно: порча
   `flutter build web … || true` не роняет ни одного теста. Вес выше, чем
   казалось: Flutter 3.41 создаёт `build/web` до компиляции
   (`flutter_tools/lib/src/web/compile.dart`, `createSync` перед сборкой), а
   `actions/upload-pages-artifact` v5.0.0 архивирует папку как есть — упавшая
   сборка с `|| true` выложила бы на сайт пустую или неполную папку вопреки
   [UC-29-P-02](../../../2-specs/use-cases/UC-29-ACTOR-5-EVT-24-ENT-16-SITE-DEPLOYED-IN-SITE.md#uc-29-p-02).
   В самом workflow `|| true` нет.
2. Адреса `web/index.html` в атрибутах без кавычек (`href=/favicon.png`)
   регулярка теста UC-30-P-01 не берёт. Вес малый: так в `web/index.html` не
   пишут.

Источник — сдача, раздел «Найдено вне задания», пп. 1–2; подтверждено
порчами на копии сдачи, вес п. 1 — по исходникам Flutter и
`upload-pages-artifact`.
