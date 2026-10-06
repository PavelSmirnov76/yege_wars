# YEGE Wars — правила проекта

Платформа тренировки заданий КЕГЭ-2027 (Flutter Web + Supabase Free + Pyodide,
по духу Codewars). Работа идёт по этапам 1–10.

## Документы — читать перед работой

- `docs/SPEC.md` — полное ТЗ, источник истины по требованиям.
- `docs/STATE.md` — что сделано, контракты кода и БД, окружение, команды.
- `docs/PROMPT_CLOSE_IMPORT.md` — текущее задание: закрытие импорта банка ФИПИ.

## Процесс

- После каждого этапа: остановиться, короткий отчёт, спросить пользователя про
  git-коммит и продолжение. Коммитить только после подтверждения.
- На развилках — предложить варианты, решение за пользователем.

## Инструменты (важно: бинарников нет в PATH)

- Flutter: `~/fvm/versions/3.41.0/bin/flutter`, Dart:
  `~/fvm/versions/3.41.0/bin/dart` (fvm, версия в `.fvmrc`; `fvm use` не
  запускать — виснет на интерактиве).
- RLS-тесты БД: `bash supabase/tests/run_local.sh` (временный PostgreSQL 17
  из Homebrew, Docker не нужен). Полный список команд — в `docs/STATE.md`.

## Качество (обязательно)

- `flutter analyze --fatal-infos --fatal-warnings` и `dart run custom_lint` —
  0 замечаний (very_good_analysis; отключён только public_member_api_docs).
- `dart format` (80 колонок); кодоген (`*.g.dart`, `lib/l10n/gen/`) в git
  не коммитится, генерируется командами.
- Riverpod v3 только через `@riverpod` (кодогенерация). Тесты обязательны
  (юнит + виджет), существующие не ломать.
- Clean Architecture: domain без Flutter/Supabase; presentation не обращается
  к Supabase напрямую; ошибки — `Result<T>`/`Failure` с русскими сообщениями;
  UI-строки только через l10n (`lib/l10n/app_ru.arb`, `context.l10n`).
- Комментарии и dartdoc — на русском, идентификаторы — на английском.
- Никаких `print`, магических строк и «файлов-свалок».

## Секреты — никогда не коммитить

- `supabase/seed/local/` (ответы задач, эталонные решения) — только локально.
- Service role key, `SEED_DATABASE_URL`, пароли. `SUPABASE_URL`/`SUPABASE_ANON_KEY`
  передаются через `--dart-define` (anon key публичный — это нормально).

## База данных

- Любые изменения схемы — только новыми файлами миграций в
  `supabase/migrations/` (не редактировать применённые), после — прогнать
  `bash supabase/tests/run_local.sh` до `RLS OK`.
- Ошибки RPC имеют формат `[код] Русский текст` — клиент парсит код,
  текст показывает пользователю.
