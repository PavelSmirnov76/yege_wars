# Прогон TC-19 — 2026-11-09

**Исполнитель:** агент-тестировщик (Playwright Chromium)
**Worktree/ветка:** `/Users/pavelsmirnov/.codex/worktrees/task-12/yege_wars`, `task/TASK-12`
**Проверяемая сдача:** `b76ed93db9cdd723b13b2b027da09a7932bafcb3`
**Коммит работы:** `978b12347cece2a6d943a3acfd4c3e1de8da21da`
**Окружение:** локальная Flutter Web dev-сборка `yege_wars_dev`, собранная после synthetic-сборки и раздававшаяся сервером во время браузерного шага. URL и ключи в журнал не включались. Проверка остановлена до обращения к API.
**Браузер:** Playwright 1.64.1, Chromium 156.0.8078.4.

## Выполнено

| Шаг | Ожидание | Наблюдение |
|---|---|---|
| Подготовка | Локальная сборка доступна для браузера | Synthetic `flutter build web --release` завершилась кодом 0. После неё dev `flutter build web --release` по README завершилась кодом 0; значения `.env.dev.local` не выводились. |
| Запуск браузера | Отдельный Chromium открывает приложение на 1440×900 | Chromium открыл локальную сборку; драйвер записал Playwright/Chromium версии и viewport. |
| До входа | Отображается форма входа | Видны поля «Логин», «Пароль», кнопка «Войти», тестовый вход и регистрация. Кадр сохранён: [initial](screenshots/1794226795429-1440x900-initial.png). Безопасный JSON журнала: [tc19-1440x900-safe-log.json](screenshots/tc19-1440x900-safe-log.json). |

Наблюдаемых отказов кейса до остановки нет. Авторизация и шаги TC-19 A/B не выполнялись.

## Остановка

По указанию постановщика прогон прекращён после подтверждения отдельными адресными проверками двух регрессий на сдаче: профиль при возврате через прямой `router.go` оставляет старую сводку (счётчик вызовов остаётся 1), а ошибка `Future.wait` ожидает завершения второго pending-запроса. Эти проверки не выполнялись данным браузерным прогоном. Следующие шаги TC-19 не выполнены: вся часть A, вход в тестовый dev-аккаунт и вся часть B; viewport 360×800 не запускался. Полный прогон следует повторить после исправления.

Временная копия драйвера в `/tmp/tc19/tc19.cjs` отличалась только добавленным параметром remote-debugging-port; продукт и замороженный кейс не изменялись. В браузере использовались штатные сетевые подмены драйвера, до отправки данных не дошло. HTTP-сервер и Chromium закрыты.

## Команды и коды выхода

- `~/fvm/versions/3.41.0/bin/flutter build web --release --dart-define=SUPABASE_URL=https://tc19.invalid --dart-define=SUPABASE_ANON_KEY=tc19-anon-key` — 0.
- `set -a; . supabase/.env.dev.local; set +a; ~/fvm/versions/3.41.0/bin/flutter build web --release --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" --dart-define=TEST_LOGIN_USERNAME="$TEST_LOGIN_USERNAME" --dart-define=TEST_LOGIN_PASSWORD="$TEST_LOGIN_PASSWORD"` — 0; значения не печатались.
- `npm install --prefix /tmp/yege-tc19-runtime.fh6uqT --no-save --package-lock=false playwright@1.64.1 && /tmp/yege-tc19-runtime.fh6uqT/node_modules/.bin/playwright install chromium` — 0.
- `node /tmp/tc19/tc19.cjs` с `TC19_APP_URL=http://127.0.0.1:8080/#/profile`, `TC19_VIEWPORT=1440x900`, `TC19_PLAYWRIGHT_MODULE=/tmp/yege-tc19-runtime.fh6uqT/node_modules/playwright` и каталогом кадров выше — закрыт кодом 0 после `shot initial`, `report`, `quit`.
- Локальный `python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web` остановлен штатно (`Ctrl-C`, код 0).

Прогон остановлен постановщиком после подтверждённых им регрессий; шаги TC-19 A и B не выполнены. Дефекты подтверждены отдельными пробами, не этим браузерным наблюдением.

**Вердикт:** BLOCKED
