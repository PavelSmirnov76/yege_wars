# TC-18 — прогон 2026-11-04

**Исполнитель:** тестировщик Luna, Chrome DevTools MCP.
**Сборка:** локальный `main`, commit `f09639a32f5a05294b88a0baa1d080b0f6e1a1d4`, release web, Supabase `yege_wars_dev`, `http://127.0.0.1:8080`.
**Окна:** desktop 1440×900; mobile 360×800, touch/mobile UA, `navigator.platform = Linux armv8l`.
**Граница:** синтетический fixture `tc-problem-page`; submit, drafts и остальные REST-записи перехвачены. Тест проверяет клиентскую реакцию на mock API, не сравнение ответов и не серверное сохранение. `blockedWrites=0`.

## Desktop — основной проход

| Шаг | Ожидалось | Наблюдалось | Доказательство |
|---|---|---|---|
| 1 | Поле ответа и пустой список попыток | Во вкладке «Попытки» показано «Попыток пока не было»; форма доступна во вкладке «Задача» | [01 пустые попытки](screenshots/01-desktop-empty-attempts.png), [02 форма](screenshots/02-desktop-form.png) |
| 2 | Пустое поле и только пробелы дают ошибку валидации; submit не вызывается | Оба действия показали «Введите ответ перед отправкой.»; `calls.submit=0`, attempts=0 | [03 пустой submit](screenshots/03-desktop-empty-submit.png), [04 пробелы](screenshots/04-desktop-whitespace.png) |
| 3 | `tc_wrong` нормализуется до маркера, создаёт одну неверную попытку | Первый синтетический submit дал `lastSubmit.p_answer=tc_wrong`, правильный task id и `# tc_ui_marker`; attempts=1, verdict неверный | [05 неверный результат](screenshots/05-desktop-wrong-result.png) |
| 3, ожидание RPC | «Отправляю…», кнопка недоступна | `wait_for` вернул ожидание текста, но кадр был снят уже после завершения 1,5 с и показывает неверный результат. Состояние disabled и кадр pending не подтверждены | отдельного кадра нет |
| 4, основной проход | `tc_correct` через Enter; вердикт и предложение публикации | Во время первой попытки очистки поля Control+A не выделил весь ответ: в одном из временных fixture был отправлен составной синтетический маркер. Это отступление тестового ввода, не баг продукта; fixture сброшен, зависимая цепочка wrong→correct пройдена заново. В повторе DOM input до Enter содержал точный `  tc_correct  `; hook подтвердил `tc_correct`, правильный task id/code и две attempts. Кадр правильного результата основного прохода не сохранён | Список двух attempts в [10](screenshots/10-desktop-attempts-two.png) |
| 5 | Четыре текста ошибки, попытки остаются прежними | Rate, missing, server error, offline появились по одному на каждую отправку; `calls.submit` последовательно 3, 4, 5, 6; attempts=2; blockedWrites=0 | [06 rate](screenshots/06-desktop-rate-error.png), [07 missing](screenshots/07-desktop-missing-error.png), [08 error](screenshots/08-desktop-error-error.png), [09 offline](screenshots/09-desktop-offline-error.png) |
| 6 | Ровно две строки, correct выше wrong; toggle выключен | UI совпал с `window.__taskCase.attempts`: `tc_correct` первая, `tc_wrong` вторая; локальное время и выключенный toggle видны | [10 две попытки](screenshots/10-desktop-attempts-two.png) |
| 7 | Ошибка списка, Retry обновляет запрос и показывает пустой список | В новой загрузке `attempts-error`: attempts calls=4; после реального клика Retry стало 5, список пустой | [11 ошибка](screenshots/11-desktop-attempts-error.png), [12 после повтора](screenshots/12-desktop-attempts-recovered.png) |

### Отдельное дополнение к шагу 4 после reset fixture

