# Content API: как создавать задачи и статьи

Документ для ИИ-агента и для человека, который его настраивает. Источник
истины по контенту — база Supabase; репозиторий хранит только резервные копии.

Писать в таблицы напрямую нельзя: задача — это запись в `tasks`, эталонный
ответ, файлы и связи со справочником, и всё это должно появляться одной
транзакцией. Поэтому запись идёт только через RPC-функции, перечисленные ниже.

## Доступ

Агент входит как обычный пользователь Supabase Auth с ролью `admin`
(сервисный аккаунт, например `ai_author`). **Service role key агенту не
выдаётся**: он обходит все права доступа. Сервисный аккаунт ограничен теми же
функциями, что и живой администратор, его действия видны в `audit_log`, а
пароль можно сменить одной командой.

Логин превращается в техническую почту `<логин>@ege.local` — это внутреннее
соглашение платформы, почта нигде не используется.

Переменные окружения (никогда не в коде):

```sh
export SUPABASE_URL="https://<ref>.supabase.co"
export SUPABASE_ANON_KEY="sb_publishable_…"   # публичный ключ
export CONTENT_API_LOGIN="ai_author"
export CONTENT_API_PASSWORD="…"
```

Получение токена:

```sh
curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$CONTENT_API_LOGIN@ege.local\",\"password\":\"$CONTENT_API_PASSWORD\"}"
```

В ответе `access_token` (живёт час) и `refresh_token`. Дальше каждый вызов:

```
apikey: <SUPABASE_ANON_KEY>
Authorization: Bearer <access_token>
Content-Type: application/json
```

Адрес любой функции: `POST $SUPABASE_URL/rest/v1/rpc/<имя_функции>`,
тело — JSON с её аргументами.

## Главное правило: ответ вычисляется, а не придумывается

Агент **обязан**:

1. написать `reference_solution` — программу на Python, которая читает файлы
   задачи и печатает ответ;
2. запустить её на тех самых файлах, которые уходят в `files`;
3. взять вывод программы и положить его в `answer`.

Придуманный «из головы» ответ — брак. Платформа это ловит: опубликовать задачу
можно только после того, как вывод эталона сверен с ответом
(`admin_verify_reference`), иначе `admin_set_task_status` вернёт `[not_verified]`.

## Функции

### `admin_upsert_task(payload jsonb) → jsonb`

Создаёт задачу или полностью обновляет существующую по `slug`. Файлы, темы
и связи со справочником **заменяются целиком**. Любой вызов снимает отметку проверки
эталона.

> **Задачам банка ФИПИ (`origin = 'fipi'`) этот вызов стирает вложения.**
> Файлы банка лежат в Storage: в `task_files` у них адрес (`storage_bucket`,
> `storage_path`) без `content`. `admin_upsert_task` принимает файлы только
> с `content` и удаляет все прежние строки `task_files`, поэтому ссылки на
> архивы и картинки задачи пропадут. Перезаписываются и все остальные поля.
> Ответ, формат и эталон задаче банка задаются через `admin_set_task_answer`.

```json
{
  "slug": "ege24-podstroka-abc-01",
  "ege_number": 24,
  "title": "Наибольшая длина подпоследовательности",
  "statement_md": "Текстовый файл состоит из символов A, B и C…",
  "difficulty": 2,
  "answer_format": "single",
  "answer": "1523",
  "reference_solution": "with open('24.txt') as f: …",
  "answer_explanation": "Скользящее окно, O(n)",
  "status": "review",
  "origin": "ai",
  "source": "собственная формулировка",
  "tags": ["strings", "sliding-window"],
  "themes": ["3.9"],
  "files": [{ "filename": "24.txt", "content": "ABCABC…" }],
  "references": [
    { "slug": "string-scan", "relevance": "primary" },
    { "slug": "file-reading", "relevance": "related" }
  ]
}
```

| Поле | Обязательно | Правило |
|---|---|---|
| `slug` | да | `^[a-z0-9-]{3,64}$`, уникален |
| `ege_number` | нет | 1–27; у части заданий банка ФИПИ номера нет |
| `ege_number_source` | нет | `fipi-spec-2026` или `manual` — откуда взят номер |
| `title` | да | непустой |
| `statement_md` | да | не короче 40 символов, markdown |
| `difficulty` | да | 1, 2 или 3 |
| `answer_format` | да | `single`, `pair`, `multi`, `string` |
| `answer` | при `status` ≠ `draft` | соответствует формату (см. ниже); присланный пустой — ошибка |
| `reference_solution` | при `status` ≠ `draft` | Python |
| `answer_explanation` | нет | короткий разбор для админа |
| `status` | нет (по умолчанию `draft`) | `draft` или `review`; `published` — только через `admin_set_task_status` |
| `origin` | нет (по умолчанию `human`) | `human`, `ai` или `fipi` — агент ставит `ai`, `fipi` — импорт банка |
| `tags` | нет | массив строк |
| `themes` | нет, но без него тема `none` | массив кодов КЭС строками, первый — основная тема |
| `files` | нет | `filename` `^[A-Za-z0-9_.-]{1,64}$` без путей, ≤ 4 МБ файл, ≤ 8 МБ на задачу |
| `references` | нет | `slug` существующей статьи, `relevance` = `primary`/`related` |

