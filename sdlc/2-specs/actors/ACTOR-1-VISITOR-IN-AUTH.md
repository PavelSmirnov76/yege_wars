# ACTOR-1: Посетитель

**Кто:** человек на сайте без входа.

**Цели:** зарегистрироваться или войти.

**Права:** видит только экраны входа и регистрации; из базы ему доступна только `is_registration_open()`.

**Сущности:** [ENT-1](../entities/ENT-1-ACCOUNT-IN-AUTH.md), [ENT-3](../entities/ENT-3-SESSION-IN-AUTH.md). **События:** [EVT-1](../events/EVT-1-REGISTERED-IN-AUTH.md), [EVT-2](../events/EVT-2-SIGNED-IN-IN-AUTH.md).
