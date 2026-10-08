# ENT-14: Ручная связь

**Модуль:** [MOD-7](../modules/MOD-7-REFERENCE.md). **Задача:** [ENT-6](ENT-6-PROBLEM-IN-CATALOG.md). **Статья:** [ENT-12](ENT-12-ARTICLE-IN-REFERENCE.md).

Таблица `task_references`.

| Поле | Тип | Правило |
|---|---|---|
| `task_id` | uuid | задача; связь удаляется вместе с ней |
| `article_id` | uuid | статья; связь удаляется вместе с ней |
| `relevance` | text | `primary` — главная, `related` — сопутствующая |
| `sort_order` | smallint | порядок связи |

- Пара «задача — статья» уникальна.
- Видна, если видны и задача, и статья (политика `task_references_select`);
  пишет только Content API.
