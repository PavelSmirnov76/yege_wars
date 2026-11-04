# TC-16 — дополнение 02 (2026-11-04)

**Основание:** закрытие оставшихся пунктов TC-16 после followup-01.

**Сборка и окружение:** сохранённый release `build/web` от `f09639a32f5a05294b88a0baa1d080b0f6e1a1d4`, локальный сервер `127.0.0.1:8080`, штатный тестовый вход. Node `v24.15.0`, Playwright `1.64.1`, Chrome for Testing/Chromium `156.0.8078.4`. Отступление: вместо Chrome DevTools MCP использован Playwright Chromium с отдельными browser contexts и без пользовательского профиля.

## Clipboard/download capability smoke

В отдельном context на loopback origin clipboard permissions были выданы только этому origin. До Copy исходный clipboard прочитан в памяти; native Clipboard API round-trip совпал, исходное значение восстановлено. Download ожидался до клика, сохранён через `saveAs` во временный каталог, сравнен по имени, байтам и SHA-256: имя совпало, 23 байта, hash совпал. Временный файл удалён; содержимое искусственного файла и clipboard в лог не попали. **Smoke: PASS.**

- Скрипт: `/tmp/yege-tc16-pw/smoke.cjs`.
- Команда: `node /tmp/yege-tc16-pw/smoke.cjs > /tmp/yege-tc16-playwright.log 2>&1; code=$?; cat /tmp/yege-tc16-playwright.log; echo exit=$code; exit $code` — exit 0.
- Лог: `/tmp/yege-tc16-playwright.log`.

## Реальная задача и файл на двух ширинах

На 1440×900 и 360×800 выполнен отдельный штатный тестовый вход. На каждой ширине задача `e24-longest-run` открыта из каталога через поиск по названию и клик по карточке. Скриншоты каталожного открытия: [1440](screenshots/followup-02-rerun-1440-task.png), [360](screenshots/followup-02-rerun-360-task.png).

После клика «Файлы» диагностика показала выбранную вкладку (`aria-selected=true`). Перед поиском карточки в памяти были получены ровно один `tasks_public` response и один `task_files` response; `task_id` совпал. Файл `24.txt`, полный `content` — 1 000 001 UTF-8 байт; в response присутствует поле `size_bytes`. UI показывает `977 КБ`. Имя expansion control объединяет имя файла и размер, поэтому использован role locator по `24.txt` без `exact:true`. Отдельный диагностический кадр после выбора вкладки: [1440](screenshots/followup-02-diagnostic-files-tab.png). Кадры раскрытого файла и preview: [1440](screenshots/followup-02-rerun-1440-files-preview.png), [360](screenshots/followup-02-rerun-360-files-preview.png). На обоих кадрах визуально видны «Первые строки», превью и кнопки; содержимое файла не переносится в журнал. В desktop Playwright text locator preview-label вернул false при видимом на кадре тексте; desktop подтверждён визуальным кадром, mobile locator вернул true.

| Проверка | 1440×900 | 360×800, touch, Android UA, `Linux armv8l` |
|---|---:|---:|
| Copy bounds | 155×48 px | 155×48 px |
| Download bounds | 130.2×48 px | 130.2×48 px |
| Исходный clipboard прочитан | да | да |
| Native clipboard равен полному content | да | да |
| Исходный clipboard восстановлен до закрытия context | да | да |
| Download имя | `24.txt`, совпало | `24.txt`, совпало |
| Download байты | 1 000 001, совпали | 1 000 001, совпали |
| SHA-256 expected = actual | `5099ef4c1797fa4306b65d292ceeef3bf53cd27a5d9c8cbdcb7cf4c1b890e76c` | `5099ef4c1797fa4306b65d292ceeef3bf53cd27a5d9c8cbdcb7cf4c1b890e76c` |

Контент response, clipboard и токены не выводились. Copy и Download были нажаты в интерфейсе; response не подменялся. Временные скачивания удалены после сравнения.

## Неизвестный slug и Retry

На обеих ширинах после перехода к `tc-missing-2026-11-04` показано «Задача не найдена или ещё не открыта.» и «Повторить». После реального клика Retry UI остался тем же; точный `tasks_public` запрос с тем же slug вырос с 1 до 2. Bounds Retry — 120.8×48 px на 1440×900 и 120.8×48 px на 360×800. Кадры после Retry: [1440](screenshots/followup-02-rerun-1440-missing-after.png), [360](screenshots/followup-02-rerun-360-missing-after.png). На снимках может оставаться snackbar «Файл скопирован в буфер обмена» от предыдущего Copy; экран неизвестной задачи и повторный запрос зафиксированы отдельно от условия T.

## Исправление записи и итог

Предыдущая версия этого дополнения неверно приписала timeout клику по вкладке. Основной прогон уже успешно нажал её; timeout произошёл позже на `getByText('24.txt', exact:true)`. Следующая отдельная диагностика подтвердила `aria-selected=true`, один file response и имя expansion control `24.txt 977 КБ`. После выбора locator по role/name реальная проверка завершилась на обеих ширинах.

Воспроизводимый сценарий и итоговый лог: `/tmp/yege-tc16-pw/phase2.cjs`, `/tmp/yege-tc16-phase2.log`. Скрипт проверяет обязательные равенства и bounds; exit 0 только если обе ширины прошли все проверки. Реальный запуск — exit 0. Сервер остановлен, оба browser context закрыты только после восстановления clipboard. Данные Supabase не менялись; попытки, ответы и код не открывались.

**Вердикт:** PASS

## Архив воспроизводимых материалов

Безопасные источники и JSON-итоги сохранены в [`playwright/`](playwright/): `smoke.cjs`, `phase2.cjs`, `smoke-result.json`, `phase2-result.json`, `metadata.json`. В них нет node_modules, cache, скачанных файлов, clipboard value или content response. SHA-256 в таблице сверён и вставлен непосредственно из JSON реального прогона.

После фактического UI-прогона сохранённый сценарий получил два локальных улучшения: параметрический `TC16_SCREENSHOTS_DIR` с repo-relative default и fail-safe guard, который делает `result.pass=false`, если финальное восстановление clipboard не удалось. Обновлённый файл проверен `node --check` и ревью исходника; UI-прогон на нём не запускался. `browser.version()` проверен отдельным коротким launch/version/close без открытия страницы: `156.0.8078.4`. Результат TC-16 выше относится к ранее выполненному UI-прогону; изменения воспроизводимого helper не меняют фактические наблюдения.
