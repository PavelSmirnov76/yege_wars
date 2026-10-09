# FIG-20: Задача

supersedes: [FIG-16](obsolete/FIG-16-PROBLEM.md)

**Основание:** [UC-15](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md), [UC-31](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md), [UC-32](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md), [UC-18](../2-specs/use-cases/UC-18-ACTOR-4-EVT-15-ENT-9-ANSWER-FILLED-IN-SUBMISSION.md), [UC-19](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md), [UC-33](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md), [UC-34](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md), [UC-35](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md), [UC-40](../2-specs/use-cases/UC-40-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md), [UC-28](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md).

## Раскладка

Заголовок — название задачи; пока задача загружается — «Каталог» и индикатор
по центру. Навигация — [COMP-4](design-system/COMP-4-NAVIGATION.md).

Условие — «Задание N» или «Без номера» и метка сложности; подсказка «Не
знаешь, с чего начать? Загляни в справку» цветом `AppColors.textSecondary` —
[TOKEN-7](design-system/TOKEN-7-COLOR.md#text-secondary), если у задачи есть
главная статья; текст условия — [COMP-16](design-system/COMP-16-MARKDOWN.md);
«Источник: …». Всё условие — одна область выделения: выделение идёт от
«Задание N» до источника через абзацы, таблицы и блоки кода.

Широкий экран — от `AppBreakpoints.tabletMax` — [TOKEN-5](design-system/TOKEN-5-BREAKPOINT.md#tablet-max):
вкладки «Задача», «Попытки», «Решения», «Справка», «Файлы». Во вкладке
«Задача» — две колонки через разделитель, левая шире правой, 3 : 2: слева
условие, справа раздел «Код» без «Моих попыток». Во вкладке «Попытки» — список
попыток; в остальных — содержимое одноимённого раздела.

Узкий экран: вкладки «Условие», «Код», «Решения», «Справка», «Файлы» с
прокруткой вбок; во вкладке — условие или содержимое одноимённого раздела.
Раздел «Код» здесь целиком, с «Моими попытками».

Раздел «Код»: поле кода, подсказка «Ctrl+Enter — запустить», сворачиваемый
«Ввод (stdin)», кнопки «Запустить» и «Стоп» — поровну делят строку, — строка
состояния с индикатором загрузки или выполнения, консоль. Под чертой — поле
«Ответ» с подсказкой формата и кнопкой «Взять из вывода» справа, кнопка
«Отправить ответ», вердикт, блок «Задача решена!», «Мои попытки» — список
попыток.

Раздел «Файлы»: карточка на файл — имя моноширинным шрифтом и размер; фон,
рамка и скругление `AppRadius.lg` — [TOKEN-4](design-system/TOKEN-4-RADIUS.md#lg) —
из темы карточек, отклик на нажатие не выходит за скругление; раскрытая
карточка — «Первые строки» на фоне кода, кнопки «Копировать» и «Скачать».

Раздел «Решения» — список чужих решений.

Раздел «Справка» — карточки статей [COMP-14](design-system/COMP-14-ARTICLE-CARD.md),
те же, что в справочнике; нажатие на карточку открывает статью в разделе
«Справочник».

## Состояния

- [UC-15-P-01](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-01) — условие и разделы, как в раскладке; у задачи без файлов в разделе «Файлы» — «У задачи нет файлов с данными»; после «Копировать» — сообщение внизу экрана «Файл скопирован в буфер обмена».
- [UC-15-P-02](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-02) — вместо страницы по центру — «Задача не найдена или ещё не открыта.» и «Повторить».
- [UC-15-P-03](../2-specs/use-cases/UC-15-ACTOR-4-EVT-12-ENT-6-PROBLEM-SHOWN-IN-CATALOG.md#uc-15-p-03) — вместо страницы по центру — сообщение об ошибке и «Повторить».
- [UC-31-P-01](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-01) — при открытии задачи в поле кода — черновик пользователя.
- [UC-31-P-02](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-02) — при открытии задачи поле кода пустое.
- [UC-31-P-03](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-03) — экран не меняется.
- [UC-31-P-04](../2-specs/use-cases/UC-31-ACTOR-4-EVT-23-ENT-15-DRAFT-SAVED-IN-CODE.md#uc-31-p-04) — вместо страницы по центру — сообщение об ошибке и «Повторить», как при сбое загрузки задачи.
- [UC-32-P-01](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-01) — весь запуск «Запустить» недоступна, «Стоп» доступна; пока среда загружается — «Загружаю Python — это разовая загрузка, потерпите» с индикатором, во время выполнения — «Выполняется…» с индикатором; затем «Готово за N с»; вывод — в консоли.
- [UC-32-P-02](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-02) — трассировка в консоли цветом ошибки; строка состояния — «Программа завершилась ошибкой».
- [UC-32-P-03](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-03) — строка состояния — «Остановлено».
- [UC-32-P-04](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-04) — сообщение в консоли цветом ошибки; строка состояния — «Не уложилось в отведённое время».
- [UC-32-P-05](../2-specs/use-cases/UC-32-ACTOR-4-EVT-14-ENT-9-RUN-FINISHED-IN-CODE.md#uc-32-p-05) — причина в консоли цветом ошибки.
- [UC-18-P-01](../2-specs/use-cases/UC-18-ACTOR-4-EVT-15-ENT-9-ANSWER-FILLED-IN-SUBMISSION.md#uc-18-p-01) — справа от поля ответа — кнопка «Взять из вывода», пока в выводе есть непустая строка; по нажатию ответ встаёт в поле.
- [UC-19-P-01](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-01) — вердикт «Верно!», под ним блок «Задача решена!»: пояснение «Опубликованное решение увидят те, кто решил задачу» и кнопки «Опубликовать решение» и «Не сейчас».
- [UC-19-P-02](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-02) — вердикт «Неверно. Попробуй ещё раз»; блока публикации нет.
- [UC-19-P-03](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-03) — под кнопкой цветом ошибки — «Введите ответ перед отправкой.»; вердикта нет.
- [UC-19-P-04](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-04) — под кнопкой цветом ошибки — «Слишком много отправок, подождите минуту.»; вердикта нет.
- [UC-19-P-05](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-05) — под кнопкой цветом ошибки — «Задача не найдена или недоступна.»; вердикта нет.
- [UC-19-P-06](../2-specs/use-cases/UC-19-ACTOR-4-EVT-16-ENT-11-ATTEMPT-CHECKED-IN-SUBMISSION.md#uc-19-p-06) — под кнопкой цветом ошибки — текст сбоя; вердикта нет.
- [UC-33-P-01](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-01) — блок «Задача решена!» скрыт, переключатель у попытки включён.
- [UC-33-P-02](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-02) — переключатель у попытки выключен.
- [UC-33-P-03](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-03) — блок «Задача решена!» скрыт.
- [UC-33-P-04](../2-specs/use-cases/UC-33-ACTOR-4-EVT-17-ENT-11-SOLUTION-PUBLISHED-IN-SUBMISSION.md#uc-33-p-04) — при сбое публикации из блока «Задача решена!» блок остаётся, под его кнопками цветом ошибки — текст ошибки; при сбое переключателя — сообщение внизу экрана с текстом ошибки, переключатель прежний.
- [UC-34-P-01](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-01) — в списке попыток — строка на попытку: значок вердикта цветом вердикта, ответ моноширинным шрифтом, время; у верной — переключатель с подсказкой «Опубликовано».
- [UC-34-P-02](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-02) — в списке попыток — «Попыток пока не было».
- [UC-34-P-03](../2-specs/use-cases/UC-34-ACTOR-4-EVT-12-ENT-11-ATTEMPTS-LISTED-IN-SUBMISSION.md#uc-34-p-03) — в списке попыток — [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с текстом ошибки.
- [UC-35-P-01](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-01) — на каждое решение — подпись «логин, ДД.ММ ЧЧ:ММ» и блок кода.
- [UC-35-P-02](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-02) — «Решения других откроются после твоего верного ответа».
- [UC-35-P-03](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-03) — «Пока никто не опубликовал своё решение».
- [UC-35-P-04](../2-specs/use-cases/UC-35-ACTOR-4-EVT-12-ENT-11-SOLUTIONS-SHOWN-IN-SUBMISSION.md#uc-35-p-04) — вместо списка — [COMP-12](design-system/COMP-12-ERROR-RETRY.md) с текстом ошибки.
- [UC-40-P-01](../2-specs/use-cases/UC-40-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md#uc-40-p-01) — в разделе «Справка» карточки статей, главные первыми, все одинаковые; нажатие на карточку открывает статью в разделе «Справочник»; над условием — подсказка, если есть главная статья.
- [UC-40-P-02](../2-specs/use-cases/UC-40-ACTOR-4-EVT-12-ENT-12-HELP-SHOWN-IN-REFERENCE.md#uc-40-p-02) — в разделе «Справка» — «К этой задаче пока нет статей справочника» цветом `AppColors.textSecondary` — [TOKEN-7](design-system/TOKEN-7-COLOR.md#text-secondary); подсказки над условием нет.
- [UC-28-P-01](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-01) — в условии название статьи ссылкой; нажатие открывает статью в разделе «Справочник».
- [UC-28-P-02](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-02) — в условии на месте ссылки на статью — slug обычным текстом.
- [UC-28-P-03](../2-specs/use-cases/UC-28-ACTOR-4-EVT-22-ENT-12-LINK-SHOWN-IN-REFERENCE.md#uc-28-p-03) — обычная ссылка в условии выглядит ссылкой; нажатие ничего не делает.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `taskTabProblem` | Задача |
| `taskTabAttempts` | Попытки |
| `taskStatementTitle` | Условие |
| `editorTitle` | Код |
| `solutionsTitle` | Решения |
| `taskHelpTitle` | Справка |
| `taskHelpHint` | Не знаешь, с чего начать? Загляни в справку |
| `taskHelpEmpty` | К этой задаче пока нет статей справочника |
| `referenceLevelBasic` | Базовый |
| `referenceLevelMedium` | Средний |
| `referenceLevelAdvanced` | Продвинутый |
| `referenceReadingMinutes` | {minutes} мин |
| `referenceEgeNumber` | № {number} |
| `taskFilesTitle` | Файлы |
| `navCatalog` | Каталог |
| `catalogEgeGroup` | Задание {number} |
| `catalogEgeGroupNone` | Без номера |
| `difficultyEasy` | Простая |
| `difficultyMedium` | Средняя |
| `difficultyHard` | Сложная |
| `taskSourceLabel` | Источник |
| `taskFilesEmpty` | У задачи нет файлов с данными |
| `unitBytes` | {value} Б |
| `unitKilobytes` | {value} КБ |
| `taskFilePreview` | Первые строки |
| `taskFileCopy` | Копировать |
| `taskFileCopied` | Файл скопирован в буфер обмена |
| `taskFileDownload` | Скачать |
| `editorCodePlaceholder` | # Твоё решение на Python |
| `editorRunHint` | Ctrl+Enter — запустить |
| `editorStdinTitle` | Ввод (stdin) |
| `editorStdinHint` | Данные, которые прочитает input() |
| `editorRun` | Запустить |
| `editorStop` | Стоп |
| `editorLoadingRuntime` | Загружаю Python — это разовая загрузка, потерпите |
| `editorRunning` | Выполняется… |
| `editorFinished` | Готово за {seconds} с |
| `editorFailed` | Программа завершилась ошибкой |
| `editorStopped` | Остановлено |
| `editorTimedOut` | Не уложилось в отведённое время |
| `editorConsoleEmpty` | Здесь появится вывод программы |
| `submitAnswerLabel` | Ответ |
| `submitHintSingle` | Одно число. Если в условии даны варианты — номер варианта |
| `submitHintPair` | Два числа через пробел |
| `submitHintMulti` | Числа через пробел. Таблицу — по строкам, слева направо |
| `submitHintString` | Точно как требует условие: регистр, запятые и пробелы важны |
| `submitTakeFromOutput` | Взять из вывода |
| `submitButton` | Отправить ответ |
| `submitSending` | Отправляю… |
| `submitCorrect` | Верно! |
| `submitWrong` | Неверно. Попробуй ещё раз |
| `submitSolvedTitle` | Задача решена! |
| `submitPublishedHint` | Опубликованное решение увидят те, кто решил задачу |
| `submitPublish` | Опубликовать решение |
| `submitNotNow` | Не сейчас |
| `attemptsTitle` | Мои попытки |
| `attemptsEmpty` | Попыток пока не было |
| `attemptPublishedSwitch` | Опубликовано |
| `solutionsLocked` | Решения других откроются после твоего верного ответа |
| `solutionsEmpty` | Пока никто не опубликовал своё решение |
| `solutionAuthor` | {author}, {date} |
| `commonRetry` | Повторить |
| `errorUnexpected` | Что-то пошло не так. Попробуйте ещё раз. |

`taskTabProblem` и `taskTabAttempts` — новые ключи. Подсказка под полем ответа
— одна из `submitHint…` по формату ответа задачи. Тексты ошибок отправки и
запуска приходят не из l10n: из базы, из среды Python и из обработки ошибок.
Чипы тегов на карточках справки подписаны самими тегами статей.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md), [COMP-6](design-system/COMP-6-DIFFICULTY-BADGE.md), [COMP-8](design-system/COMP-8-CODE-EDITOR.md), [COMP-9](design-system/COMP-9-CONSOLE.md), [COMP-10](design-system/COMP-10-VERDICT.md), [COMP-11](design-system/COMP-11-CODE-BLOCK.md), [COMP-12](design-system/COMP-12-ERROR-RETRY.md), [COMP-13](design-system/COMP-13-ARTICLE-META.md), [COMP-14](design-system/COMP-14-ARTICLE-CARD.md), [COMP-16](design-system/COMP-16-MARKDOWN.md).
