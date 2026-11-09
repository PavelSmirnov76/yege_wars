# FIG-23: Профиль с прогрессом

supersedes: [FIG-10](obsolete/FIG-10-PROFILE.md)

**Основание:** [UC-4](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md), [UC-13](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md), [UC-41](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md), [UC-42](../2-specs/use-cases/UC-42-ACTOR-2-EVT-26-ENT-18-PROBLEM-OPENED-IN-PROGRESS.md).

## Раскладка

Профиль — прокручиваемая страница под заголовком «Профиль». Сверху логин
и роль, ниже сводка решённых задач, прогресс по номерам и последние попытки.
Кнопка «Выйти» расположена после содержимого. Навигация приложения доступна
во всех состояниях.

До планшетного порога из [TOKEN-5](design-system/TOKEN-5-BREAKPOINT.md#tablet-max)
блоки идут в одну колонку. Выше порога — две равные колонки, слева сводка
и прогресс, справа попытки. Шапка профиля и выход занимают отдельные строки.
При проверке телефона используется мобильная навигация по
[COMP-4](design-system/COMP-4-NAVIGATION.md).

Поля страницы и промежутки блоков — `AppSpacing.xl`,
[TOKEN-3](design-system/TOKEN-3-SPACING.md#xl). Внутренние отступы блоков
определяются компонентами. Текст использует
[TOKEN-2](design-system/TOKEN-2-TYPOGRAPHY.md#text-theme), логин — `titleLarge`,
заголовки блоков — `titleMedium`, роль — `bodyMedium`.

## Состояния

- [UC-4-P-01](../2-specs/use-cases/UC-4-ACTOR-2-EVT-4-ENT-2-PROFILE-SHOWN-IN-AUTH.md#uc-4-p-01)
  показывает логин и русское имя роли.
- [UC-41-P-01](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md#uc-41-p-01)
  показывает [COMP-17](design-system/COMP-17-PROFILE-PROGRESS.md) и
  [COMP-18](design-system/COMP-18-RECENT-ATTEMPTS.md). При запросах показан
  индикатор загрузки в области данных, логин, роль и выход доступны.
- [UC-41-P-02](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md#uc-41-p-02)
  показывает нулевой прогресс и пустое состояние попыток.
- [UC-41-P-03](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md#uc-41-p-03)
  показывает общую сводку 0 из 0 и оба текста пустых состояний.
- [UC-41-P-04](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md#uc-41-p-04)
  заменяет область данных на [COMP-12](design-system/COMP-12-ERROR-RETRY.md)
  с сообщением ошибки и повтором.
- [UC-41-P-05](../2-specs/use-cases/UC-41-ACTOR-2-EVT-25-ENT-18-PROGRESS-SHOWN-IN-PROGRESS.md#uc-41-p-05)
  после повторной загрузки возвращает соответствующее состояние данных.
- [UC-42-P-01](../2-specs/use-cases/UC-42-ACTOR-2-EVT-26-ENT-18-PROBLEM-OPENED-IN-PROGRESS.md#uc-42-p-01)
  открывает выбранную задачу через штатный маршрут.
- [UC-13-P-01](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-01),
  [UC-13-P-02](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-02),
  [UC-13-P-03](../2-specs/use-cases/UC-13-ACTOR-2-EVT-3-ENT-3-SESSION-ENDED-IN-AUTH.md#uc-13-p-03)
  сохраняют переход при выходе/конце сессии и сообщение при отказе выхода.

## Тексты

- `navProfile` — «Профиль», `profileRoleLabel` — «Роль»,
  `profileRoleStudent` — «Ученик», `profileRoleAdmin` — «Администратор»,
  `profileSignOut` — «Выйти», `commonRetry` — «Повторить».
- `profileSolvedTitle` — «Решено задач».
- `profileSolvedSummary(solved, total)` — «{solved} из {total}».
- `profileProgressTitle` — «Прогресс по номерам КЕГЭ».
- `profileProgressCount(solved, total)` — «{solved} / {total}».
- `profileEgeNumber(number)` — «Задание {number}».
- `profileNoEgeNumber` — «Без номера КЕГЭ».
- `profileRecentAttemptsTitle` — «Последние попытки».
- `profileEmptyAttempts` — «Попыток пока нет».
- `profileEmptyTasks` — «Пока нет опубликованных задач».
- `profileAttemptCorrect` — «Верно», `profileAttemptWrong` — «Неверно».
- `profileProgressLoadError` — «Не удалось загрузить прогресс.».

При наличии русскоязычного сообщения Failure показывается оно. Общий текст
ошибки выше используется для технических ошибок без пригодного сообщения.

## Компоненты

[COMP-4](design-system/COMP-4-NAVIGATION.md),
[COMP-12](design-system/COMP-12-ERROR-RETRY.md),
[COMP-17](design-system/COMP-17-PROFILE-PROGRESS.md),
[COMP-18](design-system/COMP-18-RECENT-ATTEMPTS.md).
