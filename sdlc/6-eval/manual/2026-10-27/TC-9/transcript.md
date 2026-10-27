# TC-9 — прогон 2026-10-27

Кейс: `sdlc/6-eval/manual/TC-9-ROLES-PASSWORDS.md` — роли и пароли через API:
успех и отказы `admin_set_role` и `admin_reset_password`.

## Кто и где

- **Исполнитель:** агент — субагент-тестировщик Claude Code (модель Claude
  Opus 5.5), без браузера. Свой прогон не принимает.
- **Где:** API тестового проекта Supabase `yege_wars_dev`; коммит `main` —
  `c841a6ff12dbec7ea160eae81670336c26d6c8ba` (`git rev-parse HEAD`). Сборка и
  браузер не нужны: экранов у кейса нет, раздел «Вид экрана» не применяется,
  скриншотов нет.
- **Инструмент запросов:** скрипт Python 3.9.6 (`urllib`) из временной папки
  вне репозитория, один запуск, все шаги по порядку и каждый один раз,
  18:42:37Z–18:42:49Z. Перед каждым запросом скрипт проверял, что адрес
  содержит ref тестового проекта. Ключ, пароль администратора и токены не
  печатались и в журнал не попали: из ответов входа взяты только `user.id` и
  признак выданной сессии.
- **Заголовки:** `apikey: <SUPABASE_ANON_KEY>`, `Content-Type:
  application/json`; вызовы RPC и чтение `profiles` — с `Authorization: Bearer
  <токен администратора>`; регистрация и входы пользователя — без
  `Authorization`.

## Подстановки

| Что | Значение | Откуда |
|---|---|---|
| Доступы | только `supabase/.env.dev.local`: `YEGE_ENV=dev`, `SUPABASE_URL` содержит ref тестового проекта; `supabase/.env.local` не открывался | скрипт тестировщика |
| Адрес проекта | `<SUPABASE_URL>` | `supabase/.env.dev.local` |
| Администратор | `CONTENT_API_LOGIN` / `CONTENT_API_PASSWORD`, почта `<CONTENT_API_LOGIN>@ege.local` | `supabase/.env.dev.local`, кейс |
| `<id администратора>` | `4fee039d-05dc-48b9-be0b-a0ebbc46b1d0` | `user.id` из ответа входа администратора |
| Логин | `tc_mgmt_20261027` — свободен, буква не понадобилась | кейс; проверено запросом подготовки 3 |
| `<id>` созданного | `8f3a4f75-789e-4569-baf5-4ad7d68a97d6` | `user.id` из ответа регистрации (шаг 1) |
| Нулевой id | `00000000-0000-0000-0000-000000000000` | кейс |
| Пароли | `password123`, `newpassword9`, `short7` — тестовые значения кейса | кейс |

## Подготовка

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| п1 | `POST <SUPABASE_URL>/auth/v1/token?grant_type=password`, тело `{"email": "<CONTENT_API_LOGIN>@ege.local", "password": "<CONTENT_API_PASSWORD>"}` | 200 | сессия выдана; `user.id` = `4fee039d-05dc-48b9-be0b-a0ebbc46b1d0`; токены не печатались |
| п2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id администратора>` | 200 | `[{"role":"admin"}]` |
| п3 | `GET <SUPABASE_URL>/rest/v1/profiles?select=id&username=eq.tc_mgmt_20261027` | 200 | `[]` — логин свободен |

## Пошаговый журнал

### Шаг 1 — создать пользователя

**Ожидалось:** учётная запись создана, в `profiles` роль `student`.

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 1.1 | `POST <SUPABASE_URL>/auth/v1/signup`, тело `{"email": "tc_mgmt_20261027@ege.local", "password": "password123", "data": {"username": "tc_mgmt_20261027"}}` | 200 | сессия выдана; `user.id` = `8f3a4f75-789e-4569-baf5-4ad7d68a97d6`, `user.email` = `tc_mgmt_20261027@ege.local`, `user.user_metadata.username` = `tc_mgmt_20261027`; токены не печатались |
| 1.2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=id,username,role&id=eq.<id>` | 200 | `[{"id":"8f3a4f75-789e-4569-baf5-4ad7d68a97d6","username":"tc_mgmt_20261027","role":"student"}]` |

**Наблюдалось:** учётная запись создана, профиль с логином
`tc_mgmt_20261027` и ролью `student`.

**Совпало:** да.

### Шаг 2 — `admin_set_role`: `admin`, затем `student` (UC-8-P-01)

**Ожидалось:** оба вызова успешны; после первого роль `admin`, после второго
`student`.

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 2.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_set_role`, тело `{"p_user_id": "<id>", "p_role": "admin"}` | 204 | пусто |
| 2.2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id>` | 200 | `[{"role":"admin"}]` |
| 2.3 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_set_role`, тело `{"p_user_id": "<id>", "p_role": "student"}` | 204 | пусто |
| 2.4 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id>` | 200 | `[{"role":"student"}]` |

**Наблюдалось:** оба вызова — 204 без ошибки; роль после первого `admin`,
после второго `student`. Возвращать роль не понадобилось.

**Совпало:** да.

### Шаг 3 — `admin_set_role` с id администратора и `student` (UC-8-P-02)

