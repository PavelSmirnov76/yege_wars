# ENT-2: Профиль

**Модуль:** [MOD-1](../modules/MOD-1-AUTH.md). **Учётная запись:** [ENT-1](ENT-1-ACCOUNT-IN-AUTH.md).

Таблица `profiles`.

| Поле | Тип | Правило |
|---|---|---|
| `id` | uuid | ключ, ссылка на `auth.users.id` |
| `username` | text | уникален; `^[A-Za-z0-9_]{3,20}$`; хранится как введён |
| `role` | text | `student` или `admin`, по умолчанию `student` |
| `created_at` | timestamptz | дата регистрации |

- Строку создаёт только триггер `handle_new_user`; логин не по правилам —
  `[invalid_username]`, занят — `[username_taken]`.
- Читает любой вошедший (политика `profiles_select`); вставки, изменения и
  удаления через API нет. Роль меняет только `admin_set_role`.
- Администратор — тот, у кого `role = 'admin'`; проверка в базе — `is_admin()`.
