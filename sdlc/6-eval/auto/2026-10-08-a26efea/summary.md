# Прогон 2026-10-08-a26efea

- Коммит: `a26efea5e16bdd87a40de501885446f7bb843a3b`
- Дата: 2026-10-08; начат 2026-10-08T20:00:10+00:00, закончен 2026-10-08T20:01:09+00:00
- Незакоммиченные изменения: нет
- Итог: PASS (код 0)
- Тесты: PASS 357, FAIL 0, BLOCKED 0

## Проверки

| Проверка | Команда | Вердикт | Код | Причина |
|---|---|---|---|---|
| pub_get | `flutter pub get` | PASS | 0 | — |
| gen_l10n | `flutter gen-l10n` | PASS | 0 | — |
| build_runner | `dart run build_runner build --delete-conflicting-outputs` | PASS | 0 | — |
| analyze | `flutter analyze --fatal-infos --fatal-warnings` | PASS | 0 | — |
| custom_lint | `dart run custom_lint` | PASS | 0 | — |
| format | `dart format --output=none --set-exit-if-changed <.dart из lib/ и test/ без *.g.dart и lib/l10n/gen/>` | PASS | 0 | — |
| flutter_test | `flutter test --reporter json` | PASS | 0 | — |
| rls | `bash supabase/tests/run_local.sh` | PASS | 0 | — |
| tools_tests | `python3 -m unittest discover -s tools/tests -t .` | PASS | 0 | — |
| sdlc_tool_tests | `python3 -m unittest discover -s sdlc_tool/tests -t .` | PASS | 0 | — |

## Пути UC

