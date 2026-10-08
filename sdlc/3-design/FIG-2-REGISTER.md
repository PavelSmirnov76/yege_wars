# FIG-2: Регистрация

**Основание:** [UC-1](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md).

## Раскладка

Как у входа: карточка формы по центру — заголовок, сообщение (если есть), поля
«Логин» и «Пароль», кнопка «Зарегистрироваться», ссылка на вход.

## Состояния

- [UC-1-P-01](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-01) — форма заполнена верно: кнопка показывает отправку, затем
  открывается запомненный адрес или главная.
- [UC-1-P-02](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-02) — ошибки под полями, запрос не отправлен.
- [UC-1-P-03](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-03) — сообщение-ошибка над полями с текстом из базы: «Логин «…» уже
  занят, выберите другой.».
- [UC-1-P-04](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-04) — сообщение-предупреждение «Регистрация закрыта
  администратором», поля и кнопка недоступны.
- [UC-1-P-05](../2-specs/use-cases/UC-1-ACTOR-1-EVT-1-ENT-1-STUDENT-CREATED-IN-AUTH.md#uc-1-p-05) — сообщение-ошибка «Не удалось проверить, открыта ли
  регистрация» или текст сбоя запроса.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `authRegisterTitle` | Регистрация |
| `authUsernameLabel` | Логин |
| `authPasswordLabel` | Пароль |
| `authSignUpButton` | Зарегистрироваться |
| `authHaveAccountLink` | Уже есть аккаунт? Войдите |
| `authRegistrationClosed` | Регистрация закрыта администратором |
| `authRegistrationCheckFailed` | Не удалось проверить, открыта ли регистрация |
| `authUsernameInvalid` | Логин: 3–20 символов — латиница, цифры и подчёркивание |
| `authPasswordInvalid` | Пароль: не менее 8 символов |

## Компоненты

[COMP-1](design-system/COMP-1-AUTH-FORM-CARD.md), [COMP-2](design-system/COMP-2-AUTH-MESSAGE.md), [COMP-3](design-system/COMP-3-SUBMIT-BUTTON.md).
