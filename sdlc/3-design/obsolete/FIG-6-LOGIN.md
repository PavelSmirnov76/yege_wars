> **Похоронен:** 2026-10-09
> **Почему:** Экран входа получил кнопку «Тестовый вход» — проход 8, R48
> **Заменён:** [FIG-19](../FIG-19-LOGIN.md)

# FIG-6: Вход

supersedes: [FIG-1](FIG-1-LOGIN.md)

**Основание:** [UC-10](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md).

## Раскладка

Карточка формы по центру экрана, на любой ширине: заголовок, поля «Логин» и
«Пароль», кнопка «Войти», ссылка на регистрацию. На телефоне карточка — во
всю ширину с отступами по краям. Навигации нет: посетитель не вошёл.

## Состояния

- [UC-10-P-01](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-01) — форма заполнена верно: кнопка показывает отправку, затем
  открывается запомненный адрес или главная.
- [UC-10-P-02](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-02) — сообщение-ошибка над полями: «Неверный логин или пароль.».
- [UC-10-P-03](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-03) — ошибки под полями, запрос не отправлен.
- [UC-10-P-04](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-04) — сообщение-ошибка над полями с текстом сбоя; при частых
  попытках — «Слишком много попыток. Подождите минуту и повторите.».
- [UC-10-P-06](../../2-specs/use-cases/UC-10-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-10-p-06) — сообщение-ошибка над полями с причиной, например
  «Профиль пользователя не найден. Обратитесь к преподавателю.».

## Тексты

| Ключ l10n | Текст |
|---|---|
| `authLoginTitle` | Вход |
| `authUsernameLabel` | Логин |
| `authPasswordLabel` | Пароль |
| `authSignInButton` | Войти |
| `authNoAccountLink` | Нет аккаунта? Зарегистрируйтесь |
| `authUsernameInvalid` | Логин: 3–20 символов — латиница, цифры и подчёркивание |
| `authPasswordInvalid` | Пароль: не менее 8 символов |

Тексты ошибок запроса приходят не из l10n, а из обработки ошибок авторизации.

## Компоненты

[COMP-1](../design-system/COMP-1-AUTH-FORM-CARD.md), [COMP-2](../design-system/COMP-2-AUTH-MESSAGE.md), [COMP-3](../design-system/COMP-3-SUBMIT-BUTTON.md).