| Путь UC | Тест | Вердикт |
|---|---|---|
| UC-1-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-1-P-01: адрес переживает перезагрузку страницы регистрации | PASS |
| UC-1-P-01 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-01: адрес переходит со входа на регистрацию и открывается после регистрации | PASS |
| UC-1-P-01 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-01: успешная регистрация ведёт в каталог | PASS |
| UC-1-P-02 | `supabase/tests/rls_tests.sql` — UC-1-P-02: короче 3 символов | PASS |
| UC-1-P-02 | `supabase/tests/rls_tests.sql` — UC-1-P-02: недопустимые символы | PASS |
| UC-1-P-02 | `test/features/auth/domain/use_cases_test.dart` — SignUpUseCase UC-1-P-02: проверяет ввод до обращения к репозиторию | PASS |
| UC-1-P-02 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-02: не отправляет форму с некорректным вводом | PASS |
| UC-1-P-03 | `supabase/tests/rls_tests.sql` — UC-1-P-03: занятый логин с другой почтой — [username_taken] из триггера | PASS |
| UC-1-P-03 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-03: ошибка регистрации показывается на экране | PASS |
| UC-1-P-04 | `supabase/tests/rls_tests.sql` — UC-1-P-04: закрытая регистрация — [registration_closed] | PASS |
| UC-1-P-04 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-04: при закрытой регистрации форма заблокирована | PASS |
| UC-1-P-05 | `test/features/auth/presentation/register_screen_test.dart` — UC-1-P-05: ошибка проверки регистрации показывается | PASS |
| UC-4-P-01 | `test/features/profile/profile_screen_test.dart` — UC-4-P-01: показывает логин и роль | PASS |
| UC-4-P-01 | `test/features/profile/profile_screen_test.dart` — UC-4-P-01: показывает роль администратора | PASS |
| UC-5-P-01 | `test/app/router/app_router_test.dart` — UC-5-P-01: админ открывает админку и видит пункт меню | PASS |
| UC-5-P-02 | `test/app/router/app_router_test.dart` — UC-5-P-02: ученика не пускает в админку и прячет пункт меню | PASS |
| UC-5-P-02 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01, UC-5-P-02: ученик с адресом админки после входа попадает в каталог | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: admin_get_task под учеником | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: admin_reset_password под студентом — [forbidden] | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: admin_set_role под учеником — [forbidden] | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: admin_set_task_answer под учеником — [forbidden] | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: admin_upsert_article под студентом | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: админские RPC под студентом | PASS |
| UC-6-P-01 | `supabase/tests/rls_tests.sql` — UC-6-P-01: под студентом — [forbidden] | PASS |
| UC-7-P-01 | `supabase/tests/rls_tests.sql` — UC-7-P-01: администратор закрывает и открывает регистрацию, is_registration_open() и триггер следуют флагу | PASS |
| UC-7-P-02 | `supabase/tests/rls_tests.sql` — UC-7-P-02: ученик меняет registration_open — без ошибки, 0 строк, значение прежнее | PASS |
| UC-8-P-01 | `supabase/tests/rls_tests.sql` — UC-8-P-01: администратор назначает и снимает роль администратора | PASS |
| UC-8-P-02 | `supabase/tests/rls_tests.sql` — UC-8-P-02: снять роль администратора с себя — [self_demote] | PASS |
| UC-8-P-03 | `supabase/tests/rls_tests.sql` — UC-8-P-03: недопустимая роль — [bad_role] | PASS |
| UC-8-P-04 | `supabase/tests/rls_tests.sql` — UC-8-P-04: роль несуществующему пользователю — [user_not_found] | PASS |
| UC-9-P-01 | `supabase/tests/rls_tests.sql` — UC-9-P-01: новым паролем можно войти — хэш bcrypt сходится с ним и не сходится с другим | PASS |
| UC-9-P-01 | `supabase/tests/rls_tests.sql` — UC-9-P-01: нормальный пароль — проходит | PASS |
| UC-9-P-01 | `supabase/tests/rls_tests.sql` — UC-9-P-01: хэш действительно изменился | PASS |
| UC-9-P-02 | `supabase/tests/rls_tests.sql` — UC-9-P-02: короткий пароль — [weak_password] | PASS |
| UC-9-P-03 | `supabase/tests/rls_tests.sql` — UC-9-P-03: пароль несуществующему пользователю — [user_not_found] | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — UC-10-P-01: без авторизации любой путь ведёт на вход | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01, UC-5-P-02: ученик с адресом админки после входа попадает в каталог | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: адрес переживает перезагрузку страницы входа | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: адрес, открытый без входа, открывается после входа | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: адрес, открытый до проверки сессии, когда сессии нет, открывается после входа | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: без входа на главной вход получает её адрес | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: негодные адреса после входа ведут на главную | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после входа UC-10-P-01: путь с параметрами запроса сохраняется целиком | PASS |
| UC-10-P-01 | `test/app/router/app_router_test.dart` — адрес после конца сессии UC-10-P-01: после конца сессии адрес, открытый заново без входа, запоминается | PASS |
| UC-10-P-01 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-01: успешный вход ведёт в каталог | PASS |
| UC-10-P-01 | `test/features/auth/presentation/register_screen_test.dart` — UC-10-P-01: ссылка с регистрации на вход сохраняет адрес | PASS |
| UC-10-P-02 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-10-P-02: неуспешный вход не меняет состояние | PASS |
| UC-10-P-02 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-02: показывает ошибку сервера | PASS |
| UC-10-P-03 | `test/features/auth/domain/use_cases_test.dart` — SignInUseCase UC-10-P-03: не идёт в репозиторий при коротком пароле | PASS |
| UC-10-P-03 | `test/features/auth/domain/use_cases_test.dart` — SignInUseCase UC-10-P-03: не идёт в репозиторий при неверном логине | PASS |
| UC-10-P-03 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-03: не отправляет форму с некорректным вводом | PASS |
| UC-10-P-04 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-04: сбой связи показывается сообщением | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05, UC-13-P-03: после входа открывается каталог, после выхода — вход | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05: адрес, открытый до проверки сессии, восстанавливается | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05: вошедшего с /login и /register уводит на главную | PASS |
| UC-10-P-05 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-10-P-05: восстановленная сессия загружает профиль | PASS |
| UC-10-P-06 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-10-P-06: ошибка чтения профиля оставляет пользователя снаружи | PASS |
| UC-10-P-06 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-06: показывает ошибку восстановления сессии | PASS |
| UC-12-P-01 | `test/app/bootstrap_test.dart` — UC-12-P-01: с адресом и ключом bootstrap поднимает Supabase | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без параметров сборки адреса и ключа проекта нет | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: заглушка объясняет, чего не хватает | PASS |
| UC-12-P-02 | `test/main_test.dart` — UC-12-P-02: без параметров сборки приложение показывает экран «не сконфигурировано» с причиной | PASS |
| UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: Supabase не поднялся — bootstrap возвращает ошибку подключения | PASS |
| UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: заглушка показывает переданные подробности | PASS |
| UC-13-P-01 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-13-P-01: выход возвращает в unauthenticated | PASS |
| UC-13-P-01 | `test/features/profile/profile_screen_test.dart` — UC-13-P-01: кнопка «Выйти» возвращает на экран входа | PASS |
| UC-13-P-01 | `test/features/profile/profile_screen_test.dart` — UC-13-P-01: после «Выйти» адрес профиля не запоминается — следующий вход открывает главную | PASS |
| UC-13-P-02 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-13-P-02: ошибка выхода сохраняет вход | PASS |
| UC-13-P-02 | `test/features/profile/profile_screen_test.dart` — UC-13-P-02: ошибка выхода показывается сообщением | PASS |
| UC-13-P-03 | `test/app/router/app_router_test.dart` — UC-10-P-05, UC-13-P-03: после входа открывается каталог, после выхода — вход | PASS |
| UC-13-P-03 | `test/app/router/app_router_test.dart` — адрес после конца сессии UC-13-P-03: сессия закончилась на открытой странице — адрес не запоминается, следующий вход открывает главную | PASS |
| UC-13-P-03 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-13-P-03: выход из аккаунта в другой вкладке сбрасывает состояние | PASS |
| UC-14-P-01 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: tasks_public отдаёт опубликованную задачу и не отдаёт черновик | PASS |
| UC-14-P-01 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: студенту видны только опубликованные задачи, неопубликованная — нет | PASS |
| UC-14-P-01 | `supabase/tests/rls_tests.sql` — UC-14-P-01: доля решивших в каталоге считается только по ученикам | PASS |
| UC-14-P-01 | `test/features/tasks/data/supabase_tasks_remote_data_source_test.dart` — UC-14-P-01: каталог идёт по номеру, затем по названию — по возрастанию | PASS |
| UC-14-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — listCatalog UC-14-P-01: задача без моих попыток — не начата | PASS |
| UC-14-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — listCatalog UC-14-P-01: собирает карточки, прогресс и статистику | PASS |
| UC-14-P-01 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-01: задача без номера КИМ попадает в группу «Без номера» | PASS |
| UC-14-P-01 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-01: нажатие на карточку открывает задачу | PASS |
| UC-14-P-01 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-01: показывает задачи с группировкой по номеру | PASS |
| UC-14-P-01 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-01: показывает статус и статистику | PASS |
| UC-14-P-02 | `test/features/tasks/data/supabase_tasks_remote_data_source_test.dart` — UC-14-P-02: номера для фильтра идут по возрастанию | PASS |
| UC-14-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — UC-14-P-02: номера заданий приходят без повторов и по порядку | PASS |
| UC-14-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — listCatalog UC-14-P-02: отбор по прогрессу выполняется на клиенте | PASS |
| UC-14-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — listCatalog UC-14-P-02: фильтр уходит в datasource без изменений | PASS |
| UC-14-P-02 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-02: фильтр по сложности уходит в запрос | PASS |
| UC-14-P-02 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-02: фильтр по состоянию решения уходит в запрос | PASS |
| UC-14-P-03 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-03: пустой каталог объясняет себя | PASS |
| UC-14-P-04 | `test/features/tasks/presentation/catalog_screen_test.dart` — UC-14-P-04: ошибка каталога показывается с повтором | PASS |
| UC-15-P-01 | `supabase/tests/rls_tests.sql` — UC-15-P-01: файл опубликованной задачи ученику виден | PASS |
| UC-15-P-01 | `test/features/tasks/data/supabase_tasks_remote_data_source_test.dart` — UC-15-P-01: файлы задачи идут по sort_order по возрастанию | PASS |
| UC-15-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-15-P-01: собирает условие, файлы и справку | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01: на узком экране условие, справка и файлы — вкладки | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01: показывает условие и подсказку про справку | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01: файл разворачивается и показывает первые строки | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: tasks_public отдаёт опубликованную задачу и не отдаёт черновик | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: студенту видны только опубликованные задачи, неопубликованная — нет | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-15-P-02: файл неопубликованной задачи ученику не виден | PASS |
| UC-15-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-15-P-02: неизвестная задача — понятная ошибка | PASS |
| UC-15-P-02 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-02: ошибка загрузки показывается с повтором | PASS |
| UC-15-P-03 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-03: сбой связи показывается сообщением с повтором | PASS |
| UC-16-P-01 | `test/features/editor/editor_panel_test.dart` — UC-16-P-01: черновик подставляется и сохраняется | PASS |
| UC-16-P-01 | `test/features/editor/editor_test.dart` — PreferencesDraftStorage UC-16-P-01: пустой черновик удаляется | PASS |
| UC-16-P-01 | `test/features/editor/editor_test.dart` — PreferencesDraftStorage UC-16-P-01: сохраняет и читает черновик задачи | PASS |
| UC-17-P-01 | `test/features/editor/editor_panel_test.dart` — UC-17-P-01, UC-17-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет | PASS |
| UC-17-P-01 | `test/features/editor/editor_panel_test.dart` — UC-17-P-01: запуск передаёт код и файлы задачи | PASS |
| UC-17-P-01 | `test/features/editor/editor_panel_test.dart` — UC-17-P-01: пока грузится среда, «Запустить» доступна, а «Стоп» — нет | PASS |
| UC-17-P-01 | `test/features/editor/editor_test.dart` — RunController UC-17-P-01: запуск передаёт код, ввод и файлы задачи | PASS |
| UC-17-P-01 | `test/features/editor/editor_test.dart` — RunController UC-17-P-01: состояние среды приходит из потока | PASS |
| UC-17-P-02 | `test/features/editor/editor_panel_test.dart` — UC-17-P-02: ошибка программы показывается в консоли | PASS |
| UC-17-P-03 | `test/features/editor/editor_panel_test.dart` — UC-17-P-01, UC-17-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет | PASS |
| UC-17-P-03 | `test/features/editor/editor_test.dart` — RunController UC-17-P-03: «Стоп» доходит до среды | PASS |
| UC-17-P-04 | `test/features/editor/editor_panel_test.dart` — UC-17-P-04: таймаут — сообщение в консоли и своя строка состояния | PASS |
| UC-17-P-05 | `test/features/editor/editor_test.dart` — RunController UC-17-P-05: ошибка среды попадает в состояние | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: для multi из вывода берётся вся таблица одной строкой | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: для остальных форматов из вывода берётся последняя строка | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: ответ подставляется из вывода программы | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: single — верный ответ засчитан, '012' равен '12', неверный не засчитан | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: string — посимвольно с учётом регистра, другой регистр не засчитан | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01: pair — лишние пробелы не влияют на верный ответ | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-01: непустой ответ уходит в репозиторий | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-01: ответ уходит без пробельных краёв, включая переводы строк | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitController UC-19-P-01: успешная отправка кладёт вердикт в состояние | PASS |
| UC-19-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-01, UC-20-P-01: верный ответ показывает вердикт и предлагает публикацию | PASS |
| UC-19-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-01: ответ уходит без пробельных краёв | PASS |
| UC-19-P-02 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: single — верный ответ засчитан, '012' равен '12', неверный не засчитан | PASS |
| UC-19-P-02 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: string — посимвольно с учётом регистра, другой регистр не засчитан | PASS |
| UC-19-P-02 | `supabase/tests/rls_tests.sql` — UC-19-P-02: задача без эталонного ответа — любой ответ неверен, попытка записана | PASS |
| UC-19-P-02 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-02: неверный ответ публиковать не предлагают | PASS |
| UC-19-P-03 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-03: ответ из одних переводов строк считается пустым | PASS |
| UC-19-P-03 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-03: пустой ответ до сервера не доходит | PASS |
| UC-19-P-04 | `supabase/tests/rls_tests.sql` — UC-19-P-04: отправка сверх лимита за минуту — [rate_limit] | PASS |
| UC-19-P-04 | `test/features/submissions/submissions_test.dart` — SubmitController UC-19-P-04: ошибка отправки видна в состоянии | PASS |
| UC-19-P-04 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-04: ошибка отправки показывается текстом из базы | PASS |
| UC-19-P-05 | `supabase/tests/rls_tests.sql` — UC-19-P-05: неопубликованная и несуществующая задача — [task_not_found], попытки нет | PASS |
| UC-19-P-06 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-06: сбой связи при отправке — текст под кнопкой, вердикта нет | PASS |
| UC-20-P-01 | `supabase/tests/rls_tests.sql` — UC-20-P-01: публикация своей верной попытки — время публикации записано | PASS |
| UC-20-P-01 | `test/features/submissions/submissions_test.dart` — SubmitController UC-20-P-01: публикация зовёт репозиторий | PASS |
| UC-20-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-01, UC-20-P-01: верный ответ показывает вердикт и предлагает публикацию | PASS |
| UC-20-P-02 | `supabase/tests/rls_tests.sql` — UC-20-P-02: снятие с публикации — время публикации снято | PASS |
| UC-20-P-03 | `test/features/submissions/submit_panel_test.dart` — UC-20-P-03: «Не сейчас» скрывает блок и не публикует | PASS |
| UC-20-P-04 | `supabase/tests/rls_tests.sql` — UC-20-P-04: публикация своей неверной попытки — [not_correct] | PASS |
| UC-20-P-04 | `supabase/tests/rls_tests.sql` — UC-20-P-04: публикация чужой попытки — [not_owner] | PASS |
| UC-20-P-04 | `test/features/submissions/submit_panel_test.dart` — UC-20-P-04: публикация не прошла — сообщения нет, блок скрыт, переключатель прежний | PASS |
| UC-21-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-21-P-01: мои попытки показываются с вердиктом | PASS |
| UC-21-P-02 | `test/features/submissions/submit_panel_test.dart` — UC-21-P-02: без попыток — «Попыток пока не было» | PASS |
| UC-21-P-03 | `test/features/submissions/submit_panel_test.dart` — UC-21-P-03: сбой загрузки попыток — ни списка, ни сообщения | PASS |
| UC-22-P-01 | `supabase/tests/rls_tests.sql` — UC-22-P-01: решившему видна ровно опубликованная попытка другого по этой задаче | PASS |
| UC-22-P-01 | `supabase/tests/rls_tests.sql` — UC-22-P-01: решившему задачу неопубликованные попытки других не видны | PASS |
| UC-22-P-01 | `test/features/submissions/solutions_list_test.dart` — UC-22-P-01: после верного ответа видны чужие решения | PASS |
| UC-22-P-02 | `supabase/tests/rls_tests.sql` — UC-22-P-02: опубликованная попытка другого по задаче, которую ученик не решил, не видна | PASS |
| UC-22-P-02 | `test/features/submissions/solutions_list_test.dart` — UC-22-P-02: без своего верного ответа решения закрыты | PASS |
| UC-22-P-03 | `test/features/submissions/solutions_list_test.dart` — UC-22-P-03: решивший видит пустое состояние, если решений нет | PASS |
| UC-22-P-04 | `test/features/submissions/solutions_list_test.dart` — UC-22-P-04: сбой загрузки решений — индикатор загрузки без сообщения | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select answer_explanation под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select reference_solution под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select из task_answers под админом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select из task_answers под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: у клиентских ролей нет прав на task_answers и колонки эталона и разбора в tasks | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой delete из submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой insert в submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой update submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: у клиентских ролей на submissions только select — ни insert, ни update, ни delete | PASS |
