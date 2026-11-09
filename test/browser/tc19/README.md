# Playwright-драйвер TC-19

`tc19.cjs` запускает отдельный Chromium и перехватывает запросы Supabase внутри браузера. UI действия тестировщик выполняет по шагам `sdlc/6-eval/manual/TC-19-PROFILE-PROGRESS.md`. Все учётные записи и данные синтетические; запросы авторизации/REST не уходят к Supabase. Не использовать этот драйвер для проверки части B с dev.

## Подготовка

Соберите локальный web build с синтетическим Supabase URL и ключом (драйвер перехватывает auth/REST запросы, они не доходят до этого URL):

```sh
FL=~/fvm/versions/3.41.0/bin/flutter
$FL build web --release \
  --dart-define=SUPABASE_URL=https://tc19.invalid \
  --dart-define=SUPABASE_ANON_KEY=tc19-anon-key
```

Затем поднимите сервер из корня репозитория:

```sh
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

В другом терминале установите зафиксированную версию Playwright во временный каталог и Chromium:

```sh
tc19_runtime=$(mktemp -d /tmp/yege-tc19-runtime.XXXXXX)
npm install --prefix "$tc19_runtime" --no-save --package-lock=false playwright@1.64.1
"$tc19_runtime/node_modules/.bin/playwright" install chromium
```

Запускать отдельный свежий процесс/context для каждой ширины:

```sh
TC19_APP_URL=http://127.0.0.1:8080/#/profile \
TC19_VIEWPORT=1440x900 \
TC19_SCREENSHOTS_DIR=/tmp/yege-tc19-captures \
NODE_PATH="$tc19_runtime/node_modules" \
node test/browser/tc19/tc19.cjs
```

Для мобильного запуска заменить `TC19_VIEWPORT` на `360x800`; новый запуск создаёт новый browser context. В форме входа использовать `tc19_a` или `tc19_b` и пароль `tc19-pass`. Драйвер не автоматизирует UI путь кейса, он подменяет API и ведёт журнал. По умолчанию кадры и JSON-отчёт сохраняются в `/tmp/yege-tc19-captures`; `TC19_SCREENSHOTS_DIR` задаёт другой каталог.

## Команды во время прогона

Команды вводятся в stdin процесса:

- `mode normal` — штатные ответы;
- `mode progress-error` / `mode attempts-error` — отказ только соответствующего запроса;
- `mode no-tasks` — пустой список задач и попыток;
- `mode delay-a` — задержать RPC и запрос попыток аккаунта A до команды `release progress`, `release attempts` или `release all`;
- `shot LABEL` — сохранить кадр текущей страницы;
- `report` — сохранить безопасный JSON-журнал;
- `quit` — закрыть Chromium и драйвер.

Для возврата после синтетической отправки драйвер отвечает верно на `tc19-synthetic` и добавляет попытку в изменяемое fixture-состояние до следующего запроса. Чтобы повторить сценарий с исходными данными, запустить новый процесс.

## Фикстура и ожидаемый порядок

`fixtures.json` задаёт фиксированные UUID и UTC timestamps. На аккаунте A должно быть 1/3 задач: T1 решена, T2 и T3 не решены; аккаунт B имеет 0/3. Скрытая попытка H и чужая попытка по T1 новее списка, но исключаются фильтрами. У T2/T3 равный timestamp; T3 идёт первым, так как его UUID больше. Исходные десять ожидаемых id вычисляются фильтрацией по автору и статусу задачи, затем сортировкой `created_at desc, id desc` и limit 10; драйвер включает их в `report`.

Журнал содержит только origin, endpoint, параметры запроса, id фикстур, режим и события. Заголовки, токены, пароль и содержимое запросов не записываются. Значения фильтров остаются видимы для сверки требований TC-19.
