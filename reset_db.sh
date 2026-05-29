#!/usr/bin/env bash
# reset_db.sh — Drop and recreate the actnow schema, then load seed data.
#
# USAGE:
#   ./reset_db.sh          # prompts for confirmation
#   ./reset_db.sh -y       # non-interactive (CI / scripted)
#
# PREREQUISITES:
#   The Supabase Docker stack must be running.
#   Start it with:   cd /srv/supabase && docker compose up -d
#   Stop it with:    cd /srv/supabase && docker compose down
#
# HOW IT WORKS:
#   Schema.sql starts with a DROP/RESET block, so running this script is fully
#   idempotent — safe to run any number of times.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/docs/schema.sql"
SEED_FILE="$SCRIPT_DIR/docs/seed.sql"
DB_CONTAINER="supabase-db"
DB_USER="postgres"
DB_NAME="postgres"

# ── helpers ────────────────────────────────────────────────────────────────────

red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

confirm() {
  if [[ "${AUTO_CONFIRM:-0}" == "1" ]]; then return 0; fi
  printf 'Are you sure? (y/N) '
  read -r REPLY
  case "$REPLY" in
    [Yy]) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

psql_exec() {
  # Run a SQL file inside the DB container.
  # Passes -v ON_ERROR_STOP=1 so any SQL error aborts immediately.
  local label="$1"
  local file="$2"
  echo ""
  bold "===> $label"
  docker exec -i "$DB_CONTAINER" \
    psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
    < "$file"
}

wait_for_db() {
  bold "===> Waiting for $DB_CONTAINER to be ready..."
  local retries=30
  until docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -q 2>/dev/null; do
    retries=$((retries - 1))
    if [[ $retries -le 0 ]]; then
      red "ERROR: $DB_CONTAINER did not become ready in time."
      red "Start the stack with:  cd /srv/supabase && docker compose up -d"
      exit 1
    fi
    sleep 1
  done
  green "  DB is ready."
}

# ── entrypoint ─────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "-y" ]]; then
  AUTO_CONFIRM=1
fi

echo ""
bold "╔══════════════════════════════════════════════════╗"
bold "║  actnow — reset DB + ingest schema + seed data  ║"
bold "╚══════════════════════════════════════════════════╝"
echo ""
echo "This will:"
echo "  1. DROP and recreate all public schema objects (tables, functions, etc.)"
echo "  2. Clear all auth.users and storage.objects seed rows"
echo "  3. Re-ingest docs/schema.sql"
echo "  4. Re-ingest docs/seed.sql"
echo ""

confirm

wait_for_db

psql_exec "Applying docs/schema.sql" "$SCHEMA_FILE"
green "  Schema applied."

psql_exec "Applying docs/seed.sql" "$SEED_FILE"
green "  Seed data loaded."

echo ""
green "✔ Done. Database is ready."
echo ""
echo "Quick verify:"
echo "  docker exec supabase-db psql -U postgres -d postgres -c \\"
echo "    \"select role, count(*) from public.profiles group by role order by role;\""
echo ""
echo "Supabase Studio: http://localhost:8000"
echo "REST API:        http://localhost:8000/rest/v1/"
echo ""
