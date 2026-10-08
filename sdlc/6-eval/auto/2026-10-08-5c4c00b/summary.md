# Прогон 2026-10-08-5c4c00b

- Коммит: `5c4c00b0fa8fd82f1518fcd7a6e06be12a00be09`
- Дата: 2026-10-08; начат 2026-10-08T12:02:11+00:00, закончен 2026-10-08T12:03:14+00:00
- Незакоммиченные изменения: нет
- Итог: PASS (код 0)
- Тесты: PASS 274, FAIL 0, BLOCKED 0

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
| UC-12-P-01 | `test/app/bootstrap_test.dart` — UC-12-P-01: с адресом и ключом bootstrap поднимает Supabase | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без адреса и ключа bootstrap возвращает понятную ошибку | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: без параметров сборки адреса и ключа проекта нет | PASS |
| UC-12-P-02 | `test/app/bootstrap_test.dart` — UC-12-P-02: заглушка объясняет, чего не хватает | PASS |
| UC-12-P-02 | `test/main_test.dart` — UC-12-P-02: без параметров сборки приложение показывает экран «не сконфигурировано» с причиной | PASS |
| UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: Supabase не поднялся — bootstrap возвращает ошибку подключения | PASS |
| UC-12-P-03 | `test/app/bootstrap_test.dart` — UC-12-P-03: заглушка показывает переданные подробности | PASS |