**Темы.** `themes` — коды КЭС из кодификатора (таблица `themes`), строками:
`"3.10"`, а не `3.10`. Число клиент может испортить ещё до отправки:
`json.dumps` в Python превращает `3.10` в `3.1`. Порядок сохраняется,
первая тема — основная. Неизвестный код — `[theme_not_found]`, и вызов
откатывается целиком. Не массив (строка, объект) — ошибка PostgreSQL без кода
в скобках.

Темы заменяются при каждом вызове: если `themes` не прислать или прислать
пустым, у задачи не останется тем, и база поставит служебную тему `none`.
Такая задача выпадает из навигации по темам. Поэтому при обновлении темы
присылаются всегда, даже если они не менялись.

Справку задача получает по темам: статья, у которой `theme_code` совпадает
с темой задачи, полагается ей автоматически (представление `task_articles`).
`references` нужны только для исключений — статьи, которой по теме не
полагается.

**Ответ.** Без ключа `answer` задача сохраняется только черновиком, а
прежний ответ задачи удаляется. Пустой или пробельный ответ — `[bad_answer]`.

Форматы ответа: `single` — одно целое число; `pair` — два числа через пробел;
`multi` — одно и более чисел через пробел; `string` — строка без переносов.
Сравнение нормализованное: лишние пробелы и ведущие нули значения не имеют.

Ответ функции:

```json
{ "task_id": "…", "slug": "…", "created": true, "status": "review",
  "themes": 1,
  "warnings": ["Не заполнен разбор ответа (answer_explanation)."] }
```

`themes` — сколько тем записано. `warnings` — не ошибка: задача сохранена,
но что-то стоит доделать. Например, «У задачи нет ни статьи по теме, ни связи
с relevance = primary.» — значит, по темам справки нет и `references` тоже
пусты.

### `admin_set_task_answer(payload jsonb) → jsonb`

Задаёт ответ, формат и эталон существующей задаче и не трогает остальное:
файлы (в том числе адреса в Storage), темы, связи со справочником, условие,
номер, теги. Годится для задачи любого `origin`; для задач банка ФИПИ это
единственный способ задать ответ, не стерев вложения.

```json
{
  "slug": "fipi-xxxxxx",
  "answer_format": "multi",
  "answer": "12 7 30 4",
  "reference_solution": "…",
  "answer_explanation": "…"
}
```

| Поле | Обязательно | Правило |
|---|---|---|
| `slug` | да | задача должна существовать |
| `answer_format` | да | `single`, `pair`, `multi`, `string` |
| `answer` | да | непустой, проходит нормализацию формата; `string` — в одну строку |
| `reference_solution` | да | непустой |
| `answer_explanation` | нет | нет ключа — разбор не меняется; `null` — стирается |

Что меняет вызов: `tasks.answer_format`, `reference_solution`,
`answer_explanation`, ответ в `task_answers`. Отметка сверки эталона
снимается — ответ нужно сверить заново (`admin_verify_reference`).
**Опубликованная задача уходит в `review`**: публиковать без сверки нельзя.
Черновик и `review` статус не меняют. Действие пишется в `audit_log` как
`set_answer` и считается в лимите записей.

Ответ функции:

```json
{ "slug": "fipi-xxxxxx", "status": "draft", "answer_format": "multi" }
```

Ошибки: `bad_payload` (не объект), `not_found` (нет задачи или `slug`),
`bad_answer_format`, `bad_answer`, `missing_reference_solution`. Сам ответ
в текст ошибки не попадает.

### `admin_upsert_article(payload jsonb) → jsonb`

Статья справочника, идемпотентно по `slug`.

```json
{
  "slug": "regex-basics",
  "title": "Регулярные выражения в Python",
  "summary": "Как описать шаблон текста и найти его модулем re.",
  "content_md": "…",
  "ege_numbers": [24],
  "tags": ["regex", "strings"],
  "level": 1,
  "reading_minutes": 7,
  "is_published": true
}
```

Требования: `slug` как у задачи, `title` и `summary` непустые, `content_md`
не короче 200 символов, `level` 1–3, `reading_minutes` > 0.

`theme_code` (необязательно) — код КЭС, который объясняет статья. По нему
статья становится справкой ко всем задачам этой темы. Одна тема — одна статья:
колонка уникальна, и занятая тема даёт ошибку уникальности PostgreSQL без кода
в скобках. Все 45 тем КЭС заняты статьями банка ФИПИ (`kes-1-1` … `kes-4-6`).
Неизвестный код — `[theme_not_found]`. Вызов заменяет статью целиком: если
`theme_code` не прислать, у существующей статьи тема снимется. Ответ функции
повторяет `theme_code`:

