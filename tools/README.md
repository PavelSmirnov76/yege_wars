# tools/ — контентные скрипты

Скрипты этой папки работают с контентом: банком ФИПИ и задачами проекта. Это
работа вне SDLC-конвейера (`sdlc/AGENTS.md`, раздел «Граница с контентом»). Стык
с продуктом — Content API (`docs/content-api.md`).

- `fipi_import/`, `import_fipi_bank.py` — импорт банка ФИПИ: из выгрузки
  собирается SQL;
- `upload_fipi_assets.py` — вложения банка в Supabase Storage;
- `import_fipi_answers.py` — ответы и эталоны банка;
- `import_repo_tasks.py` — задачи проекта из `tasks/`;
- `content_client.py` — клиент Content API;
- `tests/` — их тесты: `python3 -m unittest discover -s tools/tests -t .`.

## Команды

```bash
set -a; . supabase/.env.local; set +a              # доступы к боевой, значения не выводить

# импорт банка ФИПИ (выгрузка вне репозитория)
python3 tools/import_fipi_bank.py --out /tmp/fipi.sql   # собрать SQL импорта
psql "$SEED_DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/fipi.sql
python3 tools/upload_fipi_assets.py --dry-run      # заливка вложений в Storage

# ответы банка ФИПИ (solutions.json выгрузки, вне репозитория)
python3 tools/import_fipi_answers.py --dry-run     # эталоны без сети
python3 tools/import_fipi_answers.py               # заливка; повтор безопасен
python3 tools/import_fipi_answers.py --publish     # публикация
```

Правка скриптов — тоже работа с контентом. Если для неё нужно изменить схему,
API или клиент, это задание конвейера.