**Ожидалось:** ошибка «[self_demote] Нельзя снять роль администратора с самого
себя.»; роль администратора — `admin`.

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 3.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_set_role`, тело `{"p_user_id": "4fee039d-05dc-48b9-be0b-a0ebbc46b1d0", "p_role": "student"}` | **400** | `{"code":"P0001","details":null,"hint":null,"message":"[self_demote] Нельзя снять роль администратора с самого себя."}` |
| 3.2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id администратора>` | 200 | `[{"role":"admin"}]` |

**Наблюдалось:** отказ; `message` дословно совпадает с текстом кейса; роль
администратора `admin`. Стоп-условие не сработало.

**Совпало:** да.

### Шаг 4 — `admin_set_role` с ролью `teacher` (UC-8-P-03)

**Ожидалось:** ошибка «[bad_role] Недопустимая роль. Разрешены: student,
admin.»

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 4.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_set_role`, тело `{"p_user_id": "<id>", "p_role": "teacher"}` | **400** | `{"code":"P0001","details":null,"hint":null,"message":"[bad_role] Недопустимая роль. Разрешены: student, admin."}` |
| 4.2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id>` — сверх кейса | 200 | `[{"role":"student"}]` |

**Наблюдалось:** отказ; `message` дословно совпадает с текстом кейса; роль
созданного пользователя осталась `student`.

**Совпало:** да.

### Шаг 5 — `admin_set_role` с нулевым id (UC-8-P-04)

**Ожидалось:** ошибка «[user_not_found] Пользователь не найден.»

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 5.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_set_role`, тело `{"p_user_id": "00000000-0000-0000-0000-000000000000", "p_role": "student"}` | **400** | `{"code":"P0001","details":null,"hint":null,"message":"[user_not_found] Пользователь не найден."}` |

**Наблюдалось:** отказ; `message` дословно совпадает с текстом кейса.

**Совпало:** да.

### Шаг 6 — `admin_reset_password` и входы (UC-9-P-01)

**Ожидалось:** вызов успешен; вход с новым паролем выдаёт сессию, со старым —
отказ.

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 6.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_reset_password`, тело `{"p_user_id": "<id>", "p_new_password": "newpassword9"}` | 204 | пусто |
| 6.2 | `POST <SUPABASE_URL>/auth/v1/token?grant_type=password`, тело `{"email": "tc_mgmt_20261027@ege.local", "password": "newpassword9"}` | 200 | сессия выдана; `user.id` = `8f3a4f75-789e-4569-baf5-4ad7d68a97d6`; токены не печатались |
| 6.3 | `POST <SUPABASE_URL>/auth/v1/token?grant_type=password`, тело `{"email": "tc_mgmt_20261027@ege.local", "password": "password123"}` | **400** | `{"code":400,"error_code":"invalid_credentials","msg":"Invalid login credentials"}` |

**Наблюдалось:** вызов — 204 без ошибки; вход с `newpassword9` выдал сессию
того же пользователя; вход с `password123` отклонён.

**Совпало:** да.

### Шаг 7 — `admin_reset_password` с `short7` (UC-9-P-02)

**Ожидалось:** ошибка «[weak_password] Пароль должен содержать не менее 8
символов.»

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 7.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_reset_password`, тело `{"p_user_id": "<id>", "p_new_password": "short7"}` | **400** | `{"code":"P0001","details":null,"hint":null,"message":"[weak_password] Пароль должен содержать не менее 8 символов."}` |

**Наблюдалось:** отказ; `message` дословно совпадает с текстом кейса.

**Совпало:** да.

### Шаг 8 — `admin_reset_password` с нулевым id (UC-9-P-03)

**Ожидалось:** ошибка «[user_not_found] Пользователь не найден.»

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| 8.1 | `POST <SUPABASE_URL>/rest/v1/rpc/admin_reset_password`, тело `{"p_user_id": "00000000-0000-0000-0000-000000000000", "p_new_password": "newpassword9"}` | **400** | `{"code":"P0001","details":null,"hint":null,"message":"[user_not_found] Пользователь не найден."}` |

**Наблюдалось:** отказ; `message` дословно совпадает с текстом кейса.

**Совпало:** да.

### После шагов — сверх кейса

| № | Запрос | Код | Тело ответа |
|---|---|---|---|
| к1 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id>` | 200 | `[{"role":"student"}]` |
| к2 | `GET <SUPABASE_URL>/rest/v1/profiles?select=role&id=eq.<id администратора>` | 200 | `[{"role":"admin"}]` |

Итог: созданный пользователь `tc_mgmt_20261027` — роль `student`, пароль
`newpassword9`; роль администратора — `admin`.

## Отступления от кейса

1. **Запросы сверх кейса — только чтение.** Роль администратора до шагов (п2),
   проверка, что логин свободен (п3), роль созданного после шага 4 (4.2) и
   итоговые роли (к1, к2) — `GET` к `profiles`, данных не меняют. На ожидания
   не влияют.
2. **Роль после вызовов шага 2 и шага 3 проверена чтением `profiles`
   администратором** — кейс не говорит, как узнать роль; политика
   `profiles_select` даёт чтение всем вошедшим. На ожидания не влияет.
3. **Входы создали сессии.** Вход администратора (п1) создал отдельную сессию
   его учётной записи; регистрация (1.1) и вход 6.2 — две сессии созданного
   пользователя. Сессии не отзывались, созданный пользователь не удалялся —
   кейс этого не требует. На ожидания не влияет.

**Вердикт:** PASS
