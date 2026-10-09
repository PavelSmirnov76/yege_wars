# Прогон 2026-10-09-b8e2473

- Коммит: `b8e247347bbf8634ad8936b65aaed37ce8b8e557`
- Дата: 2026-10-09; начат 2026-10-09T00:49:30+00:00, закончен 2026-10-09T00:50:35+00:00
- Незакоммиченные изменения: нет
- Итог: PASS (код 0)
- Тесты: PASS 405, FAIL 0, BLOCKED 0

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
| UC-15-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-15-P-01, UC-27-P-01: собирает условие, файлы и справку | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01, UC-27-P-01: на узком экране условие, справка и файлы — вкладки | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01, UC-27-P-01: показывает условие и подсказку про справку | PASS |
| UC-15-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01: файл разворачивается и показывает первые строки | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: tasks_public отдаёт опубликованную задачу и не отдаёт черновик | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-14-P-01, UC-15-P-02: студенту видны только опубликованные задачи, неопубликованная — нет | PASS |
| UC-15-P-02 | `supabase/tests/rls_tests.sql` — UC-15-P-02: файл неопубликованной задачи ученику не виден | PASS |
| UC-15-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-15-P-02: неизвестная задача — понятная ошибка | PASS |
| UC-15-P-02 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-02: ошибка загрузки показывается с повтором | PASS |
| UC-15-P-03 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-03: сбой связи показывается сообщением с повтором | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: для multi из вывода берётся вся таблица одной строкой | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: для остальных форматов из вывода берётся последняя строка | PASS |
| UC-18-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-18-P-01: ответ подставляется из вывода программы | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: single — верный ответ засчитан, '012' равен '12', неверный не засчитан | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01, UC-19-P-02: string — посимвольно с учётом регистра, другой регистр не засчитан | PASS |
| UC-19-P-01 | `supabase/tests/rls_tests.sql` — UC-19-P-01: pair — лишние пробелы не влияют на верный ответ | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-01: непустой ответ уходит в репозиторий | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitAnswerUseCase UC-19-P-01: ответ уходит без пробельных краёв, включая переводы строк | PASS |
| UC-19-P-01 | `test/features/submissions/submissions_test.dart` — SubmitController UC-19-P-01: успешная отправка кладёт вердикт в состояние | PASS |
| UC-19-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-01, UC-33-P-01: верный ответ показывает вердикт и предлагает публикацию | PASS |
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
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select answer_explanation под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select reference_solution под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select из task_answers под админом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: select из task_answers под студентом — permission denied | PASS |
| UC-23-P-01 | `supabase/tests/rls_tests.sql` — UC-23-P-01: у клиентских ролей нет прав на task_answers и колонки эталона и разбора в tasks | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой delete из submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой insert в submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: прямой update submissions — permission denied | PASS |
| UC-24-P-01 | `supabase/tests/rls_tests.sql` — UC-24-P-01: у клиентских ролей на submissions только select — ни insert, ни update, ни delete | PASS |
| UC-27-P-01 | `supabase/tests/rls_tests.sql` — UC-27-P-01: task_articles отдаёт статью задачи по её теме | PASS |
| UC-27-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-15-P-01, UC-27-P-01: собирает условие, файлы и справку | PASS |
| UC-27-P-01 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-27-P-01: справка по темам: статьи вторым запросом, ручные — следом | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: без ручных связей справка состоит из статей по темам | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: без тем справка — ручные связи | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: главные первыми, внутри — по порядку темы, затем ручные | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: повтор ручной связи не дублирует статью | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: статья двух тем — один раз, по ранней теме | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: статья основной темы главная, других тем — сопутствующая | PASS |
| UC-27-P-01 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-01: статья по теме и вручную — один раз, с более сильной значимостью и на месте темы | PASS |
| UC-27-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01, UC-27-P-01: на узком экране условие, справка и файлы — вкладки | PASS |
| UC-27-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-15-P-01, UC-27-P-01: показывает условие и подсказку про справку | PASS |
| UC-27-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-27-P-01: без ручных связей справка показывает статью по теме | PASS |
| UC-27-P-01 | `test/features/tasks/presentation/task_screen_test.dart` — UC-27-P-01: из справки к задаче можно перейти в статью | PASS |
| UC-27-P-02 | `test/features/tasks/data/tasks_repository_impl_test.dart` — getTask UC-27-P-02: без тем со статьями второй запрос не уходит | PASS |
| UC-27-P-02 | `test/features/tasks/domain/task_help_rules_test.dart` — TaskHelpRules.merge UC-27-P-02: нет ни тем, ни ручных связей — справка пустая | PASS |
| UC-27-P-02 | `test/features/tasks/presentation/task_screen_test.dart` — UC-27-P-02: у задачи без статей справка пустая, подсказки над условием нет | PASS |
| UC-28-P-01 | `test/core/markdown/app_markdown_test.dart` — UC-28-P-01: нажатие на внутреннюю ссылку отдаёт slug | PASS |
| UC-28-P-01 | `test/core/markdown/wiki_link_syntax_test.dart` — WikiLinkSyntax UC-28-P-01: известный slug становится ссылкой с заголовком статьи | PASS |
| UC-28-P-01 | `test/features/reference/data/reference_repository_impl_test.dart` — articleTitles UC-28-P-01: собирает словарь «slug — заголовок» | PASS |
| UC-28-P-01 | `test/features/reference/presentation/article_screen_test.dart` — UC-28-P-01: заголовки статей передаются в разметку | PASS |
| UC-28-P-02 | `supabase/tests/rls_tests.sql` — UC-36-P-01, UC-37-P-02, UC-28-P-02: неопубликованная статья ученику не видна | PASS |
| UC-28-P-02 | `test/core/markdown/app_markdown_test.dart` — UC-28-P-02: неизвестная ссылка остаётся текстом | PASS |
| UC-28-P-02 | `test/core/markdown/wiki_link_syntax_test.dart` — WikiLinkSyntax UC-28-P-02: неизвестный slug остаётся обычным текстом | PASS |
| UC-28-P-02 | `test/features/reference/presentation/article_screen_test.dart` — UC-28-P-02: словарь заголовков не загрузился — slug текстом до конца сессии | PASS |
| UC-28-P-03 | `test/features/reference/presentation/article_screen_test.dart` — UC-28-P-03: обычная ссылка не открывается | PASS |
| UC-31-P-01 | `supabase/tests/rls_tests.sql` — UC-31-P-01: автор перезаписывает черновик — строка одна, время записи новое | PASS |
| UC-31-P-01 | `supabase/tests/rls_tests.sql` — UC-31-P-01: автор пишет черновик и читает его | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01, UC-32-P-01: «Запустить» сразу записывает черновик, а запуск записи не ждёт | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: «Отправить ответ» сразу записывает черновик, отправка записи не ждёт, после неё черновик остаётся | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: без правок ни кнопки, ни уход черновик не пишут | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: переход в другой раздел записывает черновик сразу | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: правка переживает смену вкладки и раскладки | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: уход со страницы назад в каталог записывает черновик сразу | PASS |
| UC-31-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01: черновик из базы стоит в поле, правка записывается через 1 с после последней | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — DraftRepositoryImpl UC-31-P-01: загрузка ждёт незаконченной записи той же задачи | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — DraftRepositoryImpl UC-31-P-01: записи задачи идут по очереди — следующая после ответа на предыдущую | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — DraftRepositoryImpl UC-31-P-01: черновик читается из строки базы, нет строки — черновика нет | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — SaveDraftUseCase UC-31-P-01: код записывается черновиком задачи | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — SupabaseDraftRemoteDataSource UC-31-P-01: черновик пишется upsert по ключу «пользователь, задача» | PASS |
| UC-31-P-01 | `test/features/editor/editor_test.dart` — SupabaseDraftRemoteDataSource UC-31-P-01: черновик читается своей строкой задачи | PASS |
| UC-31-P-02 | `supabase/tests/rls_tests.sql` — UC-31-P-02: автор удаляет свой черновик | PASS |
| UC-31-P-02 | `test/features/editor/editor_panel_test.dart` — UC-31-P-02: код из одних пробельных символов удаляет черновик — при следующем открытии поле пустое | PASS |
| UC-31-P-02 | `test/features/editor/editor_test.dart` — SaveDraftUseCase UC-31-P-02: код из одних пробельных символов удаляет черновик | PASS |
| UC-31-P-02 | `test/features/editor/editor_test.dart` — SupabaseDraftRemoteDataSource UC-31-P-02: удаляется своя строка задачи | PASS |
| UC-31-P-03 | `test/features/editor/editor_panel_test.dart` — UC-31-P-03: сбой записи экран не показывает, следующая запись — по кнопке и при уходе — пишет код снова | PASS |
| UC-31-P-03 | `test/features/editor/editor_test.dart` — DraftRepositoryImpl UC-31-P-03: сбой записи — ошибка в результате, следующая запись уходит | PASS |
| UC-31-P-04 | `test/features/tasks/presentation/task_screen_test.dart` — UC-31-P-04: задача загрузилась, а черновик нет — вместо страницы сразу сообщение и «Повторить» | PASS |
| UC-32-P-01 | `test/features/editor/editor_panel_test.dart` — UC-31-P-01, UC-32-P-01: «Запустить» сразу записывает черновик, а запуск записи не ждёт | PASS |
| UC-32-P-01 | `test/features/editor/editor_panel_test.dart` — UC-32-P-01, UC-32-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет | PASS |
| UC-32-P-01 | `test/features/editor/editor_panel_test.dart` — UC-32-P-01: Ctrl+Enter во время запуска не запускает программу второй раз | PASS |
| UC-32-P-01 | `test/features/editor/editor_panel_test.dart` — UC-32-P-01: запуск передаёт код и файлы задачи | PASS |
| UC-32-P-01 | `test/features/editor/editor_panel_test.dart` — UC-32-P-01: пока грузится среда и пока выполняется программа, «Запустить» недоступна, а «Стоп» доступна | PASS |
| UC-32-P-01 | `test/features/editor/editor_test.dart` — RunController UC-32-P-01: запуск передаёт код, ввод и файлы задачи | PASS |
| UC-32-P-01 | `test/features/editor/editor_test.dart` — RunController UC-32-P-01: состояние среды приходит из потока | PASS |
| UC-32-P-01 | `test/features/editor/editor_test.dart` — runtimeStateOnReady UC-32-P-01: Python загрузился во время запуска — программа выполняется | PASS |
| UC-32-P-02 | `test/features/editor/editor_panel_test.dart` — UC-32-P-02: ошибка программы показывается в консоли | PASS |
| UC-32-P-03 | `test/features/editor/editor_panel_test.dart` — UC-32-P-01, UC-32-P-03: во время выполнения «Стоп» доступен, а «Запустить» — нет | PASS |
| UC-32-P-03 | `test/features/editor/editor_panel_test.dart` — UC-32-P-03: «Стоп» во время загрузки среды прерывает её — «Остановлено» | PASS |
| UC-32-P-03 | `test/features/editor/editor_test.dart` — RunController UC-32-P-03: «Стоп» доходит до среды | PASS |
| UC-32-P-04 | `test/features/editor/editor_panel_test.dart` — UC-32-P-04: таймаут — сообщение в консоли и своя строка состояния | PASS |
| UC-32-P-05 | `test/features/editor/editor_test.dart` — RunController UC-32-P-05: ошибка среды попадает в состояние | PASS |
| UC-33-P-01 | `supabase/tests/rls_tests.sql` — UC-33-P-01: публикация своей верной попытки — время публикации записано | PASS |
| UC-33-P-01 | `test/features/submissions/submissions_test.dart` — SubmitController UC-33-P-01: публикация зовёт репозиторий | PASS |
| UC-33-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-19-P-01, UC-33-P-01: верный ответ показывает вердикт и предлагает публикацию | PASS |
| UC-33-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-33-P-01: после публикации из блока переключатель у попытки включён, даже если база ответила не сразу | PASS |
| UC-33-P-02 | `supabase/tests/rls_tests.sql` — UC-33-P-02: снятие с публикации — время публикации снято | PASS |
| UC-33-P-02 | `test/features/submissions/submit_panel_test.dart` — UC-33-P-02: снятие с публикации переключателем — переключатель выключен, даже если база ответила не сразу | PASS |
| UC-33-P-03 | `test/features/submissions/submit_panel_test.dart` — UC-33-P-03: «Не сейчас» скрывает блок и не публикует | PASS |
| UC-33-P-04 | `supabase/tests/rls_tests.sql` — UC-33-P-04: публикация своей неверной попытки — [not_correct] | PASS |
| UC-33-P-04 | `supabase/tests/rls_tests.sql` — UC-33-P-04: публикация чужой попытки — [not_owner] | PASS |
| UC-33-P-04 | `test/features/submissions/submit_panel_test.dart` — UC-33-P-04: переключатель не переключился — внизу экрана сообщение с текстом ошибки, переключатель прежний | PASS |
| UC-33-P-04 | `test/features/submissions/submit_panel_test.dart` — UC-33-P-04: публикация из блока не прошла — блок остаётся, под кнопками текст ошибки, опубликовать можно снова | PASS |
| UC-34-P-01 | `test/features/submissions/submit_panel_test.dart` — UC-34-P-01: мои попытки показываются с вердиктом | PASS |
| UC-34-P-02 | `test/features/submissions/submit_panel_test.dart` — UC-34-P-02: без попыток — «Попыток пока не было» | PASS |
| UC-34-P-03 | `test/features/submissions/submit_panel_test.dart` — UC-34-P-03: сбой загрузки попыток — сразу сообщение и «Повторить» вместо списка | PASS |
| UC-35-P-01 | `supabase/tests/rls_tests.sql` — UC-35-P-01: решившему видна ровно опубликованная попытка другого по этой задаче | PASS |
| UC-35-P-01 | `supabase/tests/rls_tests.sql` — UC-35-P-01: решившему задачу неопубликованные попытки других не видны | PASS |
| UC-35-P-01 | `test/features/submissions/solutions_list_test.dart` — UC-35-P-01: после верного ответа видны чужие решения | PASS |
| UC-35-P-02 | `supabase/tests/rls_tests.sql` — UC-35-P-02: опубликованная попытка другого по задаче, которую ученик не решил, не видна | PASS |
| UC-35-P-02 | `test/features/submissions/solutions_list_test.dart` — UC-35-P-02: без своего верного ответа решения закрыты | PASS |
| UC-35-P-03 | `test/features/submissions/solutions_list_test.dart` — UC-35-P-03: решивший видит пустое состояние, если решений нет | PASS |
| UC-35-P-04 | `test/features/submissions/solutions_list_test.dart` — UC-35-P-04: сбой загрузки решений — сразу сообщение и «Повторить» вместо списка | PASS |
| UC-35-P-04 | `test/features/submissions/solutions_list_test.dart` — UC-35-P-04: свои попытки не загрузились — в «Решениях» сообщение и «Повторить», а не «откроются после верного ответа» | PASS |
| UC-36-P-01 | `supabase/tests/rls_tests.sql` — UC-36-P-01, UC-37-P-01: опубликованная статья ученику видна | PASS |
| UC-36-P-01 | `supabase/tests/rls_tests.sql` — UC-36-P-01, UC-37-P-02, UC-28-P-02: неопубликованная статья ученику не видна | PASS |
| UC-36-P-01 | `test/features/reference/data/supabase_reference_remote_data_source_test.dart` — UC-36-P-01: статьи идут по уровню, затем по названию — по возрастанию | PASS |
| UC-36-P-01 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-01: нажатие на карточку открывает статью | PASS |
| UC-36-P-01 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-01: показывает список статей | PASS |
| UC-36-P-02 | `test/features/reference/data/reference_repository_impl_test.dart` — listArticles UC-36-P-02: фильтр передаётся в datasource без изменений | PASS |
| UC-36-P-02 | `test/features/reference/domain/article_filter_test.dart` — ArticleFilterController UC-36-P-02: выбор другого значения заменяет прежнее | PASS |
| UC-36-P-02 | `test/features/reference/domain/article_filter_test.dart` — ArticleFilterController UC-36-P-02: повторный выбор снимает условие | PASS |
| UC-36-P-02 | `test/features/reference/domain/article_filter_test.dart` — ArticleFilterController UC-36-P-02: сброс очищает все условия | PASS |
| UC-36-P-02 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-02: «Сбросить фильтры» снимает все условия и строку поиска, а текст в поле остаётся | PASS |
| UC-36-P-02 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-02: выбор уровня уходит в запрос | PASS |
| UC-36-P-02 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-02: значения фильтров не загрузились — чипов номеров и тегов нет до перезагрузки страницы, а список работает | PASS |
| UC-36-P-02 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-02: строка поиска уходит в запрос через 300 мс после ввода | PASS |
| UC-36-P-02 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-02: чипы номеров и тегов — из значений фильтров | PASS |
| UC-36-P-03 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-03: по заданным условиям статей нет | PASS |
| UC-36-P-03 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-03: пустой справочник объясняет себя | PASS |
| UC-36-P-04 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-04: ошибка списка показывается с кнопкой повтора | PASS |
| UC-36-P-04 | `test/features/reference/presentation/reference_screen_test.dart` — UC-36-P-04: сбой связи — сразу сообщение и «Повторить», без автоповторов | PASS |
| UC-37-P-01 | `supabase/tests/rls_tests.sql` — UC-36-P-01, UC-37-P-01: опубликованная статья ученику видна | PASS |
| UC-37-P-01 | `test/core/markdown/app_markdown_test.dart` — UC-37-P-01: рисует заголовок, абзац и блок кода | PASS |
| UC-37-P-01 | `test/core/markdown/app_markdown_test.dart` — UC-37-P-01: таблица и цитата не ломают разметку | PASS |
| UC-37-P-01 | `test/features/reference/presentation/article_screen_test.dart` — UC-37-P-01: показывает заголовок, сведения и текст | PASS |
| UC-37-P-02 | `supabase/tests/rls_tests.sql` — UC-36-P-01, UC-37-P-02, UC-28-P-02: неопубликованная статья ученику не видна | PASS |
| UC-37-P-02 | `test/features/reference/data/reference_repository_impl_test.dart` — getArticle UC-37-P-02: отсутствующая статья — понятная ошибка | PASS |
| UC-37-P-02 | `test/features/reference/presentation/article_screen_test.dart` — UC-37-P-02: статьи нет — сразу «Статья справочника не найдена.» и «Повторить» | PASS |
| UC-37-P-03 | `test/features/reference/presentation/article_screen_test.dart` — UC-37-P-03: сбой связи — сразу сообщение и «Повторить», без автоповторов | PASS |
