# ENT-16: Сайт

**Модуль:** [MOD-9](../modules/MOD-9-SITE.md). **Конфигурация сборки:** [ENT-5](ENT-5-BUILD-CONFIG-IN-CONFIG.md).

Сборка приложения, опубликованная на GitHub Pages.

| Что | Значение |
|---|---|
| адрес | `https://pavelsmirnov76.github.io/yege_wars/` |
| сборка | `flutter build web --release --base-href /yege_wars/` из текущего `main` |
| конфигурация сборки | `SUPABASE_URL` и `SUPABASE_ANON_KEY` из секретов GitHub — параметрами `--dart-define` |
| источник Pages | GitHub Actions |

- Адреса внутри приложения — с `#`: `…/yege_wars/#/task/<slug>`. Сервер всегда
  отдаёт одну страницу, поэтому отдельный `404.html` не нужен.
- Публичный ключ попадает в код сайта. Так и задумано: ключ публичный, данные
  защищает RLS.
- Новая версия появляется на сайте только после выкладки.
