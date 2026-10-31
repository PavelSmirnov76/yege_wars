# TC-12: Каталог — состояния карточек и пустой каталог

**Цель:** проверить все состояния карточек, группу «Без номера», клиентский
отбор прогресса и пустой каталог на заранее заданных ответах API.

**Пути UC:** [UC-14-P-01](../../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-01), [UC-14-P-02](../../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-02), [UC-14-P-03](../../2-specs/use-cases/UC-14-ACTOR-4-EVT-11-ENT-6-PROBLEMS-LISTED-IN-CATALOG.md#uc-14-p-03).

**Приоритет:** средний — состояния, которых может не быть в текущем контенте.

**Дизайн:** [FIG-11](../../3-design/FIG-11-CATALOG.md),
[COMP-5](../../3-design/design-system/COMP-5-PROBLEM-CARD.md),
[COMP-6](../../3-design/design-system/COMP-6-DIFFICULTY-BADGE.md),
[COMP-7](../../3-design/design-system/COMP-7-PROGRESS-BADGE.md),
[TOKEN-6](../../3-design/design-system/TOKEN-6-TAP.md),
[TOKEN-7](../../3-design/design-system/TOKEN-7-COLOR.md).

## Предусловия

- Локальная сборка `main` с `yege_wars_dev`, `http://localhost:8080/`;
  ученик `TEST_LOGIN2_*` из `supabase/.env.dev.local`. Хэш сборки — в раунд.
- Полный кейс на 1440×900 и 360×800 с mobile/touch и мобильным user agent.
  Для 360 в начало `initScript` добавить переопределение
  `navigator.platform` из [TC-11](obsolete/TC-11-CATALOG-FILTERS.md), «Предусловия и
  подстановки»; для 1440 оставить настольную платформу.
- Chrome DevTools MCP: `navigate_page` поддерживает `initScript` до скриптов
  приложения. В новой вкладке сначала войти учеником, затем загрузить
  `http://localhost:8080/#/` с начальным скриптом ниже. Подмена живёт только
  в этой вкладке и не меняет данные Supabase. Авторизация остаётся настоящей.
- Этот кейс проверяет клиент на заданных ответах. Интеграцию с реальными
  данными проверяет [TC-11](obsolete/TC-11-CATALOG-FILTERS.md).
  В журнале явно указать подменённые ответы; не выдавать их за ответы базы.

## Начальный скрипт

Передать целиком в `initScript`, исходный режим — `cards`.
Для других режимов заменить только строку `mode: 'cards'` до навигации.
После запуска `window.__catalogCase` содержит только режим и счётчики;
заголовки авторизации, токены, адрес проекта и ответы задач не сохраняются.
Если запросы приложения не попадают в перехватчик, сценарий — `BLOCKED`,
а не `PASS`: записать, какой маршрут не перехвачен. Не переходить на
изменение базы или кода продукта.

```javascript
(() => {
  if (!['localhost', '127.0.0.1'].includes(location.hostname)) {
    throw new Error('Кейс разрешён только на локальной сборке');
  }
  const originalFetch = window.fetch.bind(window);
  const state = window.__catalogCase = {
    mode: 'cards',
    calls: {},
    replaced: {},
  };
  const id = n => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
  const rows = [
    [1, 17, 'Тест каталога А', 1],
    [2, 17, 'Тест каталога Б', 2],
    [3, 24, 'Тест каталога В', 3],
    [4, null, 'Тест каталога Г', 1],
  ].map(([n, ege_number, title, difficulty]) => ({
    id: id(n), slug: `tc-catalog-${n}`, ege_number, title,
    difficulty, tags: [],
  }));
  const data = {
    tasks: rows,
    numbers: rows.map(({ege_number}) => ({ege_number})),
    stats: [
      {task_id: id(1), attempted_students: 2,
        solved_students: 1, solved_percent: 50},
      {task_id: id(2), attempted_students: 2,
        solved_students: 0, solved_percent: 0},
      {task_id: id(3), attempted_students: 0,
        solved_students: 0, solved_percent: 0},
    ],
    attempts: [
      {task_id: id(1), is_correct: false},
      {task_id: id(1), is_correct: true},
      {task_id: id(2), is_correct: false},
    ],
  };
  const json = (body, status = 200) => new Response(
    JSON.stringify(body),
    {status, headers: {'Content-Type': 'application/json'}},
  );
  window.fetch = async (input, init) => {
    const address = typeof input === 'string' ? input
      : input instanceof URL ? input.href : input.url;
    const url = new URL(address, location.href);
    const method = (init?.method || input.method || 'GET').toUpperCase();
    const select = (url.searchParams.get('select') || '').replace(/\s/g, '');
    let kind;
    if (method === 'GET' && url.pathname === '/rest/v1/tasks_public') {
      if (select === 'ege_number') kind = 'numbers';
      else if (select.includes('title') && !url.searchParams.has('slug')) {
        kind = 'tasks';
      }
    } else if (method === 'POST' &&
        url.pathname === '/rest/v1/rpc/get_task_stats') {
      kind = 'stats';
    } else if (method === 'GET' &&
        url.pathname === '/rest/v1/submissions' &&
        select === 'task_id,is_correct' && url.searchParams.has('user_id')) {
      kind = 'attempts';
    }
    if (!kind) return originalFetch(input, init);
    state.calls[kind] = (state.calls[kind] || 0) + 1;
    const fixture = ['cards', 'empty'].includes(state.mode);
    const offline = state.mode === 'tasks-offline' && kind === 'tasks';
    const failed = state.mode === `${kind}-error`;
    if (!fixture && !offline && !failed) return originalFetch(input, init);
    state.replaced[kind] = (state.replaced[kind] || 0) + 1;
    if (offline) throw new TypeError('Имитация недоступности каталога');
    if (failed) return json({code: 'XX000',
      message: 'Имитация сбоя каталога', details: null, hint: null}, 503);
    return json(state.mode === 'empty' ? [] : data[kind]);
  };
})();
```

В `cards` серверный отбор по номеру, сложности и названию не имитируется:
их здесь не нажимать. Отбор по прогрессу выполняет само приложение над
заданными задачами и попытками. Открывать карточки `tc-catalog-*` нельзя:
таких задач в базе нет, переход проверяется в TC-11.

## Шаги

| № | Шаг и входные данные | Ожидаемый результат | Путь |
|---|---|---|---|
| 1 | Загрузить каталог с `initScript`, режим `cards`; дождаться данных, проверить счётчики | Есть перехваченные `tasks`, `numbers`, `stats`, `attempts`; чипы номеров ровно «№ 17» и «№ 24», без повторов и чипа для `null`. Группы: «Задание 17» с А, Б; «Задание 24» с В; «Без номера» с Г последней | UC-14-P-01, UC-14-P-02 |
| 2 | Сверить все четыре карточки | А — «Простая», галочка и «Решено», «Решили 50%»; Б — «Средняя», многоточие и «Есть попытки», «Решили 0%»; В — «Сложная», без метки прогресса, «Ещё никто не решал»; Г — «Простая», без метки прогресса, «Ещё никто не решал» | UC-14-P-01 |
| 3 | Выбрать «Решено» | Осталась только А в группе «Задание 17»; чип выбран, кнопка сброса видна | UC-14-P-02 |
| 4 | Не снимая предыдущий фильтр вручную, выбрать «Есть попытки» | «Решено» снят; осталась только Б в группе «Задание 17» | UC-14-P-02 |
| 5 | Выбрать «Не начата» | Остались В и Г в группах «Задание 24» и «Без номера»; ни на одной карточке нет метки «Не начата». Лишних пустых заголовков групп нет | UC-14-P-01, UC-14-P-02 |
| 6 | Повторно нажать «Не начата», затем снова выбрать «Решено» и нажать «Сбросить фильтры» | В обоих случаях снятия отбора возвращаются все четыре карточки в исходном порядке; после сброса все чипы прогресса сняты, кнопка сброса скрыта | UC-14-P-02 |
| 7 | В той же вошедшей вкладке выполнить новую загрузку с исходным скриптом в режиме `empty`; проверить счётчики | Все четыре ответа подменены пустыми массивами. При пустом поиске и без выбранных чипов — «Задач пока нет», карточек и заголовков групп нет, чипов номеров нет; ошибки и «Повторить» нет | UC-14-P-03 |
| 8 | На пустом каталоге выбрать «Сложная», затем повторно снять выбор | С выбранным условием — «По этим условиям задач нет», видна кнопка сброса; после снятия — «Задач пока нет», кнопка сброса скрыта | UC-14-P-02, UC-14-P-03 |

## Вид, доказательства и завершение

На каждой ширине скриншот каждого шага, для шага 2 — всех карточек
после прокрутки. Вид соответствует FIG-11 и компонентам; цвета сложности
и прогресса — TOKEN-7. «Сбросить фильтры» на компьютере не ниже 44;
проверить реальные области нажатия по TOKEN-6. Ничего не перекрывается,
не обрезается, вся страница вбок не прокручивается.

Для каждого режима записать только режим, счётчики и наблюдаемое UI.
Нативный сетевой журнал может не содержать синтетические ответы: факт
подмены доказывают `replaced` и наблюдаемые карточки/пустое состояние.
Нулевой счётчик нужного маршрута не подтверждает его проверку.

После кейса закрыть вкладку с подменой и открыть отдельную чистую вкладку
сборки без `initScript`: обычный каталог реального проекта снова загружается.
Значений доступов и токенов в раунде нет; база не менялась.
Вердикт и фактические наблюдения заполняет тестировщик после прогона.
