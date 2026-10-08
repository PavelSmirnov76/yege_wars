# ENT-13: Тема

**Модуль:** [MOD-7](../modules/MOD-7-REFERENCE.md). **Задача:** [ENT-6](ENT-6-PROBLEM-IN-CATALOG.md). **Статья темы:** [ENT-12](ENT-12-ARTICLE-IN-REFERENCE.md).

Таблицы `themes` — кодификатор — и `task_themes` — темы задачи.

| Поле | Тип | Правило |
|---|---|---|
| `themes.code` | text | код элемента кодификатора, например `3.13`, или служебный `none` |
| `themes.title` | text | формулировка элемента кодификатора |
| `task_themes.task_id` | uuid | задача; связь удаляется вместе с ней |
| `task_themes.theme_code` | text | тема задачи |
| `task_themes.sort_order` | smallint | порядок темы у задачи; `0` — основная |

- У задачи всегда есть тема: если к концу транзакции тем не осталось, база
  ставит `none`.
- Кодификатор читают все вошедшие; темы задачи видны вместе с задачей
  (политика `task_themes_select`); пишет только Content API.
- Представление `task_articles` соединяет темы задачи со статьями тем по
  `theme_code`; строки отбирают политики `task_themes` и
  `reference_articles`.
