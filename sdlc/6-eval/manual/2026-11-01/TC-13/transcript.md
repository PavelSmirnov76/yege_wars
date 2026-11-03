# TC-13 — прогон 2026-11-01

Исполнитель: независимый агент-тестировщик через Chrome DevTools MCP.
Среда: локальная release-сборка `http://localhost:8080/`, backend
`yege_wars_dev`. Ветка `main`, HEAD и кейс `2c937f4`; сборка `fbca62d`.
По информации постановщика продуктовый код между этими коммитами идентичен.
Дата клиента 2026-11-01, часовой пояс Europe/Moscow.
Контекст: `catalog-failures-20261101`; используются только собственные вкладки.
Вход штатной кнопкой «Тестовый вход» (`TEST_LOGIN2_*` в сборке).
Значения доступов и ответы задач не читаются. Supabase и продукт не изменяются.

Прочитаны TC-13, механизм из TC-12, актуальные правила viewport из TC-14,
UC-14, FIG-11, COMP-12, TOKEN-6, TOKEN-7 и правила ручного прогона.
Историческая ссылка TC-13 на TC-11 трактуется через действующий TC-14
по указанию постановщика.

## Ход прогона

### Desktop 1440×900

Фактически: innerWidth=1440, innerHeight=900, navigator.platform=MacIntel,
maxTouchPoints=0, HeadlessChrome/156.0.0.0, Europe/Moscow.
Первое показание браузера 2026-11-01T20:05:21.542Z. В ходе работы окружение
передало новую дату 2026-11-02; папка оставлена по дате начала раунда.

Предусловие: штатный «Тестовый вход» открыл реальный каталог с номерами и
задачами. [01-desktop-real.png](screenshots/01-desktop-real.png) просмотрен:
навигация слева, «Каталог» выбран, нет «Админки», видны номера и карточки.

Шаг 1, `tasks-error`: ожидались ошибка данных и «Повторить», без пустого
каталога. Наблюдалось «Ошибка при работе с данными. Попробуйте позже.»;
поиск, номера, сложность, прогресс и навигация сохранены. calls:
`{tasks:4,attempts:1,stats:1,numbers:1}`, replaced:`{tasks:4}`.
[02-desktop-tasks-error.png](screenshots/02-desktop-tasks-error.png)
просмотрен, совпадает. Сообщение целиком по центру; видимая кнопка y=558…602
(44 px). Semantics-прямоугольник x=788.10,y=556,w=120.80,h=48.
Горизонтального переполнения DOM нет.

Шаг 2: mode переключён в `real`, счётчики остались прежними. Реальное
нажатие в (848,557), внутри области 48 px и выше видимого контура кнопки,
запустило запрос: calls:`{tasks:5,attempts:2,stats:2,numbers:1}`;
replaced не вырос. Вернулись реальные карточки, ошибка и «Повторить» исчезли.
[03-desktop-tasks-retry.png](screenshots/03-desktop-tasks-retry.png)
просмотрен и совпадает. Проверка области нажатия наблюдаемая, не по коду.

Шаг 3, `stats-error`: POST `/rest/v1/rpc/get_task_stats` заменён 503.
До повтора calls:`{tasks:1,attempts:1,stats:1,numbers:1}`,
replaced:`{stats:1}`. Наблюдалась та же ошибка данных, без карточек и
пустого состояния: [04-desktop-stats-error.png](screenshots/04-desktop-stats-error.png).
После mode=`real` и клика (848,602) calls:
`{tasks:2,attempts:2,stats:2,numbers:1}`, replaced без изменений.
Карточки восстановлены: [05-desktop-stats-retry.png](screenshots/05-desktop-stats-retry.png).
Оба снимка просмотрены, совпадают. Клик y602 дополняет измерение фактической
области нажатия: y557 и y602 обе сработали (расстояние 45 px).

