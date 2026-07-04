#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT/backend"
SYNC_SQL="$BACKEND_DIR/database/apex_core_sync.sql"
SYNC_HELPER="$BACKEND_DIR/sync_helper.php"

function info { echo "[INFO] $*"; }
function warn { echo "[WARN] $*"; }
function fatal { echo "[FATAL] $*"; exit 1; }

if [ -f "$ROOT/hussam_ready.zip" ]; then
  info "Found hussam_ready.zip - extracting into project/"
  mkdir -p "$ROOT/project"
  unzip -o "$ROOT/hussam_ready.zip" -d "$ROOT/project"
fi

if [ -d "$BACKEND_DIR" ]; then
  cd "$BACKEND_DIR"
  info "Backend directory: $BACKEND_DIR"

  if command -v composer >/dev/null 2>&1; then
    info "Running composer install (no dev) to ensure dependencies present"
    composer install --no-interaction --no-progress --prefer-dist || warn "composer install failed; please run manually"
  else
    warn "composer not found - skip composer install"
  fi

  if [ -f .env ]; then
    info "Generating application key"
    php artisan key:generate --ansi || warn "php artisan key:generate failed"
  else
    warn ".env not found in backend; please create it before migrating"
  fi

  info "Running migrations"
  php artisan migrate --force || fatal "Migrations failed"

  info "Seeding tenants"
  php artisan db:seed --class=TenantSeeder || warn "Tenant seeder failed"

  if [ -n "${APEX_SYNC_PG_CONN:-}" ]; then
    info "Applying apex_core_sync.sql via psql using APEX_SYNC_PG_CONN"
    psql "$APEX_SYNC_PG_CONN" -f "$SYNC_SQL" || warn "psql apply failed"
  else
    info "APEX_SYNC_PG_CONN not set - skip direct psql apply"
  fi

  if [ -f "$SYNC_HELPER" ]; then
    info "Running sync_helper.php for incremental sync"
    php "$SYNC_HELPER" || warn "sync_helper.php exited non-zero"
  fi

  info "Apex core initialization complete."
else
  fatal "Backend directory not found: $BACKEND_DIR"
fi