```json
{ "article_id": "…", "slug": "regex-basics", "theme_code": null, "created": true }
```

Статья **не решает** конкретную задачу и не содержит ответов — это правило
содержания, а не техническое ограничение.

### `admin_verify_reference(p_slug text, p_output text) → jsonb`

Сверяет вывод эталонного решения с сохранённым ответом. Совпало — ставится
отметка проверки, не совпало — снимается.

```json
{ "slug": "ege24-podstroka-abc-01", "matches": true }
```

### `admin_set_task_status(p_slug text, p_status text) → jsonb`

`draft` → `review` → `published`. Для `review` нужен эталон, для `published` —
ещё и успешная сверка.

### `admin_delete_task(p_slug text) → jsonb`

Удаляет задачу вместе с файлами, ответом и связями.

### `admin_list_tasks(filters jsonb) → jsonb`

Фильтры: `status`, `ege_number`, `origin`, `search`, `limit` (≤ 500),
`offset`. Возвращает `total`, `awaiting_review` и `items` с полями `slug`,
`title`, `ege_number`, `difficulty`, `status`, `origin`, `has_reference`,
`verified`, `files_count`, `articles_count`, `attempts`, `updated_at`.

### `admin_get_task(p_slug text) → jsonb`

Задача целиком: поля, эталон, ответ, файлы с содержимым, темы (`themes`:
`code`, `title`, `level`, основная первой), справка по темам (`articles`:
`slug`, `title`, `theme_code`) и ручные связи со справочником (`references`).

### `admin_check_slug_available(p_slug text) → jsonb`

`{ "slug": "…", "available": true }` — проверка перед созданием.

## Ошибки

Ошибка приходит как HTTP 4xx/5xx с телом PostgREST, где `message` начинается
с кода в квадратных скобках: `[код] Русский текст`. Код разбирает программа,
текст можно показывать человеку.

| Код | Когда |
|---|---|
| `not_authenticated` | нет или просрочен токен |
| `forbidden` | аккаунт без роли `admin` |
| `rate_limit` | больше 60 изменений контента в минуту |
| `bad_payload` | тело не объект JSON |
| `bad_slug` | slug не по шаблону |
| `bad_title`, `bad_summary` | пустой заголовок или описание |
| `short_statement`, `short_content` | слишком короткий текст |
| `bad_number`, `bad_ege_number`, `bad_difficulty` | числа вне диапазона |
| `bad_answer_format`, `bad_answer` | формат и ответ не согласуются |
| `bad_status`, `bad_origin`, `bad_relevance`, `bad_level`, `bad_number_source` | значение вне списка |
| `missing_reference_solution` | `review`/`published` без эталона |
| `not_verified` | публикация без сверки эталона |
| `bad_filename`, `file_too_large`, `files_too_large` | нарушены правила файлов |
| `article_not_found` | ссылка на несуществующую статью справочника |
| `theme_not_found` | кода нет в кодификаторе (`themes` задачи, `theme_code` статьи) |
| `not_found` | нет задачи с таким slug |

Любая ошибка откатывает весь вызов: полузадача в базе не остаётся.

## Примеры

curl:

```sh
TOKEN=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$CONTENT_API_LOGIN@ege.local\",\"password\":\"$CONTENT_API_PASSWORD\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/admin_upsert_task" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @task.json
```

Python (`requests`):

```python
import os, requests

url = os.environ["SUPABASE_URL"]
key = os.environ["SUPABASE_ANON_KEY"]

token = requests.post(
    f"{url}/auth/v1/token", params={"grant_type": "password"},
    headers={"apikey": key},
    json={"email": f"{os.environ['CONTENT_API_LOGIN']}@ege.local",
          "password": os.environ["CONTENT_API_PASSWORD"]},
    timeout=30,
).json()["access_token"]

response = requests.post(
    f"{url}/rest/v1/rpc/admin_upsert_task",
    headers={"apikey": key, "Authorization": f"Bearer {token}"},
    json={"payload": task},
    timeout=60,
)
response.raise_for_status()
```

Проще пользоваться готовой обёрткой `tools/content_client.py` (в Python —
класс `ContentClient`, у него метод на каждую функцию, например
`set_answer(payload)`):

```sh
python3 tools/content_client.py list --status review
python3 tools/content_client.py upsert-task task.json
python3 tools/content_client.py verify ege24-demo-01 --output-file out.txt
python3 tools/content_client.py publish ege24-demo-01
```

## Порядок работы агента

1. `admin_check_slug_available` — убедиться, что slug свободен.
2. Сгенерировать файлы данных и написать `reference_solution`.
3. **Запустить решение на этих файлах**, взять вывод как `answer`.
4. `admin_upsert_task` со `status: "review"` и `origin: "ai"`.
5. `admin_verify_reference` с тем же выводом — убедиться, что `matches: true`.
6. Остановиться. Публикует человек: задача ждёт его в разделе админки
   «Ждут проверки».

Автоматически публиковать созданное агентом нельзя.