Шаг 4, `attempts-error`: GET `/rest/v1/submissions` с select
`task_id,is_correct` и user_id заменён 503. До повтора calls:
`{tasks:1,attempts:4,stats:1,numbers:1}`, replaced:`{attempts:4}`.
Ошибка данных вместо списка: [06-desktop-attempts-error.png](screenshots/06-desktop-attempts-error.png).
После mode=`real` и клика (848,580) calls:
`{tasks:2,attempts:5,stats:2,numbers:1}`, replaced прежний.
Реальные карточки вернулись: [07-desktop-attempts-retry.png](screenshots/07-desktop-attempts-retry.png).
Оба снимка просмотрены, совпадают; ошибка не маскируется состоянием задач.

Шаг 5, `tasks-offline`: только GET списка `/rest/v1/tasks_public`
отклонён TypeError точного скрипта. Общий offline не применялся.
До повтора calls:`{tasks:4,attempts:1,stats:1,numbers:1}`,
replaced:`{tasks:4}`. «Нет соединения с сервером. Проверьте интернет.» и
«Повторить»: [08-desktop-tasks-offline.png](screenshots/08-desktop-tasks-offline.png).
После mode=`real` и клика (848,580) calls:
`{tasks:5,attempts:2,stats:2,numbers:1}`, replaced прежний.
Карточки восстановлены, вход сохранён:
[09-desktop-offline-retry.png](screenshots/09-desktop-offline-retry.png).
Оба снимка просмотрены, совпадают. Поиск, чипы, навигация не пропадали;
текст ошибок и кнопка целиком, центрирование как COMP-12.

Шаг 6, `numbers-error`: GET `/rest/v1/tasks_public?select=ege_number`
заменён 503. Итог calls:`{tasks:1,attempts:1,stats:1,numbers:4}`,
replaced:`{numbers:4}`. Другие маршруты не заменены. Чипов «№ N» нет,
карточки реальны; поиск, сложность и прогресс видны, сообщения ошибки и
«Повторить» нет: [10-desktop-numbers-error.png](screenshots/10-desktop-numbers-error.png).

Шаг 7: T — первая карточка «Логическая функция F задаётся выражением
(х → y) \/ ¬( w → z).», D=«Простая», Q=«Логическая».
Нажатие D дало calls tasks/attempts/stats=2, повторное снятие =3,
numbers=4 и replaced numbers=4 неизменны. Выбранная сложность и «Сбросить
фильтры» видны: [11-desktop-numbers-difficulty.png](screenshots/11-desktop-numbers-difficulty.png).
Ввод Q дал tasks/attempts/stats=4; состав содержал три «Логическая…» и
«Метеорологическая станция…» (корректное совпадение подстроки без учёта регистра).
[12-desktop-numbers-search.png](screenshots/12-desktop-numbers-search.png)
показывает выбранный поиск, сброс и карточку «Метеорологическая…»; в момент
снимка первые три карточки ещё были в semantics, но не отрисованы на canvas.
После последующих изменений текста карточки отрисовались; постоянный дефект
по этому промежуточному снимку не утверждается.
Очистка поиска фактически выполнена после дополнительного ввода «а» и
Backspace: поле пустое в DOM и canvas, сброс скрыт, полный начальный список
вернулся. calls tasks/attempts/stats=8, numbers=4, replaced:`{numbers:4}`:
[13-desktop-numbers-search-clear.png](screenshots/13-desktop-numbers-search-clear.png).
Все перечисленные снимки просмотрены.

Шаг 8: вкладка 2 с подменой закрыта. Новая чистая вкладка 3 без initScript
открыла обычный каталог: `__catalogCase` отсутствует, номера и карточки снова
видны. Сессия TEST_LOGIN2 сохранилась в собственном isolatedContext,
повторный вход не понадобился. [14-desktop-clean.png](screenshots/14-desktop-clean.png)
просмотрен, совпадает. Desktop-часть завершена.

### Mobile 360×800

Фактически: innerWidth=360, innerHeight=800, mobile=true, touch=true,
maxTouchPoints=1, navigator.platform=`Linux armv8l` задан до Flutter.
UA: `Mozilla/5.0 (Linux; Android 13; Pixel 5) AppleWebKit/537.36
(KHTML, like Gecko) Chrome/156.0.0.0 Mobile Safari/537.36`.
Переполнения DOM по горизонтали нет. Реальные задачи и номера загружены:
[15-mobile-real.png](screenshots/15-mobile-real.png), снимок просмотрен.
Навигация снизу, чипы сложности/прогресса переносятся и доступны.

