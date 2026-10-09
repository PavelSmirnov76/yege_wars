# Находки приёмки TASK-7

2026-10-09, приёмка [ACC-TASK-7-01](../../../6-eval/acceptance/ACC-TASK-7-01.md)
сдачи [RESULT-TASK-7-01](../../../5-results/RESULT-TASK-7-01.md).

1. Адреса внутри приложения с `#` ([ENT-16](../../../2-specs/entities/ENT-16-SITE-IN-SITE.md))
   тестом не закреплены: в `lib/` нет `usePathUrlStrategy` и
   `setUrlStrategy`, но проверки на это нет. Без `#` перезагрузка на
   `…/yege_wars/task/<slug>` дала бы `404` от Pages. Пока это проверит только
   TC-1.
2. `web/manifest.json` и `web/index.html` — остатки шаблона Flutter: `name` и
   `short_name` — `yege_wars`, `description` — «A new Flutter project.»,
   `background_color` и `theme_color` — `#0175C2` при фоне страницы
   `#0F1115`; `apple-mobile-web-app-title` — `yege_wars`. Видно, когда сайт
   добавляют на экран «Домой» телефона.
3. `flutter build web --release --base-href /yege_wars/` печатает «Expected to
   find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons),
   but found (MaterialIcons)». То же — в сборке `main` до задания. В
   `pubspec.yaml` и `lib/` `cupertino_icons` нет; сборка проходит.
4. Проверки выкладки повторяют задачу `build` из `ci.yml` (решение владельца
   на СТОПе 0 TASK-7, п. 3): правку проверок CI нужно повторять в
   `deploy.yml`, тест с `ci.yml` их не сравнивает.
5. Адрес воркера Python закреплён тестом только константой
   `PyodideRuntime.defaultWorkerUrl`, прочитанной из исходника, — приём,
   выбранный владельцем на СТОПе 0 TASK-7, п. 7. Абсолютный адрес в фабрике
   `createPythonRuntime` или в вызове `web.Worker` ни один тест не ловит
   (порчи 5 и 6 приёмки). На сайте это проверит TC-1 — Python запускается.
6. [BT-16](../../../1-business-tasks/planning/BT-16-PLANNING-SITE.md) после
   прогона `run` — «да»: все три пути `PASS` по тестам Dart, хотя сайт ещё не
   выложен. Тесты держат текст workflow и файлы `web/`; что сайт обновился и
   открывается ([UC-30-P-01](../../../2-specs/use-cases/UC-30-ACTOR-1-EVT-10-ENT-16-SITE-OPENED-IN-SITE.md#uc-30-p-01)),
   проверит только TC-1. Скрипт закрывает бизнес-задачу по автоматическим
   вердиктам и не знает, что у пути есть часть, которую проверяет только
   ручной кейс.

Источник пп. 1–4 — сдача, раздел «Найдено вне задания»; подтверждено по коду
и выводу сборки. Пп. 5–6 — приёмка.
