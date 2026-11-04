# TC-17: Страница задачи — состояния файлов и сбои загрузки

**Цель:** проверить воспроизводимые состояния страницы и восстановление после
сбоя задачи, файлов или черновика. Проверяется клиент на подменённых ответах.
**Пути UC:** [UC-15-P-01](../../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-01), [UC-15-P-03](../../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-03), [UC-31-P-04](../../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-04).
**Приоритет:** высокий — сбой источника не должен выглядеть как пустая задача.
**Дизайн:** [FIG-20](../../3-design/FIG-20-PROBLEM.md),
[COMP-12](../../3-design/design-system/COMP-12-ERROR-RETRY.md),
[TOKEN-6](../../3-design/design-system/TOKEN-6-TAP.md).

## Предусловия

Окружение, вход и обе ширины — по [TC-16](TC-16-PROBLEM-PAGE-FILES.md).
Здесь T заменена синтетической страницей /#/task/tc-problem-page.
До навигации передать начальный скрипт ниже через initScript; авторизация
настоящая. Для mobile переопределение platform идёт перед этим скриптом.
Для каждого нового режима — полная загрузка в своей вкладке с начальным
`window.__taskCaseConfig = {mode: 'нужный-режим'};` перед скриптом.
Исходный режим без конфига — good.

Данные и строки ниже вымышлены, не являются ответами задач или решениями
банка. Скрипт не сравнивает ответы математически. Отправку проверяет
отдельный клиентский кейс; в этом кейсе ответ/код не редактировать.

## Начальный скрипт

Скрипт общий для состояний страницы и клиентского кейса отправки этого среза.
Подменённые ответы не появляются в нативном Network: доказательства —
счётчики calls/replaced и наблюдаемый UI. Не перехвачен нужный маршрут —
BLOCKED, а не переход к изменению БД или кода. Журнал не содержит заголовков,
токенов и реальных ответов. Не включать общий offline.