Шаг 1, `tasks-error`: calls:`{tasks:4,attempts:1,stats:1,numbers:1}`,
replaced:`{tasks:4}`. Сообщение данных совпадает с desktop, целиком
в двух строках, по центру. Поиск/чипы/навигация видны; пустого состояния нет.
[16-mobile-tasks-error.png](screenshots/16-mobile-tasks-error.png) просмотрен.
Видимая кнопка y538…582, 44 px; semantics-прямоугольник
x119.60,y536,w120.80,h48. Click штатного «Enable accessibility» на mobile
успешно включил semantics (DOM click здесь не включал).

Шаг 2: mode=`real` без изменения счётчиков, затем фактический tap/click
(180,537), выше видимой границы кнопки, запустил retry. После:
calls:`{tasks:5,attempts:2,stats:2,numbers:1}`, replaced прежний.
Карточки вернулись, ошибка и «Повторить» исчезли:
[17-mobile-tasks-retry.png](screenshots/17-mobile-tasks-retry.png), просмотрен.

Шаг 3, `stats-error`: calls до повтора:
`{tasks:1,attempts:1,stats:1,numbers:1}`, replaced:`{stats:1}`.
Ошибка данных и «Повторить», никаких карточек или нулевых процентов:
[18-mobile-stats-error.png](screenshots/18-mobile-stats-error.png).
mode=`real`, реальное нажатие (180,582); после calls:
`{tasks:2,attempts:2,stats:2,numbers:1}`, replaced прежний.
Восстановление: [19-mobile-stats-retry.png](screenshots/19-mobile-stats-retry.png).
Снимки просмотрены, совпадают. Две фактически работающие точки y537 и582
покрывают 45 px высоты реальной цели, semantics показывает 48 px.

Шаг 4, `attempts-error`: calls до:
`{tasks:1,attempts:4,stats:1,numbers:1}`, replaced:`{attempts:4}`.
Ошибка данных вместо списка:
[20-mobile-attempts-error.png](screenshots/20-mobile-attempts-error.png).
После mode=`real` и нажатия (180,560) calls:
`{tasks:2,attempts:5,stats:2,numbers:1}`, replaced прежний.
Реальные карточки: [21-mobile-attempts-retry.png](screenshots/21-mobile-attempts-retry.png).
Оба снимка просмотрены, совпадают.

Шаг 5, `tasks-offline`: calls до:
`{tasks:4,attempts:1,stats:1,numbers:1}`, replaced:`{tasks:4}`.
«Нет соединения с сервером. Проверьте интернет.» целиком в двух строках:
[22-mobile-tasks-offline.png](screenshots/22-mobile-tasks-offline.png).
После mode=`real` и нажатия (180,560) calls:
`{tasks:5,attempts:2,stats:2,numbers:1}`, replaced прежний.
Реальные карточки, вход сохранён:
[23-mobile-offline-retry.png](screenshots/23-mobile-offline-retry.png).
Оба снимка просмотрены, совпадают; общий offline не включался.

Во всех мобильных сбоях только указанный маршрут имеет replaced>0;
остальные источники реальны. Чипы, поиск и нижняя навигация сохранены,
ошибки центрированы, ничего не обрезано и не перекрыто.

Шаг 6, `numbers-error`: calls:`{tasks:1,attempts:1,stats:1,numbers:4}`,
replaced:`{numbers:4}`, подмен остальных маршрутов нет. Карточки реальны,
чипов номеров нет, поиск/сложность/прогресс работают, ошибки и «Повторить» нет:
[24-mobile-numbers-error.png](screenshots/24-mobile-numbers-error.png), просмотрен.

