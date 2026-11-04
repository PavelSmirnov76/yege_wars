# TC-17 — прогон 2026-11-04

**Исполнитель:** тестировщик Luna, Chrome DevTools MCP.
**Сборка:** локальный `main`, commit `f09639a32f5a05294b88a0baa1d080b0f6e1a1d4`, release web, Supabase `yege_wars_dev`, `http://127.0.0.1:8080`.
**Окна:** desktop 1440×900; mobile 360×800, touch/mobile UA, `navigator.platform = Linux armv8l`.
**Данные:** только синтетический fixture `tc-problem-page`; все режимы устанавливались из замороженного TC-17 script до полной перезагрузки. Записи запрещены hook; `blockedWrites=0` во всех проверенных режимах. Это клиентские API-подмены, не end-to-end проверка Supabase.

| Шаг / режим | Ожидалось | Наблюдалось | Доказательство |
|---|---|---|---|
| 1 good, 1440 | Fixture, два файла в порядке `z-small.txt`, `a-long.txt`; второй preview ограничен | Номер 17, средняя сложность, условие и источник fixture. Порядок файлов верный. Второй preview визуально показывает усечённую длинную первую строку, строки 2–10 и многоточие; длина полного fixture — 10 070 символов/байт. Точную длину первой строки в UI программно не измерил | [01 desktop good](screenshots/01-desktop-good.png), [02 файлы](screenshots/02-desktop-good-files-expanded.png), [21 длинный файл](screenshots/22-desktop-long-file.png) |
| 1 good, 360 | То же; нет горизонтального overflow | То же; файлы доступны через горизонтально прокручиваемую строку вкладок. `document.documentElement.scrollWidth > innerWidth` вернуло `false` на обеих ширинах | [03 mobile good](screenshots/03-mobile-good.png), [22 длинный файл](screenshots/23-mobile-long-file.png) |
| 2 empty-files, обе ширины | Пустое состояние без кнопок файла и «Повторить» | Показано «У задачи нет файлов с данными»; hook вернул пустой список; «Повторить» отсутствует | [20 desktop](screenshots/20-desktop-empty-files.png), [20 mobile](screenshots/21-mobile-empty-files.png) |
| 3 task-error → good + «Повторить», обе ширины | Ошибка; запрос task повторяется, fixture восстанавливается | Сообщение ошибки показано. После клика счётчик task вырос с 4 до 5, fixture восстановился | [12–13 desktop](screenshots/12-desktop-task-error-error.png), [13](screenshots/13-desktop-task-error-recovered.png); [04–05 mobile](screenshots/04-mobile-task-error.png), [05](screenshots/05-mobile-recovered.png) |
| 3 files-error → good + «Повторить», обе ширины | Ошибка файлов вместо пустого результата; повторный запрос восстанавливает fixture | Ошибка показана. Счётчик files вырос с 4 до 5 на повторе; fixture восстановился | [14–15 desktop](screenshots/14-desktop-files-error-error.png), [15](screenshots/15-desktop-files-error-recovered.png); [06–07 mobile](screenshots/06-mobile-files-error-error.png), [07](screenshots/07-mobile-files-error-recovered.png) |
| 4 task-offline → good + «Повторить», обе ширины | Сообщение об отсутствии соединения; повтор восстанавливает fixture | Точный текст offline показан. Счётчик task вырос с 4 до 5 на повторе; fixture восстановился | [16–17 desktop](screenshots/16-desktop-task-offline-error.png), [17](screenshots/17-desktop-task-offline-recovered.png); [08–09 mobile](screenshots/08-mobile-task-offline-error.png), [09](screenshots/09-mobile-task-offline-recovered.png) |
| 5 draft-error → good + «Повторить», обе ширины | Ошибка вместо частичной страницы; повторно загружается черновик | Ошибка показана. Счётчик draft вырос с 4 до 5 на повторе; fixture восстановился с тестовым черновиком | [18–19 desktop](screenshots/18-desktop-draft-error-error.png), [19](screenshots/19-desktop-draft-error-recovered.png); [10–11 mobile](screenshots/10-mobile-draft-error-error.png), [11](screenshots/11-mobile-draft-error-recovered.png) |

Кнопка «Повторить» нажималась координатным кликом. На кадрах при DPR 1 видимая цель примерно 120×44 px; точные runtime bounds из семантического дерева в исходном прогоне не сняты. Горизонтальный overflow программно отсутствовал на 360 и 1440 px. Все состояния и кадры выше повторно просмотрены. Секреты и ответы задач в журнал не включены.

## Адресные проверки после ревью

Штатный клик по Flutter «Enable accessibility» включил семантические узлы на mobile странице; замер показал bounds обычных контролов, но на ней уже не было виджета «Повторить». После reload режим доступности сбросился. Повторное нажатие для повторного включения не выполнялось. Поэтому точные runtime bounds «Повторить» на 360/1440 px не установлены.

Синтетический длинный файл в screenshot визуально ограничен десятью строками и знаком продолжения. Из-за недоступного на момент раскрытия файла семантического дерева программно не установлены длина первой preview-строки (ожидается 10 000 символов плюс маркер) и точное число строковых элементов.

Функциональные состояния прошли, однако эти два явных требования доказательствами не закрыты.

**Вердикт:** BLOCKED — точные bounds и программные пределы preview требуют семантического дерева в соответствующем состоянии.
