# FIG-9: Приложение не сконфигурировано

**Основание:** [UC-12](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md).

## Раскладка

По центру экрана — колонка ограниченной ширины: заголовок и под ним причина.
Навигации нет.

## Состояния

- [UC-12-P-02](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md#uc-12-p-02) — причина: нет параметров сборки.
- [UC-12-P-03](../2-specs/use-cases/UC-12-ACTOR-1-EVT-10-ENT-5-APP-STARTED-IN-CONFIG.md#uc-12-p-03) — причина: не удалось подключиться.

## Тексты

| Ключ l10n | Текст |
|---|---|
| `configMissingTitle` | Приложение не сконфигурировано |
| `configMissingBody` | Не заданы адрес и ключ Supabase. Соберите приложение с параметрами --dart-define=SUPABASE_URL=… и --dart-define=SUPABASE_ANON_KEY=… |

Причина из запуска показывается вместо `configMissingBody`, если она есть.
