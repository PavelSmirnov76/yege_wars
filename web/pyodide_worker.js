// Web Worker с Pyodide: выполняет код ученика в отдельном потоке, чтобы
// бесконечный цикл не вешал интерфейс. Остановка — terminate() со стороны
// приложения, после чего воркер создаётся заново.
//
// Воркер МОДУЛЬНЫЙ (создаётся с type: 'module'), и это не вкусовщина:
// importScripts с другого домена современный Chrome не выполняет, а сам
// загрузчик Pyodide тянет свои части динамическим import(), которого в
// классическом воркере нет. Поэтому загружаем pyodide.mjs через import().
//
// Протокол сообщений:
//   приложение -> воркер: {id, type: 'run', code, stdin, files}
//   воркер -> приложению: {type: 'loading'} | {type: 'ready'}
//                         {type: 'log', text}
//                         {id, type: 'result', stdout, stderr, failed}

const PYODIDE_VERSION = '314.0.7';

// Зеркала по порядку: если первое недоступно, пробуем следующее. Это не
// перестраховка — в разных сетях доступны разные CDN.
const PYODIDE_MIRRORS = [
  'https://cdn.jsdelivr.net/npm/pyodide@' + PYODIDE_VERSION + '/',
  'https://unpkg.com/pyodide@' + PYODIDE_VERSION + '/',
];

// Сколько символов вывода отдаём приложению. Ученик легко печатает файл
// целиком (миллион символов), и тогда рисование такого текста вешает
// интерфейс намертво — обрезаем на стороне воркера.
const OUTPUT_LIMIT = 20000;

/** Загрузка Pyodide начинается при первом запуске и переиспользуется. */
let pyodidePromise = null;

/** Имена файлов, записанных в виртуальную ФС прошлым запуском. */
let writtenFiles = new Set();

function log(text) {
  self.postMessage({ type: 'log', text: text });
}

/**
 * Грузит Pyodide, перебирая зеркала.
 *
 * Загрузка вынесена из верхнего уровня файла намеренно: падение на верхнем
 * уровне убивало бы воркер целиком, и приложение получало бы событие error
 * без текста. Здесь причина доходит до пользователя.
 */
async function loadFromMirrors() {
  const problems = [];
  for (const indexURL of PYODIDE_MIRRORS) {
    try {
      log('загружаю Pyodide: ' + indexURL);
      const module = await import(indexURL + 'pyodide.mjs');
      const pyodide = await module.loadPyodide({ indexURL: indexURL });
      log('Pyodide загружен: ' + indexURL);
      return pyodide;
    } catch (error) {
      const text = error && error.message ? error.message : String(error);
      problems.push(indexURL + ' — ' + text);
      log('не вышло: ' + indexURL + ' — ' + text);
    }
  }
  throw new Error(
    'Не удалось загрузить Python ни с одного адреса:\n' + problems.join('\n'),
  );
}

function ensurePyodide() {
  if (pyodidePromise === null) {
    self.postMessage({ type: 'loading' });
    pyodidePromise = loadFromMirrors().then(
      (pyodide) => {
        self.postMessage({ type: 'ready' });
        return pyodide;
      },
      (error) => {
        // Сбрасываем обещание: следующий запуск попробует снова.
        pyodidePromise = null;
        throw error;
      },
    );
  }
  return pyodidePromise;
}

/** Записывает файлы задания под их настоящими именами. */
function writeFiles(pyodide, files) {
  // Файлы прошлого запуска убираем: имена могли измениться.
  for (const name of writtenFiles) {
    try {
      pyodide.FS.unlink(name);
    } catch (error) {
      // Файла уже нет — это не ошибка.
    }
  }
  writtenFiles = new Set();

  for (const name of Object.keys(files || {})) {
    pyodide.FS.writeFile(name, files[name], { encoding: 'utf8' });
    writtenFiles.add(name);
  }
}

/** Подменяет потоки ввода-вывода на буферы. */
function bindStreams(pyodide, stdin, stdout, stderr) {
  const lines = (stdin || '').length === 0 ? [] : String(stdin).split('\n');
  let nextLine = 0;

  pyodide.setStdin({
    // null означает конец ввода: input() получит EOFError, как в CPython.
    stdin: () => (nextLine < lines.length ? lines[nextLine++] : null),
    isatty: false,
  });
  pyodide.setStdout({ batched: (text) => stdout.push(text) });
  pyodide.setStderr({ batched: (text) => stderr.push(text) });
}

/** Склеивает вывод и обрезает его до разумного размера. */
function joinOutput(parts) {
  const text = parts.join('\n');
  if (text.length <= OUTPUT_LIMIT) {
    return text;
  }
  const hidden = text.length - OUTPUT_LIMIT;
  return (
    text.slice(0, OUTPUT_LIMIT) +
    '\n\n… показаны первые ' + OUTPUT_LIMIT + ' символов, скрыто ' +
    hidden + '. Печатай ответ, а не весь файл.'
  );
}

self.onmessage = async (event) => {
  const message = event.data || {};
  if (message.type !== 'run') {
    return;
  }

  const stdout = [];
  const stderr = [];
  try {
    const pyodide = await ensurePyodide();
    const startedAt = Date.now();
    writeFiles(pyodide, message.files);
    log('файлы записаны за ' + (Date.now() - startedAt) + ' мс');
    bindStreams(pyodide, message.stdin, stdout, stderr);

    await pyodide.runPythonAsync(message.code || '');
    log('программа отработала за ' + (Date.now() - startedAt) + ' мс');

    self.postMessage({
      id: message.id,
      type: 'result',
      stdout: joinOutput(stdout),
      stderr: joinOutput(stderr),
      failed: false,
    });
  } catch (error) {
    // У ошибки Python в message лежит готовая трассировка; у ошибки
    // загрузки — перечень адресов и причин.
    const text = error && error.message ? error.message : String(error);
    self.postMessage({
      id: message.id,
      type: 'result',
      stdout: joinOutput(stdout),
      stderr: joinOutput([joinOutput(stderr), text].filter(Boolean)),
      failed: true,
    });
  }
};

// Ошибки, до которых не дотянулся try/catch, тоже должны доходить.
self.onerror = (event) => {
  log('ошибка воркера: ' + (event && event.message ? event.message : event));
};
