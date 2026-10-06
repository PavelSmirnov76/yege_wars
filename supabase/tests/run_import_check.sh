#!/usr/bin/env bash
# =============================================================================
# Воспроизводимая проверка импорта банка ФИПИ на «голом» PostgreSQL 17.
#
# Поднимает временный кластер во временном каталоге, применяет:
#   shim_local.sql -> supabase/migrations/*.sql (по алфавиту)
# собирает скрипт импорта из выгрузки, заливает его и прогоняет
# supabase/tests/import_checks.sql. При любом исходе останавливает сервер
# и удаляет за собой всё, включая собранный SQL.
#
# Использование:
#   bash supabase/tests/run_import_check.sh [каталог выгрузки]
#   FIPI_DUMP=/path/to/dump bash supabase/tests/run_import_check.sh
#
# Успех: код выхода 0 и строка 'IMPORT OK'.
# =============================================================================
set -euo pipefail

# Детерминированная сортировка глобов; файлы шлём в UTF-8
export LC_ALL=C
export PGCLIENTENCODING=UTF8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATIONS_DIR="$REPO_ROOT/supabase/migrations"

# --- каталог выгрузки ---------------------------------------------------------
DUMP_DIR="${1:-${FIPI_DUMP:-$HOME/projects/ege-informatics-2027}}"
DUMP_DIR="${DUMP_DIR/#\~/$HOME}"
if [ ! -f "$DUMP_DIR/tasks.json" ]; then
  echo "ОШИБКА: в «$DUMP_DIR» нет tasks.json — это не выгрузка банка ФИПИ." >&2
  echo "Укажите каталог аргументом или переменной FIPI_DUMP." >&2
  exit 1
fi
DUMP_DIR="$(cd "$DUMP_DIR" && pwd)"

# --- бинарники PostgreSQL 17 --------------------------------------------------
PGBIN="/opt/homebrew/opt/postgresql@17/bin"
if [ ! -x "$PGBIN/initdb" ]; then
  PGBIN="/opt/homebrew/bin"
fi
if [ ! -x "$PGBIN/initdb" ]; then
  echo "ОШИБКА: initdb не найден ни в /opt/homebrew/opt/postgresql@17/bin, ни в /opt/homebrew/bin" >&2
  exit 1
fi

# --- временный каталог, порт --------------------------------------------------
TMP_ROOT="$(mktemp -d)"
PGDATA="$TMP_ROOT/pgdata"
PGLOG="$TMP_ROOT/postgres.log"
IMPORT_SQL="$TMP_ROOT/fipi_import.sql"
IMPORT_STATS="$TMP_ROOT/fipi_import.json"

port_busy() {
  (echo -n > "/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1
}

PORT=55432
while port_busy "$PORT"; do
  PORT=$((PORT + 1))
  if [ "$PORT" -gt 55442 ]; then
    echo "ОШИБКА: не нашёл свободный порт в диапазоне 55432-55442" >&2
    exit 1
  fi
done

cleanup() {
  if [ -d "$PGDATA" ] && "$PGBIN/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
    "$PGBIN/pg_ctl" -D "$PGDATA" stop -m fast >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

# --- что должно быть в выгрузке ----------------------------------------------
echo "Выгрузка: $DUMP_DIR"
KIM24="$(python3 -c "
import json, sys
with open(sys.argv[1] + '/kim_numbers.json', encoding='utf-8') as handle:
    data = json.load(handle)
payload = data.get('24', {})
print(len(payload['tasks'] if isinstance(payload, dict) else payload))
" "$DUMP_DIR")"

# --- юнит-тесты импорта -------------------------------------------------------
echo "Прогоняю юнит-тесты импорта…"
python3 "$REPO_ROOT/tools/tests/test_fipi_import.py"

# --- сборка скрипта импорта ---------------------------------------------------
echo "Собираю скрипт импорта…"
python3 "$REPO_ROOT/tools/import_fipi_bank.py" \
  --dump "$DUMP_DIR" --out "$IMPORT_SQL" --stats "$IMPORT_STATS"

# Сколько вложений из tasks.json реально лежит на диске и сколько файлов
# в каталоге ни одному заданию не принадлежит (хвосты прошлой выгрузки).
FILES_ON_DISK="$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    print(json.load(handle)['files_on_disk'])
" "$IMPORT_STATS")"
ORPHANS="$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    print(json.load(handle)['assets_orphaned'])
" "$IMPORT_STATS")"
if [ "$ORPHANS" -gt 0 ]; then
  echo "В каталоге вложений $ORPHANS файлов, на которые выгрузка не ссылается:"
  echo "это хвосты прошлой загрузки, импорт и заливка идут по tasks.json."
fi

# --- временный кластер --------------------------------------------------------
echo "Инициализирую кластер (порт $PORT, каталог $PGDATA)…"
"$PGBIN/initdb" -D "$PGDATA" -U postgres --auth=trust -E UTF8 --no-locale >/dev/null

if ! "$PGBIN/pg_ctl" -D "$PGDATA" -l "$PGLOG" -w \
     -o "-p $PORT -c listen_addresses=127.0.0.1 -c unix_socket_directories='$TMP_ROOT'" \
     start >/dev/null; then
  echo "ОШИБКА: сервер не стартовал, лог:" >&2
  cat "$PGLOG" >&2
  exit 1
fi

"$PGBIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres yege_import

run_sql() {
  "$PGBIN/psql" -X -q -h 127.0.0.1 -p "$PORT" -U postgres -d yege_import \
    -v ON_ERROR_STOP=1 "$@"
}

echo "Применяю шим auth…"
run_sql -f "$SCRIPT_DIR/shim_local.sql"

shopt -s nullglob
MIGRATIONS=("$MIGRATIONS_DIR"/*.sql)
shopt -u nullglob
if [ "${#MIGRATIONS[@]}" -eq 0 ]; then
  echo "ОШИБКА: в $MIGRATIONS_DIR нет ни одной миграции (*.sql)" >&2
  exit 1
fi

for f in "${MIGRATIONS[@]}"; do
  echo "Применяю миграцию $(basename "$f")…"
  run_sql -f "$f"
done

echo "Заливаю выгрузку…"
run_sql -f "$IMPORT_SQL"

# Сразу после импорта у банка нет ни ответов, ни публикаций.
echo
echo "Проверки импорта:"
run_sql -v "files_on_disk=$FILES_ON_DISK" -v "kim24=$KIM24" \
  -v "published_fipi=0" -v "answered_fipi=0" \
  -f "$SCRIPT_DIR/import_checks.sql"

echo
echo "IMPORT OK"
