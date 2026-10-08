# Находки приёмки TASK-2

2026-10-08, приёмка [ACC-TASK-2-01](../../../6-eval/acceptance/ACC-TASK-2-01.md)
сдачи [RESULT-TASK-2-01](../../../5-results/RESULT-TASK-2-01.md).

1. Путь UC-12-P-03 «подключиться к Supabase не удалось» наступает, только
   когда падает сам `Supabase.initialize` (supabase_flutter 2.17.2):
   неразбираемый адрес или сбой хранилища сессии. Без сохранённой сессии
   `initialize` к проекту не обращается. С чужим, но верно записанным адресом
   или с неверным ключом `bootstrap` возвращает успех, приложение идёт по
   P-01, ошибка проявится на первых запросах. Тест P-01 в
   `test/app/bootstrap_test.dart` с адресом `https://project.invalid` это
   показывает. Источник — сдача, раздел «Найдено вне задания»; код
   `lib/app/bootstrap.dart` это подтверждает.
2. Три теста P-02 (`без адреса и ключа bootstrap…`, `без параметров сборки
   адреса и ключа…`, `test/main_test.dart`) проверяют пустые значения `Env` и
   рассчитаны на запуск `flutter test` без `--dart-define`. Источник — сдача.
3. Для `SEC-1`, найдено при проверке утечек:
   - в `sdlc_tool/tests/test_run.py` есть поддельный ключ вида `sb_secret_…`
     (тест маскировки) — проверить, не остановит ли его защита от утечек
     GitHub при push;
   - значение логина Content API из `supabase/.env.local` записано в
     `docs/SUPABASE_SETUP.md`, `docs/content-api.md`,
     `tools/content_client.py`, `tools/upload_fipi_assets.py` и в
     `raw/2026-10-08/STATE.md`; пароля в дереве нет;
   - ref проекта — в `raw/2026-10-08/STATE.md` и
     `raw/2026-10-08/DEPLOY_REPORT.md` (решение 27: не секрет, raw не правят).