```javascript
(() => {
  if (!['localhost', '127.0.0.1'].includes(location.hostname)) {
    throw new Error('Только локальная сборка');
  }
  const originalFetch = window.fetch.bind(window);
  const id = n => `10000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
  const taskId = id(1);
  const state = window.__taskCase = {
    mode: window.__taskCaseConfig?.mode ?? 'good',
    submitMode: 'wrong', delayMs: 0, calls: {}, replaced: {},
    blockedWrites: 0, attempts: [], lastSubmit: null, code: '# tc_ui_marker',
  };
  const count = (name) => {
    state.calls[name] = (state.calls[name] ?? 0) + 1;
    state.replaced[name] = (state.replaced[name] ?? 0) + 1;
  };
  const json = (body, status = 200) => new Response(JSON.stringify(body), {
    status, headers: {'Content-Type': 'application/json'},
  });
  const failure = message => json({code: 'P0001', message,
    details: null, hint: null}, 400);
  const serverError = () => json({code: 'XX000', message: 'tc_fault',
    details: null, hint: null}, 503);
  const offline = () => {throw new TypeError('Failed to fetch');};
  const task = {
    id: taskId, slug: 'tc-problem-page', title: 'Тест страницы задачи',
    ege_number: 17, difficulty: 2, tags: [], answer_format: 'string',
    statement_md: 'Синтетическое условие для проверки интерфейса.\n\n' +
      'Второй абзац.\n\n| Имя | Значение |\n| --- | --- |\n| Тест | UI |',
    source: 'Тест интерфейса',
  };
  const contents = ['alpha\nbeta\n',
    ['x'.repeat(10001), ...Array.from({length: 11}, (_, i) => `row-${i+2}`)]
      .join('\n')];
  state.files = contents.map((content, i) => ({
    filename: ['z-small.txt', 'a-long.txt'][i], content,
    size_bytes: new TextEncoder().encode(content).length,
  }));
  state.restore = () => {window.fetch = originalFetch;};
  window.fetch = async (input, init) => {
    const request = new Request(input, init);
    const url = new URL(request.url);
    if (!url.pathname.startsWith('/rest/v1/')) {
      return originalFetch(request);
    }
    const name = url.pathname.slice('/rest/v1/'.length);
    const method = request.method.toUpperCase();
    const isTask = url.searchParams.get('task_id') === `eq.${taskId}`;
    const mode = state.mode;
    if (name === 'tasks_public' && method === 'GET') {
      const slug = url.searchParams.get('slug');
      count(slug ? 'task' : 'catalog');
      if (slug === 'eq.tc-problem-page' && mode === 'task-error') {
        return serverError();
      }
      if (slug === 'eq.tc-problem-page' && mode === 'task-offline') {
        return offline();
      }
      if (slug && slug !== 'eq.tc-problem-page') return json([]);
      return json([task]);
    }
    if (name === 'task_files' && isTask && method === 'GET') {
      count('files');
      if (mode === 'files-error') return serverError();
      return json(mode === 'empty-files' ? [] : state.files);
    }
    if (['task_references', 'task_articles'].includes(name) &&
        isTask && method === 'GET') {
      count(name); return json([]);
    }
    if (name === 'drafts' && isTask && method === 'GET') {
      count('draft');
      return mode === 'draft-error' ? serverError() : json([{code: state.code}]);
    }
    if (name === 'drafts' && method !== 'GET') {
      // Сохранение черновика при отправке тоже не должно уйти в dev.
      count('draftWrite');
      return new Response(null, {status: 204});
    }
    if (name === 'submissions' && method === 'GET') {
      if (isTask) {
        const published = url.searchParams.get('is_published') === 'eq.true';
        count(published ? 'solutions' : 'attempts');
        if (!published && mode === 'attempts-error') return serverError();
        return json(published ? [] : state.attempts);
      }
      // Фоновое обновление прогресса каталога после отправки.
      count('catalogAttempts');
      return json(state.attempts.map(row => ({
        task_id: taskId, is_correct: row.is_correct,
      })));
    }
    if (name === 'rpc/get_task_stats') {
      count('stats');
      const solved = state.attempts.some(row => row.is_correct);
      return json([{task_id: taskId,
        attempted_students: state.attempts.length ? 1 : 0,
        solved_students: solved ? 1 : 0, solved_percent: solved ? 100 : 0}]);
    }
    if (name === 'rpc/submit_solution' && method === 'POST') {
      const body = await request.clone().json();
      if (body.p_task_id !== taskId) {
        state.blockedWrites++; return failure('[forbidden] Не та задача кейса.');
      }
      count('submit');
      state.lastSubmit = {p_task_id: taskId,
        p_answer: body.p_answer, p_code: body.p_code};
      const submitMode = state.submitMode;
      if (state.delayMs) {
        await new Promise(resolve => setTimeout(resolve, state.delayMs));
      }
      if (submitMode === 'offline') return offline();
      if (submitMode === 'error') return serverError();
      if (submitMode === 'rate') {
        return failure('[rate_limit] Слишком много отправок, подождите минуту.');
      }
      if (submitMode === 'missing') {
        return failure('[task_not_found] Задача не найдена или недоступна.');
      }
      const row = {
        id: id(100 + state.attempts.length), answer: body.p_answer,
        code: body.p_code, is_correct: submitMode === 'correct',
        is_published: false, created_at: new Date().toISOString(),
      };
      state.attempts.unshift(row);
      return json({submission_id: row.id, is_correct: row.is_correct});
    }
    // Любые остальные записи REST запрещены, в том числе публикация.
    if (!['GET', 'HEAD', 'OPTIONS'].includes(method)) {
      state.blockedWrites++;
      return failure('[forbidden] Запись не входит в кейс.');
    }
    return originalFetch(request);
  };
})();
```

## Шаги

| № | Действие | Ожидаемый результат |
|---|---|---|
| 1 | Режим good: открыть синтетическую T, вкладку «Файлы», раскрыть оба файла | Условие, источник и номер соответствуют fixture. Файлы z-small.txt, a-long.txt именно в таком порядке. Первый целиком в preview; второй — 10 строк и признак продолжения, первая строка усечена после 10 000 символов. Горизонтальная прокрутка длинной строки внутри preview, вся страница не расширяется |
| 2 | Новая загрузка с empty-files, открыть «Файлы» | «У задачи нет файлов с данными», карточек/кнопок копирования и скачивания нет; это успешная страница, без «Повторить» |
| 3 | По очереди task-error и files-error: дождаться ошибки; сохранить счётчик соответствующего маршрута, изменить mode на good и нажать «Повторить» без reload | В каждом режиме replaced нужного маршрута > 0. Вместо страницы — «Ошибка при работе с данными. Попробуйте позже.» и «Повторить», не пустые файлы. До нажатия ошибка остаётся; после — новый запрос нужного маршрута, полная страница и файлы восстановлены |
| 4 | Аналогично task-offline → good → «Повторить» | «Нет соединения с сервером. Проверьте интернет.», после нажатия страница восстановлена. Настоящая авторизация не потеряна |
| 5 | Аналогично draft-error → good → «Повторить» | Ошибка вместо всей страницы, а не пустой редактор или частично открытая задача. После повтора счётчик draft растёт, страница восстановлена с тестовым черновиком |

## Доказательства и завершение

Каждый режим выполнить на обеих ширинах. Кадры: good и empty-files;
для каждого из четырёх сбоев — ошибка и итог повтора. Это разные состояния,
их не заменяет один общий кадр. В журнале — режим, счётчики до/после,
наблюдение против ожидания и ссылки на кадры. Полное содержимое длинного
файла в журнал не печатать; длину и предел preview проверить программно.
У «Повторить» тап-цель не меньше 44×44; текст не обрезан, навигация доступна.

blockedWrites должен оставаться 0. Не выдавать подмену за проверку сервера.
Закрыть только свои вкладки; в открытой вкладке снять hook через restore.
Данные Supabase и код продукта не менялись; вердикт — по факту.
