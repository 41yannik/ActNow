#!/usr/bin/env bash
# setup-backend.sh — Start Supabase, apply schema, and load seed data.
#
# USAGE:
#   ./scripts/setup-backend.sh
#
# PREREQUISITES:
#   - Docker and Docker Compose running
#   - macOS: open Docker.app first
#
# WHAT IT DOES:
#   1. Starts Supabase (postgres, auth, storage)
#   2. Applies database schema
#   3. Loads seed data (test accounts with password 'actnow-dev')

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { printf "${BLUE}${BOLD}===>${NC} $*\n"; }
success() { printf "${GREEN}${BOLD}✓${NC} $*\n"; }
error() { printf "${RED}${BOLD}✗${NC} $*\n"; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA_FILE="$ROOT_DIR/docs/schema.sql"
SEED_FILE="$ROOT_DIR/docs/seed.sql"

# ── Step 1: Install Supabase CLI if needed ──────────────────────────────────

if ! command -v supabase &> /dev/null; then
  log "Installing Supabase CLI..."
  if command -v brew &> /dev/null; then
    brew install supabase/tap/supabase || npm install -g @supabase/cli
  else
    npm install -g @supabase/cli
  fi
  success "Supabase CLI installed"
fi

# ── Step 2: Check Docker daemon ────────────────────────────────────────────

log "Checking Docker daemon..."
if ! docker ps &> /dev/null; then
  error "Docker daemon is not running. Start Docker (macOS: open Docker.app) and try again."
fi
success "Docker is running"

# ── Step 3: Start Supabase ───────────────────────────────────────────────────

log "Starting Supabase stack..."
cd "$ROOT_DIR"
supabase start || error "Failed to start Supabase"
success "Supabase started"

# ── Step 4: Wait for Postgres to be ready ──────────────────────────────────

log "Waiting for Postgres to be ready..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:54321/auth/v1/health &> /dev/null; then
    success "Postgres is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    error "Postgres failed to start"
  fi
  sleep 1
done

# ── Step 5: Get database connection ────────────────────────────────────────

log "Retrieving database credentials..."
DB_URL=$(supabase status --json | jq -r '.db | select(.host) | "postgresql://\(.user):\(.password)@\(.host):\(.port)/\(.database)"' || true)

if [ -z "$DB_URL" ] || [[ "$DB_URL" == "null" ]]; then
  error "Failed to extract database URL from supabase status"
fi

export PGPASSWORD=""

# ── Step 6: Apply schema ───────────────────────────────────────────────────

log "Applying database schema..."
if ! psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE" &> /dev/null; then
  error "Failed to apply schema"
fi
success "Schema applied"

# ── Step 7: Load seed data ─────────────────────────────────────────────────

log "Loading seed data (test accounts)..."
if ! psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SEED_FILE" &> /dev/null; then
  error "Failed to load seed data"
fi
success "Seed data loaded"

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
printf "${GREEN}${BOLD}Backend is ready!${NC}\n"
echo ""
echo "Test accounts (password: 'actnow-dev'):"
echo "  - admin@actnow.test (admin)"
echo "  - helper1@actnow.test (helper)"
echo "  - org1@actnow.test (organization)"
echo ""
echo "Supabase Studio: http://localhost:54323"
echo "Database URL:    $DB_URL"
echo ""
echo "Frontend is running on http://localhost:5173"
echo "Try registering a new account!"
