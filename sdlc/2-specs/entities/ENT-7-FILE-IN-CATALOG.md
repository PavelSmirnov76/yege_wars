# ENT-7: Файл задачи

**Модуль:** [MOD-4](../modules/MOD-4-CATALOG.md). **Задача:** [ENT-6](ENT-6-PROBLEM-IN-CATALOG.md).

Таблица `task_files`.

| Поле | Тип | Правило |
|---|---|---|
| `task_id` | uuid | задача; файл удаляется вместе с ней |
| `filename` | text | только имя: `^[A-Za-z0-9_.-]{1,64}$`, без `..`; уникально в задаче |
| `content` | text | содержимое текстового файла, до 4 МБ; `null` — файл лежит в Storage |
| `storage_bucket`, `storage_path` | text | адрес файла в Supabase Storage — оба или ни одного |
| `size_bytes` | int | размер в байтах |
| `sort_order` | smallint | порядок показа |
| `kind` | text | `file` — файл задачи, `image` — картинка условия |

- Виден вместе со своей задачей (политика `task_files_select`); пишет только
  Content API.
- Клиент читает имя, содержимое и размер по `sort_order`. Файл из Storage
  клиент получает пустым.
