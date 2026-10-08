# YEGE Wars

Веб-платформа подготовки к ЕГЭ по информатике (КЕГЭ-2027) в духе
Codewars: тренировка заданий экзамена, решение задач на Python прямо
в браузере, прогресс и рейтинг на Supabase.

## Стек

- **Flutter Web** — клиент (single-page application);
- **Supabase Free** — аутентификация, база данных, хранение прогресса;
- **Pyodide** — исполнение пользовательского Python-кода в браузере;
- **GitHub Pages** — хостинг статической сборки.

## Архитектура

Clean Architecture + feature-first. Каждая фича делится на три слоя:

- **domain** — сущности и контракты репозиториев, чистый Dart без
  зависимостей от Flutter и внешних сервисов;
- **data** — реализации репозиториев, источники данных (Supabase),
  модели сериализации;
- **presentation** — виджеты, экраны и провайдеры состояния
  (Riverpod v3 с кодогенерацией).

Структура каталогов `lib/`:

```
lib/
├── app/                  # корень приложения: MaterialApp, роутер, тема
├── core/                 # общий код: константы, ошибки, утилиты, виджеты
└── features/
    └── <feature>/
        ├── domain/       # сущности, интерфейсы репозиториев
        ├── data/         # реализации, источники данных, модели
        └── presentation/ # экраны, виджеты, провайдеры
```

## Требования

- [fvm](https://fvm.app/) — менеджер версий Flutter;
- Flutter **3.41.0** — версия закреплена в `.fvmrc`;
- PostgreSQL 17 (например, из Homebrew) — для RLS-тестов базы: они поднимают
  временный сервер, Docker и Supabase CLI не нужны;
- Python 3.9 — для скриптов `tools/` и их тестов.

## Локальный запуск

Адреса проекта Supabase и публичного ключа в коде нет: приложение получает
их только параметрами сборки `--dart-define`. Локальные значения лежат в
`supabase/.env.local` — файл в `.gitignore`, в репозиторий он не попадает.

```sh
fvm use
set -a; . supabase/.env.local; set +a
flutter run -d chrome \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Без этих параметров приложение не падает, а показывает экран
«Приложение не сконфигурировано» с подсказкой.

## Команды разработки

```sh
# Генерация локализации (lib/l10n/gen/)
flutter gen-l10n

# Кодогенерация (Riverpod, *.g.dart)
dart run build_runner build --delete-conflicting-outputs

# Форматирование
dart format lib test

# Статический анализ
flutter analyze --fatal-infos --fatal-warnings

# Кастомные линты
dart run custom_lint

# Тесты
flutter test

# Проверка форматирования без изменений
find lib test -name '*.dart' -not -name '*.g.dart' -not -path 'lib/l10n/gen/*' \
  -print0 | xargs -0 dart format --output=none --set-exit-if-changed

# Миграции и RLS-тесты на временном PostgreSQL → RLS OK
bash supabase/tests/run_local.sh

# Миграции, импорт банка ФИПИ и его приёмка → IMPORT OK
bash supabase/tests/run_import_check.sh

# Тесты скриптов tools/
python3 -m unittest discover -s tools/tests -t .

# Конвейер sdlc/: пересборка индексов и проверка — перед каждым коммитом
python3 -m sdlc_tool views
python3 -m sdlc_tool check
```

Остальные команды скрипта конвейера (`next`, `entomb`, `snapshot-prd`, `run`) —
в `sdlc_tool/README.md`.

Команды контентных скриптов — в `tools/README.md`.

Генерённые файлы (`*.g.dart`, `lib/l10n/gen/`) в git не коммитятся —
перед анализом и запуском их нужно сгенерировать локально.

## Статус

Разработка идёт через SDLC-конвейер `sdlc/` (`sdlc/README.md`). Очередь работы
— `sdlc/1-business-tasks/planning/INDEX.md`, задания — `sdlc/4-tasks/INDEX.md`,
выполнение требований — `sdlc/6-eval/DASHBOARD.md`.

До конвейера сделаны этапы 1–6 ТЗ и доработки «контент в базе» и
«справочник». Их история — в `sdlc/0-vibes/raw/2026-10-08/` (`STATE.md`,
промты и отчёты).

## Добавление задач

Задачи и статьи справочника живут в базе, а не в репозитории. Создавать их
можно через Content API (`docs/content-api.md`) — этим пользуется ИИ-агент —
или в админке приложения. Папка `tasks/` остаётся резервной копией; перенести
её содержимое в базу можно командой `python3 tools/import_repo_tasks.py`.

## Деплой

Появится на соответствующем этапе.
