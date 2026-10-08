# FIG-1: Вход

**Основание:** [UC-2](../2-specs/use-cases/UC-2-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md).

## Раскладка

Карточка формы по центру экрана, на любой ширине: заголовок, поля «Логин» и
«Пароль», кнопка «Войти», ссылка на регистрацию. На телефоне карточка — во
всю ширину с отступами по краям. Навигации нет: посетитель не вошёл.

## Состояния

- [UC-2-P-01](../2-specs/use-cases/UC-2-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-2-p-01) — форма заполнена верно: кнопка показывает отправку, затем
  открывается запомненный адрес или главная.
- [UC-2-P-02](../2-specs/use-cases/UC-2-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-2-p-02) — сообщение-ошибка над полями: «Неверный логин или пароль.».
- [UC-2-P-03](../2-specs/use-cases/UC-2-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-2-p-03) — ошибки под полями, запрос не отправлен.
- [UC-2-P-04](../2-specs/use-cases/UC-2-ACTOR-1-EVT-2-ENT-3-SESSION-STARTED-IN-AUTH.md#uc-2-p-04) — сообщение-ошибка над полями с текстом сбоя; при частых
  попытках — «Слишком много попыток. Подождите минуту и повторите.».

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

[COMP-1](design-system/COMP-1-AUTH-FORM-CARD.md), [COMP-2](design-system/COMP-2-AUTH-MESSAGE.md), [COMP-3](design-system/COMP-3-SUBMIT-BUTTON.md).
