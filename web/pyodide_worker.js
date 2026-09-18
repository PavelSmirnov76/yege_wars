// Web Worker с Pyodide: выполняет код ученика в отдельном потоке, чтобы
// бесконечный цикл не вешал интерфейс. Остановка — terminate() со стороны
// приложения, после чего воркер создаётся заново.
//
// Протокол сообщений:
//   приложение -> воркер: {id, type: 'run', code, stdin, files}
//   воркер -> приложению: {type: 'loading'} | {type: 'ready'}
//                         {id, type: 'result', stdout, stderr, failed}

'use strict';

const PYODIDE_VERSION = '314.0.7';
const PYODIDE_INDEX_URL =
  'https://cdn.jsdelivr.net/npm/pyodide@' + PYODIDE_VERSION + '/';

importScripts(PYODIDE_INDEX_URL + 'pyodide.js');

/** Загрузка Pyodide начинается при первом запуске и переиспользуется. */
let pyodidePromise = null;

/** Имена файлов, записанных в виртуальную ФС прошлым запуском. */
let writtenFiles = new Set();

function ensurePyodide() {
  if (pyodidePromise === null) {
    self.postMessage({ type: 'loading' });
    pyodidePromise = loadPyodide({ indexURL: PYODIDE_INDEX_URL }).then(
      (pyodide) => {
        self.postMessage({ type: 'ready' });
        return pyodide;
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

self.onmessage = async (event) => {
  const message = event.data || {};
  if (message.type !== 'run') {
    return;
  }

  const stdout = [];
  const stderr = [];
  try {
    const pyodide = await ensurePyodide();
    writeFiles(pyodide, message.files);
    bindStreams(pyodide, message.stdin, stdout, stderr);

    await pyodide.runPythonAsync(message.code || '');

    self.postMessage({
      id: message.id,
      type: 'result',
      stdout: stdout.join('\n'),
      stderr: stderr.join('\n'),
      failed: false,
    });
  } catch (error) {
    // У ошибки Python в message лежит готовая трассировка.
    const text = error && error.message ? error.message : String(error);
    self.postMessage({
      id: message.id,
      type: 'result',
      stdout: stdout.join('\n'),
      stderr: [stderr.join('\n'), text].filter(Boolean).join('\n'),
      failed: true,
    });
  }
};
