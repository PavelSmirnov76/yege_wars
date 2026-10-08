# Прогон 2026-10-08-4cdfa0e

- Коммит: `4cdfa0e07da2455ae4263046382d37ee5728dac9`
- Дата: 2026-10-08; начат 2026-10-08T12:03:32+00:00, закончен 2026-10-08T12:04:37+00:00
- Незакоммиченные изменения: нет
- Итог: PASS (код 0)
- Тесты: PASS 298, FAIL 0, BLOCKED 0

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
| UC-10-P-02 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-10-P-02: неуспешный вход не меняет состояние | PASS |
| UC-10-P-02 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-02: показывает ошибку сервера | PASS |
| UC-10-P-03 | `test/features/auth/domain/use_cases_test.dart` — SignInUseCase UC-10-P-03: не идёт в репозиторий при коротком пароле | PASS |
| UC-10-P-03 | `test/features/auth/domain/use_cases_test.dart` — SignInUseCase UC-10-P-03: не идёт в репозиторий при неверном логине | PASS |
| UC-10-P-03 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-03: не отправляет форму с некорректным вводом | PASS |
| UC-10-P-04 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-04: сбой связи показывается сообщением | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05, UC-11-P-03: после входа открывается каталог, после выхода — вход | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05: адрес, открытый до проверки сессии, восстанавливается | PASS |
| UC-10-P-05 | `test/app/router/app_router_test.dart` — UC-10-P-05: вошедшего с /login и /register уводит на главную | PASS |
| UC-10-P-05 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-10-P-05: восстановленная сессия загружает профиль | PASS |
| UC-10-P-06 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-10-P-06: ошибка чтения профиля оставляет пользователя снаружи | PASS |
| UC-10-P-06 | `test/features/auth/presentation/login_screen_test.dart` — UC-10-P-06: показывает ошибку восстановления сессии | PASS |
| UC-11-P-01 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-11-P-01: выход возвращает в unauthenticated | PASS |
| UC-11-P-01 | `test/features/profile/profile_screen_test.dart` — UC-11-P-01: кнопка «Выйти» возвращает на экран входа | PASS |
| UC-11-P-02 | `test/features/auth/presentation/auth_controller_test.dart` — действия пользователя UC-11-P-02: ошибка выхода сохраняет вход | PASS |
| UC-11-P-02 | `test/features/profile/profile_screen_test.dart` — UC-11-P-02: ошибка выхода показывается сообщением | PASS |
| UC-11-P-03 | `test/app/router/app_router_test.dart` — UC-10-P-05, UC-11-P-03: после входа открывается каталог, после выхода — вход | PASS |
| UC-11-P-03 | `test/features/auth/presentation/auth_controller_test.dart` — подписка на сессию UC-11-P-03: выход из аккаунта в другой вкладке сбрасывает состояние | PASS |