После завершения основного прохода и reset fixture выполнена одна отдельная проверка для «Не сейчас». Это отдельный fixture с одной правильной попыткой, не продолжение списка из шага 6. Один точный `tc_correct` через Enter показал «Верно!»; колесом прокручена Flutter-область к предложению «Задача решена!», затем выполнен реальный клик «Не сейчас». Кадр после клика сохраняет «Верно!» и показывает, что предложение исчезло. `calls.submit=1`, attempts=1, blockedWrites=0.

[13 правильный результат supplement](screenshots/13-desktop-correct-supplement.png), [14 предложение публикации](screenshots/14-desktop-correct-offer-supplement.png), [15 после «Не сейчас»](screenshots/15-desktop-not-now-supplement.png).

## Mobile — основной проход

| Шаг | Ожидалось | Наблюдалось | Доказательство |
|---|---|---|---|
| 1 | Форма и пустые попытки доступны во вкладке «Код» | Оба состояния показаны; список размещён ниже редактора | [16 форма и список](screenshots/16-mobile-code-form.png) |
| 2 | Пустое поле и пробелы отклоняются без submit | Оба действия показали ошибку валидации; `calls.submit=0`, attempts=0 | [17 пустой submit](screenshots/17-mobile-empty-submit.png), [18 пробелы](screenshots/18-mobile-whitespace.png) |
| 3 | Один неверный submit с `tc_wrong` | Ответ обрезан по краям до `tc_wrong`; `calls.submit=1`, одна неверная attempt, код и task id fixture совпали | [19 неверный результат](screenshots/19-mobile-wrong-result.png) |
| 3, ожидание RPC | «Отправляю…», кнопка недоступна | При задержке 1,5 с отдельный кадр pending не сохранён; проверены только итоговый результат и счётчики | отдельного кадра нет |
| 4 | `tc_correct` через Enter, предложение скрывается после «Не сейчас», verdict остаётся | `calls.submit=2`, correct первая и wrong вторая attempt. После прокрутки и клика «Не сейчас» предложение исчезло, «Верно!» осталось | [20 верный результат](screenshots/20-mobile-correct-result.png), [21 предложение](screenshots/21-mobile-correct-offer.png), [22 после клика](screenshots/22-mobile-not-now.png) |
| 5 | Четыре ошибки; форма доступна, attempts остаются двумя | Rate/missing/error/offline соответствуют текстам кейса; вызовы 3–6, attempts=2, blockedWrites=0 | [23 rate](screenshots/23-mobile-rate-error.png), [24 missing](screenshots/24-mobile-missing-error.png), [25 error](screenshots/25-mobile-error-error.png), [26 offline](screenshots/26-mobile-offline-error.png) |
| 6 | Две попытки в правильном порядке, верный toggle выключен | `tc_correct` выше `tc_wrong`; UI совпал с hook и показывает выключенный toggle | [27 две попытки](screenshots/27-mobile-two-attempts.png) |
| 7 | Сбой списка и восстановление пустого состояния | В свежей загрузке attempts-error: вызовов 4; после Retry стало 5, UI показывает «Попыток пока не было» | [28 ошибка](screenshots/28-mobile-attempts-error.png), [29 после повтора](screenshots/29-mobile-attempts-recovered.png) |

В ходе мобильного прогона диагностические файлы 28–30 сначала содержали stale rate-кадр; они были перезаписаны подтверждёнными missing/error/offline кадрами. В журнале используются только итоговые корректные файлы 24–26.

Тап-цели и доступность текста визуально проверены. После TC-18 одним штатным кликом включено Flutter accessibility; на mobile при 360×800 semantics bounds кнопки «Отправить ответ» составили x=16, y=596, w=328, h=48. Точные bounds для desktop, «Не сейчас» и «Повторить» не сняты. Временное состояние «Отправляю…» и недоступность кнопки не имеют сохранённого кадра на обеих ширинах. При следующей полной загрузке semantics сбросились; повторное включение не выполнялось.

**Вердикт:** BLOCKED — для шага 3 отсутствует доказательство pending/disabled состояния на двух ширинах; основной desktop правильный результат также не имеет сохранённого кадра. Функциональные реакции, ошибки, attempts и Retry прошли без обнаруженного продуктового FAIL.
