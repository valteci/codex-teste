#!/bin/sh
set -eu

log() {
  printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

wait_for_db() {
  timeout="${DB_WAIT_TIMEOUT:-60}"
  log "Waiting for database (timeout: ${timeout}s)..."
  DB_WAIT_TIMEOUT="${timeout}" python - <<'PY'
import os
import sys
import time

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

import django
from django.db import connections
from django.db.utils import OperationalError

timeout = int(os.getenv("DB_WAIT_TIMEOUT", "60"))
started_at = time.monotonic()
django.setup()

while True:
    try:
        connection = connections["default"]
        connection.ensure_connection()
        connection.close()
        break
    except OperationalError as exc:
        elapsed = time.monotonic() - started_at
        if elapsed >= timeout:
            print(f"Database unavailable after {timeout}s: {exc}", file=sys.stderr)
            raise SystemExit(1)
        time.sleep(1)
PY
  log "Database is available."
}

if is_true "${WAIT_FOR_DB:-1}"; then
  wait_for_db
fi

if is_true "${RUN_MIGRATIONS:-0}"; then
  log "Applying migrations..."
  python manage.py migrate --noinput
fi

if is_true "${RUN_COLLECTSTATIC:-0}"; then
  log "Collecting static files..."
  python manage.py collectstatic --noinput
fi

if is_true "${RUN_DEPLOY_CHECK:-0}"; then
  log "Running Django deploy checks..."
  python manage.py check --deploy
fi

if [ "$#" -eq 0 ]; then
  set -- \
    gunicorn config.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers "${GUNICORN_WORKERS:-3}" \
    --access-logfile - \
    --error-logfile - \
    --capture-output \
    --log-level "${GUNICORN_LOG_LEVEL:-info}"
fi

log "Starting process: $*"
exec "$@"
