#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
COPY_INSTEAD_OF_MOVE=true

usage() {
  cat <<EOF
Usage: $0 [--move]

This script bootstraps a Laravel backend in ./backend.
By default it COPIES any detected Models and Migrations from the repository root (or subfolders) into the new Laravel project to remain idempotent and safe.
Pass --move to MOVE the files instead (originals removed). Use with caution.

Steps performed:
 1) Clean existing backend directory
 2) Create new Laravel project with composer
 3) Configure .env and generate app key
 4) Copy/move PHP Model files into backend/app/Models and Migration files into backend/database/migrations
 5) composer install and php artisan migrate

Requirements: composer, php, and a configured DB for migrations (env DB_*).
EOF
}

# Parse args
while [[ ${#@} -gt 0 ]]; do
  case "$1" in
    --move)
      COPY_INSTEAD_OF_MOVE=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

echo "[bootstrap_full] Starting bootstrap at $REPO_ROOT"

# Simple check for required tools
command -v composer >/dev/null 2>&1 || { echo "[bootstrap_full][ERROR] composer not found in PATH. Install Composer and retry."; exit 1; }
command -v php >/dev/null 2>&1 || { echo "[bootstrap_full][ERROR] php not found in PATH. Install PHP (with required extensions) and retry."; exit 1; }

# Step 1: Clean up
if [ -d "$BACKEND_DIR" ]; then
  echo "[bootstrap_full] Removing existing backend directory at $BACKEND_DIR"
  rm -rf "$BACKEND_DIR"
else
  echo "[bootstrap_full] No existing backend directory found. Proceeding."
fi

# Step 2: Initialize Laravel project
echo "[bootstrap_full] Creating new Laravel project in $BACKEND_DIR"
composer create-project --prefer-dist laravel/laravel "$BACKEND_DIR"

# Step 3: Configure .env and generate key
if [ -f "$BACKEND_DIR/.env.example" ]; then
  echo "[bootstrap_full] Copying .env.example -> .env"
  cp -f "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
  echo "[bootstrap_full] Generating APP_KEY"
  pushd "$BACKEND_DIR" >/dev/null
  php artisan key:generate --ansi
  popd >/dev/null
else
  echo "[bootstrap_full][ERROR] .env.example not found in $BACKEND_DIR. Aborting."
  exit 1
fi

# Ensure target directories exist
mkdir -p "$BACKEND_DIR/app/Models"
mkdir -p "$BACKEND_DIR/database/migrations"

# Step 4: Integrate Models and Migrations
# We search the repo (excluding the newly created backend directory) for likely Model and Migration files.

echo "[bootstrap_full] Searching for Model files to copy/move..."
# Model heuristic: php files containing "extends Model" (case-insensitive)
mapfile -t MODEL_FILES < <(grep -RIl --exclude-dir=backend -E "class[[:space:]]+[A-Za-z0-9_]+[[:space:]]+extends[[:space:]]+[A-Za-z0-9_]*Model" . || true)

if [ ${#MODEL_FILES[@]} -eq 0 ]; then
  echo "[bootstrap_full] No Model files found by heuristic."
else
  echo "[bootstrap_full] Found ${#MODEL_FILES[@]} model file(s):"
  for f in "${MODEL_FILES[@]}"; do
    # skip this bootstrap script itself
    if [[ "$f" == "./bootstrap_full.sh" || "$f" == "$BACKEND_DIR"* ]]; then
      continue
    fi
    echo "  - $f"
    base="$(basename "$f")"
    dest="$BACKEND_DIR/app/Models/$base"
    if [ -f "$dest" ]; then
      echo "    [bootstrap_full] Destination $dest exists; backing up to ${dest}.bak.$TIMESTAMP"
      mv "$dest" "${dest}.bak.$TIMESTAMP"
    fi
    if [ "$COPY_INSTEAD_OF_MOVE" = true ]; then
      cp -a "$f" "$dest"
      echo "    [bootstrap_full] Copied -> $dest"
    else
      mv "$f" "$dest"
      echo "    [bootstrap_full] Moved -> $dest"
    fi
  done
fi

# Migrations heuristic: php files containing Schema::create or "extends Migration"
echo "[bootstrap_full] Searching for Migration files to copy/move..."
mapfile -t MIGRATION_FILES < <(grep -RIl --exclude-dir=backend -E "Schema::create|Schema::table|extends[[:space:]]+Migration" . || true)

if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
  echo "[bootstrap_full] No Migration-like files found by heuristic."
else
  echo "[bootstrap_full] Found ${#MIGRATION_FILES[@]} migration-like file(s):"
  for f in "${MIGRATION_FILES[@]}"; do
    # skip vendor, node_modules, and backend directory
    case "$f" in
      ./vendor/*|./node_modules/*|./$BACKEND_DIR/*)
        continue
        ;;
    esac
    echo "  - $f"
    base="$(basename "$f")"
    dest="$BACKEND_DIR/database/migrations/$base"
    if [ -f "$dest" ]; then
      echo "    [bootstrap_full] Destination $dest exists; backing up to ${dest}.bak.$TIMESTAMP"
      mv "$dest" "${dest}.bak.$TIMESTAMP"
    fi
    if [ "$COPY_INSTEAD_OF_MOVE" = true ]; then
      cp -a "$f" "$dest"
      echo "    [bootstrap_full] Copied -> $dest"
    else
      mv "$f" "$dest"
      echo "    [bootstrap_full] Moved -> $dest"
    fi
  done
fi

# Step 5: Setup composer install and migrate
echo "[bootstrap_full] Installing composer dependencies inside backend (composer install)"
pushd "$BACKEND_DIR" >/dev/null
composer install --no-interaction --prefer-dist

# Run migrations. Use --force for non-interactive environments.
echo "[bootstrap_full] Running php artisan migrate --force"
php artisan migrate --force
popd >/dev/null

# Final notes and idempotency
cat <<EOF
[bootstrap_full] Bootstrap completed.
Notes:
 - The script is idempotent: it removes any existing ./backend, recreates it, and copies/moves detected model/migration files.
 - By default the script COPIES the detected files to preserve originals and make the script safe to run multiple times. Use --move to move files instead.
 - You may need to run: chmod +x bootstrap_full.sh
 - Ensure your DB connection is configured in backend/.env before running migrations if migrations need a DB.

EOF

exit 0
