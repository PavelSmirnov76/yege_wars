# Clipboard и download в браузерных проверках

Для этих операций доступного Chrome DevTools MCP оказалось недостаточно.
Проверенный способ — отдельный Playwright Chromium с новым context,
разрешениями clipboard только для loopback origin и ожиданием download.
Реальный TC-16 с e24-longest-run прошёл на 1440×900 и 360×800.

Проверенное окружение: Node 24.15.0, Playwright 1.64.1, Chromium 156.0.8078.4.
Этот прогон выполнила Luna без изменений продуктового кода и зависимостей Flutter.

## Сохранённый пример

[Исходники и безопасные результаты](../sdlc/6-eval/manual/2026-11-04/TC-16/playwright/)
содержат smoke.cjs, phase2.cjs и JSON-итоги. Это пример для конкретного TC-16,
не общий E2E framework. Пара защитных/переносимых правок после прогона
перечислена в metadata.json; на них выполнены syntax check и ревью,
полный UI-прогон после этих правок не повторялся.

Команды ниже выполняются из корня репозитория. Зависимости устанавливаются
в отдельный временный каталог:

```sh
tc16_runtime=$(mktemp -d /tmp/yege-tc16-runtime.XXXXXX)
tc16_sources=sdlc/6-eval/manual/2026-11-04/TC-16/playwright
cp "$tc16_sources/smoke.cjs" "$tc16_sources/phase2.cjs" "$tc16_runtime/"
npm install --prefix "$tc16_runtime" --no-save --package-lock=false playwright@1.64.1
"$tc16_runtime/node_modules/.bin/playwright" install chromium
node "$tc16_runtime/smoke.cjs"
```

Продолжать только при exit 0 и успешных clipboard round-trip/restore и download
comparison. Smoke использует искусственный файл и собственный loopback сервер.

Для реального кейса нужна локальная dev-сборка по README, настроенная на
тестового ученика. Сохранённый пример использовал сборку f09639a с тестовой
кнопкой TEST_LOGIN2. В другом терминале из корня репозитория:

```sh
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

В терминале с tc16_runtime:

```sh
tc16_capture=$(mktemp -d /tmp/yege-tc16-capture.XXXXXX)
TC16_SCREENSHOTS_DIR="$tc16_capture" node "$tc16_runtime/phase2.cjs"
```

Новый каталог нужен, чтобы не перезаписать принятые скриншоты. После проверки
остановить свой сервер, зафиксировать нужные доказательства и удалить только
свои временные каталоги. Context/browser и временный download скрипт закрывает
и удаляет сам; clipboard восстанавливает до закрытия context.

## Что проверяет драйвер

- Штатный вход и открытие конкретной T из каталога. Ожидаемое содержимое
  берётся из реального ответа task_files именно этой T, только в память.
- Copy вызывается нажатием UI; clipboard сравнивается с полным content,
  затем исходное значение восстанавливается и проверяется. Если исходное
  значение нельзя прочитать, Copy не нажимается.
- Download ожидается до клика, сохраняется через saveAs, проверяются имя,
  байты и SHA-256. Подмен Blob/clipboard/download API нет.
- Измеряются Copy/Download/Retry; проверяется новый запрос и прежнее
  сообщение после Retry для неизвестного slug.

В отчёт попадают сравнения, размеры, счётчики и хэши; содержимое clipboard,
файла, токены и заголовки авторизации не сохраняются. Exit 0 относится к
машинным проверкам; вид кадров и соответствие кейсу принимает постановщик.
Изменение браузера относительно кейса фиксируется отступлением в журнале.

Flutter accessibility: desktop — focus placeholder и настоящий Enter;
mobile — tap точно в центр placeholder. После полной загрузки включать
заново и проверять появление flt-semantics. У file ExpansionTile объединённое
доступное имя, поэтому exact text locator по одному filename может не найти
контрол. Использовать фактические role/name и проверять aria-selected вкладки.

API: [разрешения context](https://playwright.dev/docs/api/class-browsercontext#browser-context-grant-permissions),
[скачивание](https://playwright.dev/docs/downloads).
