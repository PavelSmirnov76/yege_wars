# ACTOR-3: Администратор

**Кто:** пользователь с ролью `admin` — преподаватель.

**Цели:** управлять регистрацией, ролями и паролями.

**Права:** вызывает `admin_*` и меняет `app_settings`; видит раздел администратора. Снять роль администратора с себя не может.

**Сущности:** [ENT-4](../entities/ENT-4-SETTINGS-IN-MANAGEMENT.md), [ENT-2](../entities/ENT-2-PROFILE-IN-AUTH.md), [ENT-1](../entities/ENT-1-ACCOUNT-IN-AUTH.md). **События:** [EVT-7](../events/EVT-7-REGISTRATION-SWITCHED-IN-MANAGEMENT.md), [EVT-8](../events/EVT-8-ROLE-CHANGED-IN-MANAGEMENT.md), [EVT-9](../events/EVT-9-PASSWORD-RESET-IN-MANAGEMENT.md).
