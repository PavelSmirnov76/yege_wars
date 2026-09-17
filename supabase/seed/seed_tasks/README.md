# seed_tasks

Идемпотентный seed-скрипт банка задач ЕГЭ по информатике: читает банк из
каталога `tasks/`, валидирует его и загружает в PostgreSQL (локальный или
Supabase) в одной транзакции. Повторный запуск ничего не удаляет и не меняет
число строк — задачи и ответы обновляются upsert'ом по `slug` / `task_id`.

## Что делает

1. Сканирует `tasks/<ege_number>/<slug>/task.yaml`.
2. Валидирует банк:
   - `slug` совпадает с именем папки, `ege_number` — с папкой номера;
   - `difficulty` 1..3, `answer_format` — `single | pair | multi | string`;
   - `statement.md` существует и не пуст;
   - для каждого `slug` есть ответ в файле ответов;
   - `slug` уникален по всему банку.
3. Строит `files` — отсортированный список путей
   `task_files/<ege_number>/<slug>/<имя файла>` для всех файлов папки задачи,
   кроме `task.yaml`, `statement.md` и скрытых (`.DS_Store` и т.п.).
4. В одной транзакции: upsert в `public.tasks` по `slug` (все поля, включая
   `is_published = true`, если не указан `--unpublished`) и upsert ответа
   в `public.task_answers` по `task_id`.

## Файл ответов

JSON-объект `{"<slug>": "<ответ>", ...}`, по умолчанию —
`supabase/seed/local/answers.local.json`. Файл содержит ответы к задачам
и **не должен попадать в git**.

Если ответы лежат по одному на задачу в
`supabase/seed/local/answers/<slug>.json` (формат
`{"slug": "...", "answer": "..."}`), собрать общий файл можно так:

```sh
jq -s 'map({(.slug): .answer}) | add' \
  supabase/seed/local/answers/*.json \
  > supabase/seed/local/answers.local.json
```

## Строка подключения

Берётся **только** из переменной окружения `SEED_DATABASE_URL`
(формат `postgres://user:pass@host:port/db`). Без неё скрипт завершается
с кодом 2. Это секрет: не коммитьте её и не передавайте через аргументы
командной строки (они видны в истории шелла и списке процессов).

SSL: для `localhost` / `127.0.0.1` выключен, для остальных хостов —
обязателен; переопределяется query-параметром
`?sslmode=disable|prefer|require|verify-full`.

## Запуск

Из корня репозитория (пути по умолчанию рассчитаны на это):

```sh
# Только валидация и план, без подключения к БД
"$HOME/fvm/versions/3.41.0/bin/dart" run \
  supabase/seed/seed_tasks/bin/seed_tasks.dart --dry-run

# Локальный PostgreSQL
export SEED_DATABASE_URL='postgres://postgres:postgres@localhost:5432/yege'
"$HOME/fvm/versions/3.41.0/bin/dart" run \
  supabase/seed/seed_tasks/bin/seed_tasks.dart

# Supabase (Session pooler; строка — в Dashboard → Connect)
export SEED_DATABASE_URL='postgres://postgres.<project-ref>:<пароль>@aws-0-<регион>.pooler.supabase.com:5432/postgres'
"$HOME/fvm/versions/3.41.0/bin/dart" run \
  supabase/seed/seed_tasks/bin/seed_tasks.dart

# Загрузить как черновики (is_published = false)
"$HOME/fvm/versions/3.41.0/bin/dart" run \
  supabase/seed/seed_tasks/bin/seed_tasks.dart --unpublished
```

Параметры:

| Параметр        | По умолчанию                             | Назначение                         |
| --------------- | ---------------------------------------- | ---------------------------------- |
| `--tasks-dir`   | `tasks`                                  | Каталог банка задач                |
| `--answers`     | `supabase/seed/local/answers.local.json` | JSON-файл с ответами               |
| `--dry-run`     | —                                        | Валидация и план, без БД           |
| `--unpublished` | —                                        | Загрузить с `is_published = false` |

Коды выхода: `0` — успех, `1` — ошибки валидации или БД,
`2` — нет/некорректен `SEED_DATABASE_URL` либо ошибка в аргументах.

## Разработка

В каталоге пакета `supabase/seed/seed_tasks/`:

```sh
"$HOME/fvm/versions/3.41.0/bin/dart" pub get
"$HOME/fvm/versions/3.41.0/bin/dart" analyze
"$HOME/fvm/versions/3.41.0/bin/dart" test
```

Тесты не требуют БД: проверяются парсинг `task.yaml`, сканирование банка
во временных каталогах, построение `files`, файл ответов и разбор
строки подключения.
