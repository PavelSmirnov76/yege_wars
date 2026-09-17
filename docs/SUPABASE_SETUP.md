# Подключение Supabase: пошагово

Инструкция для владельца проекта. На выходе — облачная база с нашей схемой,
к которой ходит приложение.

## Что такое Supabase (коротко)

Хостинг PostgreSQL с готовой аутентификацией и доступом к базе по HTTP.
Бесплатный тариф: 500 МБ базы, проект засыпает после недели без запросов
(будим его раз в три дня из GitHub Actions на этапе 9).

Схема, права доступа и функции описаны SQL-файлами в `supabase/migrations/`.
В панели Supabase таблицы руками **не создаём**: иначе локальная копия,
тесты и облако разойдутся.

## Шаг 1. Создать проект

1. [supabase.com](https://supabase.com) → **Start your project** → вход через
   GitHub или почту.
2. **New project**.
3. **Name**: `yege-wars`.
4. **Database Password**: нажать *Generate a password* и **сохранить пароль**
   (менеджер паролей или файл вне репозитория). Он понадобится для строки
   подключения; посмотреть его позже нельзя, только сбросить.
5. **Region**: `Central EU (Frankfurt)` — ближайший к России.
6. **Plan**: Free → **Create new project**. Проект поднимается 1–2 минуты.

## Шаг 2. Отключить подтверждение почты

Вход у нас по логину, почта техническая (`<логин>@ege.local`), писем мы не
отправляем — без этого шага регистрация будет ждать подтверждения навсегда.

1. Слева **Authentication** → **Sign In / Providers** → **Email**.
2. Выключить **Confirm email** → **Save**.

Прямая ссылка: `https://supabase.com/dashboard/project/_/auth/providers`.

## Шаг 3. Взять адрес проекта и публичный ключ

Кнопка **Connect** вверху страницы проекта (или **Settings → API Keys**):

- **Project URL** — вида `https://<ref>.supabase.co`;
- **Publishable key** — вида `sb_publishable_…`. В проектах постарше он
  называется **anon** и выглядит как длинный JWT (`eyJ…`). Годится любой из
  двух: это публичный ключ, его не прячут — доступ ограничивает RLS.

**Ключ `secret` / `service_role` не копировать и никому не передавать**: он
обходит все права доступа.

## Шаг 4. Взять строку подключения к базе

Та же кнопка **Connect** → вкладка **Session pooler** → строка вида:

```
postgresql://postgres.<ref>:[YOUR-PASSWORD]@aws-0-<region>.pooler.supabase.com:5432/postgres
```

Вместо `[YOUR-PASSWORD]` подставить пароль из шага 1.

## Шаг 5. Куда что положить

| Что | Куда | Почему |
|---|---|---|
| Project URL | в код (`lib/core/config/env.dart`) | публичный адрес |
| Publishable / anon key | в код | публичный ключ, защита — RLS |
| Строка подключения с паролем | `supabase/.env.local` (в `.gitignore`) | пароль базы, в git не попадает |
| `secret` / `service_role` | никуда | не нужен проекту |

Файл `supabase/.env.local`:

```sh
SEED_DATABASE_URL="postgresql://postgres.<ref>:<пароль>@aws-0-<region>.pooler.supabase.com:5432/postgres"
```

## Шаг 6. Применить миграции

Из корня репозитория:

```sh
source supabase/.env.local
for file in supabase/migrations/*.sql; do
  echo "== $file"
  psql "$SEED_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" || break
done
```

Порядок и полный список файлов — в `supabase/README.md`. Если `psql` нет,
можно вставить содержимое файлов в **SQL Editor** панели и выполнить по
одному, строго в порядке имён.

## Шаг 7. Задачи в базе

Банк задач из репозитория переносится в базу одной командой (эталоны при этом
прогоняются заново, и ответ берётся из вывода решения):

```sh
python3 tools/import_repo_tasks.py --dry-run   # проверка без записи
python3 tools/import_repo_tasks.py             # импорт
```

Дальше задачи создаются в админке или через Content API
(`docs/content-api.md`), а репозиторий остаётся резервной копией.

## Шаг 8. Первый администратор

Роль `admin` руками выдаётся один раз. Зарегистрируйтесь в приложении, затем
в **SQL Editor**:

```sql
update profiles set role = 'admin' where username = '<ваш логин>';
```

Дальше роли раздаются из админки.

## Если панель выглядит иначе

Интерфейс Supabase меняется несколько раз в год. Если пункта меню нет —
пришлите скриншот, сориентируемся по месту.
