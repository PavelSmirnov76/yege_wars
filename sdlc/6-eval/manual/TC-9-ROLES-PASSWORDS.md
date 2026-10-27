# TC-9: Роли и пароли через API — успех и отказы

**Цель:** установить, что администратор меняет роль и пароль пользователя
через `admin_set_role` и `admin_reset_password`, а недопустимые вызовы база
отклоняет своими кодами.

**Пути UC:** [UC-8-P-01](../../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-01), [UC-8-P-02](../../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-02), [UC-8-P-03](../../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-03), [UC-8-P-04](../../2-specs/use-cases/UC-8-ACTOR-3-EVT-8-ENT-2-ROLE-CHANGED-IN-MANAGEMENT.md#uc-8-p-04), [UC-9-P-01](../../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-01), [UC-9-P-02](../../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-02), [UC-9-P-03](../../2-specs/use-cases/UC-9-ACTOR-3-EVT-9-ENT-1-PASSWORD-SET-IN-MANAGEMENT.md#uc-9-p-03).

**Приоритет:** средний — так владелец меняет пароли учеников.

## Предусловия

- API тестового проекта: `SUPABASE_URL` и `SUPABASE_ANON_KEY` из
  `supabase/.env.dev.local`; администратор `CONTENT_API_LOGIN` /
  `CONTENT_API_PASSWORD` оттуда же. Вход в API —
  `POST /auth/v1/token?grant_type=password` с почтой `<логин>@ege.local`;
  вызовы — `POST /rest/v1/rpc/<функция>` с токеном администратора.
- Подстановка — одноразовый логин `tc_mgmt_<ГГГГММДД>`; если занят — с
  буквой в конце. Нулевой id — `00000000-0000-0000-0000-000000000000`.
- Экрана нет: доказательство — ответы API в журнале, без токенов.

## Шаги

| № | Шаг и входные данные | Ожидаемый результат | Путь |
|---|---|---|---|
| 1 | Создать пользователя: `POST /auth/v1/signup`, почта `<логин>@ege.local`, пароль `password123`, `data.username` — логин; узнать его id | Учётная запись создана, в `profiles` роль `student` | — |
| 2 | `admin_set_role` с `{"p_user_id": "<id>", "p_role": "admin"}`, затем с `"student"` | Оба вызова успешны; после первого роль `admin`, после второго `student` | UC-8-P-01 |
| 3 | `admin_set_role` с id администратора и `"student"` | Ошибка «[self_demote] Нельзя снять роль администратора с самого себя.»; роль администратора — `admin` | UC-8-P-02 |
| 4 | `admin_set_role` с `{"p_user_id": "<id>", "p_role": "teacher"}` | Ошибка «[bad_role] Недопустимая роль. Разрешены: student, admin.» | UC-8-P-03 |
| 5 | `admin_set_role` с нулевым id и `"student"` | Ошибка «[user_not_found] Пользователь не найден.» | UC-8-P-04 |
| 6 | `admin_reset_password` с `{"p_user_id": "<id>", "p_new_password": "newpassword9"}`; вход в API пользователем с `newpassword9`, затем с `password123` | Вызов успешен; вход с новым паролем выдаёт сессию, со старым — отказ | UC-9-P-01 |
| 7 | `admin_reset_password` с `"short7"` | Ошибка «[weak_password] Пароль должен содержать не менее 8 символов.» | UC-9-P-02 |
| 8 | `admin_reset_password` с нулевым id и `"newpassword9"` | Ошибка «[user_not_found] Пользователь не найден.» | UC-9-P-03 |
