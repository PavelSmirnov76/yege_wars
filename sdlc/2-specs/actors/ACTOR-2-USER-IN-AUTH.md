# ACTOR-2: Пользователь

**Кто:** вошедший человек любой роли: ученик или администратор.

**Цели:** работать в приложении, видеть свой профиль, выйти.

**Права:** читает профили и настройки; раздел администратора и действия `admin_*` — только с ролью `admin`.

**Сущности:** [ENT-2](../entities/ENT-2-PROFILE-IN-AUTH.md), [ENT-3](../entities/ENT-3-SESSION-IN-AUTH.md). **События:** [EVT-3](../events/EVT-3-SIGNED-OUT-IN-AUTH.md), [EVT-4](../events/EVT-4-PROFILE-OPENED-IN-AUTH.md), [EVT-5](../events/EVT-5-ADMIN-SECTION-OPENED-IN-AUTH.md), [EVT-6](../events/EVT-6-ADMIN-ACTION-CALLED-IN-AUTH.md).
