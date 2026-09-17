#!/usr/bin/env bash
# =============================================================================
# Локальный прогон RLS-тестов на «голом» PostgreSQL 17 (без Docker и Supabase).
#
# Поднимает временный кластер во временном каталоге, применяет:
#   shim_local.sql -> supabase/migrations/*.sql (по алфавиту) -> rls_tests.sql
# и при любом исходе останавливает сервер и удаляет каталог.
#
# Использование: supabase/tests/run_local.sh
# Успех: код выхода 0 и строка 'RLS OK'.
# =============================================================================
set -euo pipefail

# Детеминированная сортировка глобов; файлы шлём в UTF-8
export LC_ALL=C
export PGCLIENTENCODING=UTF8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATIONS_DIR="$REPO_ROOT/supabase/migrations"

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

# true, если на 127.0.0.1:$1 уже кто-то слушает
port_busy() {
  (echo -n > "/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1
}

PORT=55432
if port_busy "$PORT"; then
  PORT=55433
fi

# --- уборка при любом исходе --------------------------------------------------
cleanup() {
  if [ -d "$PGDATA" ] && "$PGBIN/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
    "$PGBIN/pg_ctl" -D "$PGDATA" stop -m fast >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

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

"$PGBIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres yege_test

run_sql() {
  "$PGBIN/psql" -X -q -h 127.0.0.1 -p "$PORT" -U postgres -d yege_test \
    -v ON_ERROR_STOP=1 -f "$1"
}

# --- шим -> миграции (по алфавиту) -> тесты -----------------------------------
echo "Применяю шим auth…"
run_sql "$SCRIPT_DIR/shim_local.sql"

shopt -s nullglob
MIGRATIONS=("$MIGRATIONS_DIR"/*.sql)
shopt -u nullglob
if [ "${#MIGRATIONS[@]}" -eq 0 ]; then
  echo "ОШИБКА: в $MIGRATIONS_DIR нет ни одной миграции (*.sql)" >&2
  exit 1
fi

for f in "${MIGRATIONS[@]}"; do
  echo "Применяю миграцию $(basename "$f")…"
  run_sql "$f"
done

echo "Запускаю RLS-тесты…"
run_sql "$SCRIPT_DIR/rls_tests.sql"

echo "RLS OK"