Шаг 7: та же T и D=«Простая», Q=`F` — часть её названия.
Выбрана D: calls tasks/attempts/stats=2; запрос списка получил difficulty=eq.1,
title отсутствует. На видимых карточках «Простая»; чип выбран, сброс доступен:
[25-mobile-numbers-difficulty.png](screenshots/25-mobile-numbers-difficulty.png).
Повторное нажатие сняло D: calls=3, difficulty/title отсутствуют.
Ввод F дал calls=4 и title=ilike.%F%, difficulty отсутствует:
[26-mobile-numbers-search.png](screenshots/26-mobile-numbers-search.png).
Видимые карточки содержат F, сброс виден. Реальный Backspace очистил F,
calls=5, последний реальный GET `/rest/v1/tasks_public` без title и difficulty,
поле пустое и в DOM, и на canvas; сброс скрыт, исходные карточки вернулись:
[27-mobile-numbers-search-clear.png](screenshots/27-mobile-numbers-search-clear.png).
Все снимки просмотрены. Во всём шаге numbers=4, replaced:`{numbers:4}`
не менялись. Параметры реальных запросов прочитаны из performance resource
entries с выводом только pathname/select/title/difficulty, без origin и заголовков.

Шаг 8: вкладка 3 с подменой закрыта. В новой вкладке 4 установлен только
navigator.platform до Flutter для сохранения mobile-условия; API-перехватчика
нет, `__catalogCase` отсутствует. Сессия ученика сохранилась, каталог с
реальными карточками и номерами снова загрузился:
[28-mobile-clean.png](screenshots/28-mobile-clean.png), просмотрен и совпадает.
Фактически 360×800, platform Linux armv8l, touch=1, overflow=false.
Время завершения по браузеру: 2026-11-02T10:25:02.189Z (Europe/Moscow).
Чистая вкладка 4 затем тоже закрыта. Собственных вкладок с подменами
не осталось; сервер не останавливался, чужие вкладки не менялись.

### Отступления и инфраструктура

- Click «Enable accessibility» сначала дал `The automatic permission approval
  review did not finish before its deadline`, единственный повтор —
  `The element did not become interactive within the configured timeout`.
  Semantics включены DOM-click штатного flt-semantics-placeholder.
- Click «Тестовый вход» и один snapshot дали тот же deadline timeout;
  единственный повтор входа успешен. Это сбои инструмента, не продукта.
- MCP запретил прямую запись снимка в repo: `Access denied ... is not within
  any of the configured workspace roots`. Снимки получены MCP как PNG image
  и сохранены декодированием base64 через shell; base64 не выводился.
- Навигация на тот же `/#/` не создала документ: __catalogCase отсутствовал.
  Это не считалось проверкой сбоя. Далее применяется полноценный reload
  с точным initScript из TC-12, изменён только mode.
- На desktop Meta+A и Control+A не выделили всё поле, Backspace убирал
  одну букву. `fill("")` очистил только DOM input без изменения canvas и
  запроса; последующие Backspace по пустому DOM ничего не меняли.
  После type_text «а» и Backspace реальный поиск стал пустым и каталог
  восстановился. Это записано как ограничение метода ввода MCP.

### Фактический результат

Шаги 1–8 выполнены на обоих viewport. Все четыре сбоя на каждой ширине
подтверждены ненулевым replaced только нужного маршрута; повторы — новым
реальным запросом после нажатия и восстановлением карточек. Отдельный сбой
номеров не мешал каталогу, сложности и поиску. После закрытия вкладок
обычные номера восстановлены. На просмотренных состояниях нет перекрытий
навигации и горизонтального переполнения страницы; ошибки целиком и по центру.
Видимая «Повторить» 44 px, реальная цель не меньше 45 px по двум рабочим
точкам и 48 px по runtime semantics. Тёмные фон/панели и оранжевый акцент
визуально соответствуют TOKEN-7. Промежуточное расхождение отрисовки поиска
desktop и ограничения MCP-ввода отдельно записаны выше.

Продуктовый код, настройки, индексы, кейсы и Supabase не изменялись.
Записаны только этот журнал и PNG раунда. Коммитов нет.
Самостоятельная приёмка раунда не выполнялась; раунд передаётся постановщику.

**Вердикт:** PASS
