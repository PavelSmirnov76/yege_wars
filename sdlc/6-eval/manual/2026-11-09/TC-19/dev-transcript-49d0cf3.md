# TC-19, часть B — реальное чтение dev

**Вердикт:** PASS

HEAD: `49d0cf355f400d7f3bb0a8afa0e4565659d93a82`; исправления: `3a9047c`.
Окружение: dev-проект из `supabase/.env.dev.local`; сборка и сервер изолированы в `/tmp`; рабочий сервер — только `127.0.0.1:8082`.
Браузер: Playwright 1.64.1, Chromium 156.0.8078.4; 1440×900 desktop context и 360×800 Pixel 5 mobile context.
Аккаунт: тестовый ученик `TEST_LOGIN_USERNAME`; в UI подтверждены имя текущей тестовой учётной записи и роль «Ученик». Пароль, user id и токены не записывались.

На обеих ширинах выполнены настоящие чтения `get_user_progress` и `submissions`: HTTP 200. UI совпал с ответом: суммарно 0 из 140, 21 строка прогресса и пустая история попыток. Подробные безопасные числовые суммы и UI сравнения находятся в JSON.
Запрос RPC передавал authenticated user id. Запрос submissions проверен по user_id, published status, inner join, created_at/id descending, limit 10 и разрешённому набору полей. Все признаки совпали с ENT-18.
На каждой ширине запросы повторились при возврате в профиль: по два вызова каждого запроса. История пуста, поэтому переход к реальной попытке пропущен. Для проверки возврата открыта опубликованная задача, затем выполнен browser back в профиль; обе повторные загрузки подтверждены.
Flutter semantics включались клавишей Enter на штатном accessibility placeholder. В mobile UA placeholder 1×1 находится за границей viewport, поэтому использован доступный `Enable accessibility` button с фокусом и настоящим Enter; mobile UI проверен при viewport 360×800.
Скриншоты с реальными данными не сохранялись. В JSON нет тел API, UUID, slug, названий задач, ответов, auth payload, ключей, токенов или заголовков.
Попытки не отправлялись, данные dev не менялись. API отказов не было.

Сборка: `flutter build web --release --output /tmp/task12-tc19-dev-build --dart-define-from-file=/tmp/task12-acceptance-probes/dev-defines.json` — exit 0.
Сервер: `python3 -m http.server 8082 --bind 127.0.0.1 --directory /tmp/task12-tc19-dev-build`.
Runner: `node /tmp/task12-acceptance-probes/dev-b.cjs --mobile-only` для завершающего mobile шага; desktop прогон выполнен тем же runner до mobile.

Безопасные параметры запросов, статусы, суммы, количества и булевы UI сверки: `dev-result-49d0cf3.json`.

Примечание о кодах завершения: итоговый процесс runner напечатал `OVERALL=FAIL` и завершился с кодом 1 из-за опечатки в агрегаторе: сборщик записал `attemptOrderMatchesCreatedAtDescIdDesc`, а итоговая проверка читала `attemptOrderMatchesCreatedAtDescIdDescending`. Первичные UI/API проверки обеих ширин сохранены в JSON. Независимый валидатор `/tmp/task12-acceptance-probes/validate-dev-result.py` проверил именно сохранённые поля без браузера и завершился кодом 0; полный безопасный вывод — `/tmp/task12-acceptance-probes/validate-dev-result.log`. С учётом пустой истории порядок строк неприменим, параметр сортировки запроса отдельно подтверждён.
