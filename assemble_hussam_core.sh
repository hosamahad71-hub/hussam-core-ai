#!/usr/bin/env bash
set -euo pipefail

# assemble_hussam_core.sh
# Creates directories and writes the full production-ready source files for Hussam Core AI.
# Usage: save as assemble_hussam_core.sh, make executable, then run: ./assemble_hussam_core.sh

ROOT_DIR="$(pwd)"

# Directories to create
mkdir -p "$ROOT_DIR/scripts"
mkdir -p "$ROOT_DIR/backend/database"
mkdir -p "$ROOT_DIR/backend/database/migrations"
mkdir -p "$ROOT_DIR/backend/database/seeders"
mkdir -p "$ROOT_DIR/backend/app/Models"
mkdir -p "$ROOT_DIR/backend/app/Repositories"
mkdir -p "$ROOT_DIR/backend/app/Http/Middleware"
mkdir -p "$ROOT_DIR/backend/app/Observers"
mkdir -p "$ROOT_DIR/flutter_client/lib/core/network"

# 1) scripts/apply_apex_core.sh
cat > "$ROOT_DIR/scripts/apply_apex_core.sh" <<'EOF'
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
EOF
chmod +x "$ROOT_DIR/scripts/apply_apex_core.sh"

# 2) backend/database/apex_core_sync.sql
cat > "$ROOT_DIR/backend/database/apex_core_sync.sql" <<'EOF'
-- apex_core_sync.sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tenants_region ON tenants(region);

CREATE TABLE IF NOT EXISTS tenant_settings (
  id BIGSERIAL PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, key)
);
CREATE INDEX IF NOT EXISTS idx_tenant_settings_tenant ON tenant_settings(tenant_id);

CREATE TABLE IF NOT EXISTS ai_logs (
  id BIGSERIAL NOT NULL,
  tenant_id UUID NOT NULL,
  event_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_id UUID DEFAULT gen_random_uuid(),
  model TEXT NOT NULL,
  prompt JSONB NOT NULL,
  response JSONB,
  cost NUMERIC(12,6) DEFAULT 0.0,
  region TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (event_at);

DO $$
DECLARE
  i INT := 0;
  p_name TEXT;
  p_start TIMESTAMP;
  p_end TIMESTAMP;
BEGIN
  WHILE i < 18 LOOP
    p_start := date_trunc('month', now()) + (interval '1 month' * i);
    p_end := p_start + interval '1 month';
    p_name := format('ai_logs_p_%s', to_char(p_start, 'YYYY_MM'));
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = p_name) THEN
      EXECUTE format('CREATE TABLE %I PARTITION OF ai_logs FOR VALUES FROM (%L) TO (%L)', p_name, p_start, p_end);
    END IF;
    i := i + 1;
  END LOOP;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_ai_logs_tenant_event ON ai_logs (tenant_id, event_at DESC);

CREATE TABLE IF NOT EXISTS ai_logs_daily_summary (
  id BIGSERIAL PRIMARY KEY,
  tenant_id UUID NOT NULL,
  day DATE NOT NULL,
  total_requests BIGINT NOT NULL DEFAULT 0,
  total_cost NUMERIC(14,6) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_ai_logs_daily_tenant_day ON ai_logs_daily_summary (tenant_id, day);

COMMIT;
EOF

# 3) backend/sync_helper.php
cat > "$ROOT_DIR/backend/sync_helper.php" <<'EOF'
#!/usr/bin/env php
<?php
$options = getopt("", ["dsn::", "user::", "pass::", "file::", "help::"]);
if (isset($options['help'])) {
    echo "Usage: php sync_helper.php --dsn='pgsql:host=...;port=...;dbname=...' --user=... --pass=... [--file=data.jsonl]\n";
    exit(0);
}
$dsn = $options['dsn'] ?? getenv('SYNC_PG_DSN') ?: null;
$user = $options['user'] ?? getenv('SYNC_PG_USER') ?: null;
$pass = $options['pass'] ?? getenv('SYNC_PG_PASS') ?: null;
$file = $options['file'] ?? null;
if (!$dsn) {
    fwrite(STDERR, "Missing DSN (use --dsn or set SYNC_PG_DSN)\n");
    exit(2);
}
try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (Exception $e) {
    fwrite(STDERR, "Failed to connect to Postgres: " . $e->getMessage() . "\n");
    exit(3);
}
$in = STDIN;
if ($file) {
    if (!file_exists($file)) {
        fwrite(STDERR, "File not found: $file\n");
        exit(4);
    }
    $in = fopen($file, 'r');
}
$lineNo = 0;
while (!feof($in)) {
    $line = trim(fgets($in));
    $lineNo++;
    if ($line === '') continue;
    $obj = json_decode($line, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        fwrite(STDERR, "JSON parse error on line $lineNo\n");
        continue;
    }
    $type = $obj['type'] ?? null;
    if ($type === 'tenant') {
        $sql = "INSERT INTO tenants (id, code, name, region, metadata, created_at, updated_at)
                VALUES (:id, :code, :name, :region, :metadata, coalesce(:created_at, now()), coalesce(:updated_at, now()))
                ON CONFLICT (id) DO UPDATE SET
                  code = EXCLUDED.code,
                  name = EXCLUDED.name,
                  region = EXCLUDED.region,
                  metadata = EXCLUDED.metadata,
                  updated_at = EXCLUDED.updated_at";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':id' => $obj['id'] ?? null,
            ':code' => $obj['code'] ?? $obj['id'] ?? null,
            ':name' => $obj['name'] ?? 'unknown',
            ':region' => $obj['region'] ?? 'unknown',
            ':metadata' => json_encode($obj['metadata'] ?? new stdClass()),
            ':created_at' => $obj['created_at'] ?? null,
            ':updated_at' => $obj['updated_at'] ?? null,
        ]);
    } elseif ($type === 'ai_log') {
        $sql = "INSERT INTO ai_logs (tenant_id, event_at, request_id, model, prompt, response, cost, region, created_at)
                VALUES (:tenant_id, :event_at, :request_id, :model, :prompt, :response, :cost, :region, coalesce(:created_at, now()))";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':tenant_id' => $obj['tenant_id'],
            ':event_at' => $obj['event_at'] ?? date('c'),
            ':request_id' => $obj['request_id'] ?? null,
            ':model' => $obj['model'] ?? 'unknown',
            ':prompt' => json_encode($obj['prompt'] ?? new stdClass()),
            ':response' => json_encode($obj['response'] ?? null),
            ':cost' => $obj['cost'] ?? 0.0,
            ':region' => $obj['region'] ?? null,
            ':created_at' => $obj['created_at'] ?? null,
        ]);
    } else {
        fwrite(STDERR, "Unknown type on line $lineNo\n");
    }
}
if ($file) fclose($in);
fwrite(STDOUT, "Sync completed\n");
EOF
chmod +x "$ROOT_DIR/backend/sync_helper.php"

# 4) backend/database/migrations/create_tenants_table.php
cat > "$ROOT_DIR/backend/database/migrations/create_tenants_table.php" <<'EOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class CreateTenantsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('tenants')) {
            Schema::create('tenants', function (Blueprint $table) {
                $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
                $table->string('code')->unique();
                $table->string('name');
                $table->string('region')->index();
                $table->jsonb('metadata')->nullable();
                $table->timestampTz('created_at')->useCurrent();
                $table->timestampTz('updated_at')->useCurrent();
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('tenants');
    }
}
EOF

# 5) backend/database/migrations/create_tenant_settings_table.php
cat > "$ROOT_DIR/backend/database/migrations/create_tenant_settings_table.php" <<'EOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTenantSettingsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('tenant_settings')) {
            Schema::create('tenant_settings', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->uuid('tenant_id');
                $table->string('key');
                $table->jsonb('value');
                $table->timestampTz('created_at')->useCurrent();
                $table->timestampTz('updated_at')->useCurrent();

                $table->unique(['tenant_id','key']);
                $table->index('tenant_id');
            });

            Schema::table('tenant_settings', function (Blueprint $table) {
                $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('tenant_settings');
    }
}
EOF

# 6) backend/database/migrations/create_ai_logs_table.php
cat > "$ROOT_DIR/backend/database/migrations/create_ai_logs_table.php" <<'EOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class CreateAiLogsTable extends Migration
{
    public function up()
    {
        DB::statement(<<<'SQL'
CREATE TABLE IF NOT EXISTS ai_logs (
  id BIGSERIAL NOT NULL,
  tenant_id UUID NOT NULL,
  event_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_id UUID DEFAULT gen_random_uuid(),
  model TEXT NOT NULL,
  prompt JSONB NOT NULL,
  response JSONB,
  cost NUMERIC(12,6) DEFAULT 0.0,
  region TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (event_at);
SQL
        );
    }

    public function down()
    {
        DB::statement('DROP TABLE IF EXISTS ai_logs CASCADE');
    }
}
EOF

# 7) backend/app/Models/Tenant.php
cat > "$ROOT_DIR/backend/app/Models/Tenant.php" <<'EOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class Tenant extends Model
{
    use HasFactory;

    protected $table = 'tenants';
    public $incrementing = false;
    protected $keyType = 'string';
    protected $fillable = ['id', 'code', 'name', 'region', 'metadata'];
    protected $casts = [
        'metadata' => 'array',
    ];

    protected static function booted()
    {
        static::creating(function ($model) {
            if (empty($model->id)) {
                $model->id = (string) Str::uuid();
            }
        });
    }

    public static function findByCode(string $code)
    {
        return static::where('code', $code)->first();
    }
}
EOF

# 8) backend/app/Models/AILog.php
cat > "$ROOT_DIR/backend/app/Models/AILog.php" <<'EOF'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AILog extends Model
{
    protected $table = 'ai_logs';
    public $timestamps = false;

    protected $casts = [
        'prompt' => 'array',
        'response' => 'array',
    ];
}
EOF

# 9) backend/app/Repositories/TenantRepository.php
cat > "$ROOT_DIR/backend/app/Repositories/TenantRepository.php" <<'EOF'
<?php
namespace App\Repositories;

use App\Models\Tenant;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;
use Exception;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Redis;

class TenantRepository
{
    protected string $connectionName;
    protected int $cacheTtl;
    protected CacheRepository $cache;

    /**
     * Constructor.
     *
     * @param CacheRepository $cache    The cache implementation (injected).
     * @param string|null     $connectionName Optional DB connection name to run tenant queries on.
     * @param int             $cacheTtl Time-to-live for tenant cache in seconds.
     */
    public function __construct(CacheRepository $cache, ?string $connectionName = null, int $cacheTtl = 300)
    {
        $this->cache = $cache;
        $this->connectionName = $connectionName ?? config('database.default');
        $this->cacheTtl = $cacheTtl;
    }

    /**
     * Return an Eloquent query builder bound to the configured connection.
     */
    protected function query()
    {
        if ($this->connectionName === config('database.default')) {
            return Tenant::query();
        }

        // Use the model's on() to set connection for all queries
        return Tenant::on($this->connectionName)->newQuery();
    }

    /**
     * List all tenants (cached).
     *
     * @return Collection
     */
    public function all(): Collection
    {
        $key = "tenants:all:conn:{$this->connectionName}";
        return $this->cache->remember($key, $this->cacheTtl, function () {
            return $this->query()->get();
        });
    }

    /**
     * Paginate tenants with optional filters (cached per page/filters).
     *
     * @param int $perPage
     * @param array $filters
     * @return LengthAwarePaginator
     */
    public function paginate(int $perPage = 25, array $filters = []): LengthAwarePaginator
    {
        $page = request()->get('page', 1);
        $cacheKey = 'tenants:paginate:' . md5(json_encode([$filters, $perPage, $page, $this->connectionName]));
        return $this->cache->remember($cacheKey, $this->cacheTtl, function () use ($perPage, $filters) {
            $q = $this->query()->orderBy('created_at', 'desc');
            if (!empty($filters['region'])) {
                $q->where('region', $filters['region']);
            }
            if (!empty($filters['code'])) {
                $q->where('code', 'like', "%{$filters['code']}%");
            }
            return $q->paginate($perPage);
        });
    }

    /**
     * Find a tenant by primary ID (UUID).
     *
     * @param string $id
     * @return Tenant|null
     */
    public function findById(string $id): ?Tenant
    {
        $key = "tenant:id:{$id}:conn:{$this->connectionName}";
        return $this->cache->remember($key, $this->cacheTtl, function () use ($id) {
            return $this->query()->where('id', $id)->first();
        });
    }

    /**
     * Find a tenant by its code (human-friendly identifier).
     *
     * @param string $code
     * @return Tenant|null
     */
    public function findByCode(string $code): ?Tenant
    {
        $key = "tenant:code:{$code}:conn:{$this->connectionName}";
        return $this->cache->remember($key, $this->cacheTtl, function () use ($code) {
            return $this->query()->where('code', $code)->first();
        });
    }

    /**
     * Create a tenant and return the instance. Ensures unique code generation if missing.
     *
     * @param array $data
     * @return Tenant
     * @throws Exception
     */
    public function create(array $data): Tenant
    {
        return DB::connection($this->connectionName)->transaction(function () use ($data) {
            if (empty($data['code'])) {
                $data['code'] = $this->generateUniqueCode($data['name'] ?? 'tenant');
            } else {
                $data['code'] = $this->sanitizeCode($data['code']);
                // Ensure uniqueness
                if ($this->query()->where('code', $data['code'])->exists()) {
                    $data['code'] = $this->generateUniqueCode($data['code']);
                }
            }
            // Cast metadata to array/json structure
            if (isset($data['metadata']) && !is_array($data['metadata'])) {
                $data['metadata'] = json_decode($data['metadata'], true) ?? [];
            }

            $tenant = $this->query()->create([
                'id' => $data['id'] ?? null,
                'code' => $data['code'],
                'name' => $data['name'] ?? $data['code'],
                'region' => $data['region'] ?? ($data['metadata']['region'] ?? 'unknown'),
                'metadata' => $data['metadata'] ?? [],
            ]);

            // Warm cache
            $this->warmCaches($tenant);

            // Optionally create schema or DB artifacts if requested in metadata
            $this->provisionStorageForTenant($tenant);

            return $tenant;
        });
    }

    /**
     * Update an existing tenant by id and return the updated model or null.
     *
     * @param string $id
     * @param array $data
     * @return Tenant|null
     */
    public function update(string $id, array $data): ?Tenant
    {
        return DB::connection($this->connectionName)->transaction(function () use ($id, $data) {
            $tenant = $this->query()->where('id', $id)->first();
            if (!$tenant) {
                return null;
            }

            if (isset($data['code'])) {
                $data['code'] = $this->sanitizeCode($data['code']);
                if ($this->query()->where('code', $data['code'])->where('id', '!=', $id)->exists()) {
                    $data['code'] = $this->generateUniqueCode($data['code']);
                }
            }

            if (isset($data['metadata']) && !is_array($data['metadata'])) {
                $data['metadata'] = json_decode($data['metadata'], true) ?? [];
            }

            $tenant->fill([
                'code' => $data['code'] ?? $tenant->code,
                'name' => $data['name'] ?? $tenant->name,
                'region' => $data['region'] ?? $tenant->region,
                'metadata' => $data['metadata'] ?? $tenant->metadata,
            ]);
            $tenant->save();

            $this->clearCaches($tenant);
            $this->warmCaches($tenant);

            // If metadata changed with DB details, attempt to re-provision or adjust
            $this->provisionStorageForTenant($tenant);

            return $tenant;
        });
    }

    /**
     * Soft or hard delete tenant by id.
     *
     * @param string $id
     * @param bool $hardDelete
     * @return bool
     */
    public function delete(string $id, bool $hardDelete = false): bool
    {
        return DB::connection($this->connectionName)->transaction(function () use ($id, $hardDelete) {
            $tenant = $this->query()->where('id', $id)->first();
            if (!$tenant) {
                return false;
            }

            if ($hardDelete) {
                $deleted = $tenant->delete();
            } else {
                // Soft-delete semantics: set metadata.active = false and mark deleted_at if schema supports it
                $meta = (array) ($tenant->metadata ?? []);
                $meta['active'] = false;
                $tenant->metadata = $meta;
                $tenant->save();
                $deleted = true;
            }

            $this->clearCaches($tenant);

            // Optionally revoke resources (best-effort)
            try {
                $this->teardownStorageForTenant($tenant);
            } catch (Exception $e) {
                Log::warning("Failed to teardown storage for tenant {$tenant->id}: {$e->getMessage()}");
            }

            return $deleted;
        });
    }

    /**
     * Generate a safe, unique tenant code from a base string.
     *
     * @param string $base
     * @return string
     */
    protected function generateUniqueCode(string $base): string
    {
        $slug = $this->sanitizeCode($base);
        $attempt = $slug;
        $i = 0;
        while ($this->query()->where('code', $attempt)->exists()) {
            $i++;
            $attempt = $slug . '-' . Str::random(4);
            if ($i > 12) {
                // fallback
                $attempt = $slug . '-' . Str::uuid();
                break;
            }
        }
        return $attempt;
    }

    /**
     * Sanitize code for safe use in identifiers (lowercase, alnum, dashes).
     *
     * @param string $code
     * @return string
     */
    protected function sanitizeCode(string $code): string
    {
        $normalized = mb_strtolower($code, 'UTF-8');
        $normalized = preg_replace('/[^a-z0-9\-]+/', '-', $normalized);
        $normalized = preg_replace('/\-+/', '-', $normalized);
        $normalized = trim($normalized, '-');
        if ($normalized === '') {
            $normalized = 'tenant-' . Str::random(6);
        }
        return $normalized;
    }

    /**
     * Warm caches for a tenant instance.
     *
     * @param Tenant $tenant
     */
    protected function warmCaches(Tenant $tenant): void
    {
        $this->cache->put("tenant:id:{$tenant->id}:conn:{$this->connectionName}", $tenant, $this->cacheTtl);
        $this->cache->put("tenant:code:{$tenant->code}:conn:{$this->connectionName}", $tenant, $this->cacheTtl);

        // Additionally push a Redis short-lived key for fast lookup by other services
        try {
            if (class_exists('Illuminate\Support\Facades\Redis')) {
                $redisKey = "tenant_lookup:{$tenant->code}";
                Redis::setex($redisKey, max(60, $this->cacheTtl), json_encode([
                    'id' => $tenant->id,
                    'code' => $tenant->code,
                    'region' => $tenant->region,
                    'metadata' => $tenant->metadata,
                ]));
            }
        } catch (Exception $e) {
            Log::debug("Redis warm cache failed: " . $e->getMessage());
        }
    }

    /**
     * Clear caches for a tenant.
     *
     * @param Tenant $tenant
     */
    protected function clearCaches(Tenant $tenant): void
    {
        $this->cache->forget("tenant:id:{$tenant->id}:conn:{$this->connectionName}");
        $this->cache->forget("tenant:code:{$tenant->code}:conn:{$this->connectionName}");
        try {
            if (class_exists('Illuminate\Support\Facades\Redis')) {
                Redis::del("tenant_lookup:{$tenant->code}");
            }
        } catch (Exception $e) {
            Log::debug("Redis clear cache failed: " . $e->getMessage());
        }
    }

    /**
     * Provision storage or DB artifacts for a tenant if metadata indicates.
     *
     * Behavior:
     *  - If TENANCY_STRATEGY=schema, create a Postgres schema 'tenant_{code}'.
     *  - If metadata contains db_database, attempt to create database or ensure connectivity (best-effort).
     *
     * @param Tenant $tenant
     */
    protected function provisionStorageForTenant(Tenant $tenant): void
    {
        $meta = (array) ($tenant->metadata ?? []);
        $strategy = env('TENANCY_STRATEGY', 'schema');

        try {
            if ($strategy === 'schema') {
                $schema = 'tenant_' . $tenant->code;
                // Create schema if not exists (Postgres)
                DB::statement("CREATE SCHEMA IF NOT EXISTS \"" . str_replace('"', '""', $schema) . "\"");
            } elseif (!empty($meta['db_database'])) {
                // configure a dedicated connection entry for the tenant at runtime
                $connKey = "tenant_{$tenant->code}";
                $base = config('database.connections.' . config('database.default'));
                $cfg = array_merge($base, [
                    'database' => $meta['db_database'],
                    'username' => $meta['db_username'] ?? $base['username'] ?? null,
                    'password' => $meta['db_password'] ?? $base['password'] ?? null,
                ]);
                Config::set("database.connections.{$connKey}", $cfg);
                DB::purge($connKey);
                DB::reconnect($connKey);
            }
            // Optionally set up initial schema for tenant (tables, indices) via SQL file or migration runner (omitted here)
        } catch (Exception $e) {
            Log::warning("Provision attempt for tenant {$tenant->id} failed: " . $e->getMessage());
        }
    }

    /**
     * Teardown tenant storage (best-effort).
     *
     * @param Tenant $tenant
     */
    protected function teardownStorageForTenant(Tenant $tenant): void
    {
        $meta = (array) ($tenant->metadata ?? []);
        $strategy = env('TENANCY_STRATEGY', 'schema');

        try {
            if ($strategy === 'schema') {
                $schema = 'tenant_' . $tenant->code;
                DB::statement("DROP SCHEMA IF EXISTS \"" . str_replace('"', '""', $schema) . "\" CASCADE");
            } elseif (!empty($meta['db_database'])) {
                // Drop tenant database only if explicitly allowed in configuration
                if (!empty($meta['allow_db_teardown'])) {
                    $dbName = $meta['db_database'];
                    // Use superuser connection or a management connection defined in config for teardown
                    $mgmtConn = config('tenancy.management_connection', null);
                    if ($mgmtConn) {
                        DB::connection($mgmtConn)->statement("DROP DATABASE IF EXISTS \"" . str_replace('"', '""', $dbName) . "\"");
                    } else {
                        Log::warning("No management_connection defined for DB teardown of {$dbName}");
                    }
                }
            }
        } catch (Exception $e) {
            Log::warning("Teardown failed for tenant {$tenant->id}: " . $e->getMessage());
        }
    }
}
EOF

# 10) backend/app/Http/Middleware/TenantMiddleware.php
cat > "$ROOT_DIR/backend/app/Http/Middleware/TenantMiddleware.php" <<'EOF'
<?php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Repositories\TenantRepository;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class TenantMiddleware
{
    protected TenantRepository $tenantRepo;
    protected int $logThresholdMs;

    /**
     * Constructor - TenantRepository is injected via service container.
     *
     * @param TenantRepository $tenantRepo
     * @param int $logThresholdMs When processing exceeds this in ms, log as slow.
     */
    public function __construct(TenantRepository $tenantRepo, int $logThresholdMs = 500)
    {
        $this->tenantRepo = $tenantRepo;
        $this->logThresholdMs = $logThresholdMs;
    }

    /**
     * Handle incoming request: resolve tenant, validate, switch DB/session, and attach tenant to app container.
     *
     * Behavior:
     *  - Resolves tenant by X-Tenant-ID header, X-Tenant-Code header, 'tenant' route parameter, cookie, or subdomain.
     *  - If tenant is marked inactive in metadata['active'] === false, abort with 403.
     *  - If tenancy strategy is 'schema' sets Postgres search_path to tenant_{code}.
     *  - If metadata contains db_database, configures a runtime connection 'tenant_runtime' and reconnects.
     *  - Logs processing time for tenant resolution and connection switching.
     *
     * @param Request $request
     * @param Closure $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $start = microtime(true);
        $tenant = $this->resolveTenantFromRequest($request);

        if (!$tenant) {
            Log::info('Tenant not resolved for request', ['host' => $request->getHost(), 'path' => $request->path()]);
            return response()->json(['error' => 'Tenant not resolved'], Response::HTTP_NOT_FOUND);
        }

        // Attach tenant to container for application use
        App::instance('currentTenant', $tenant);
        $request->attributes->set('currentTenant', $tenant);

        // Validate active flag. Prefer explicit 'active' boolean in model or metadata.
        $meta = (array) ($tenant->metadata ?? []);
        $isActive = true;
        if (array_key_exists('active', $meta)) {
            $isActive = (bool) $meta['active'];
        } elseif (property_exists($tenant, 'active')) {
            $isActive = (bool) ($tenant->active ?? true);
        }

        if (!$isActive) {
            Log::warning('Blocked request for inactive tenant', ['tenant_id' => $tenant->id, 'tenant_code' => $tenant->code]);
            return response()->json(['error' => 'Tenant is inactive'], Response::HTTP_FORBIDDEN);
        }

        // Sector enforcement: if the tenant metadata declares allowed_sectors, ensure requested sector is permitted.
        $allowedSectors = $meta['allowed_sectors'] ?? null;
        if ($allowedSectors && is_array($allowedSectors)) {
            // Request may specify sector in header X-Sector or X-Industry or in route param 'sector'
            $sector = $request->header('X-Sector') ?? $request->header('X-Industry') ?? $request->route('sector') ?? null;
            if ($sector && !in_array($sector, $allowedSectors, true)) {
                Log::warning('Sector access denied for tenant', ['tenant' => $tenant->code, 'sector_requested' => $sector, 'allowed' => $allowedSectors]);
                return response()->json(['error' => 'Sector not permitted for this tenant'], Response::HTTP_FORBIDDEN);
            }
        }

        // Attempt to configure DB context for tenant
        try {
            $this->configureDatabaseForTenant($tenant);
        } catch (\Throwable $e) {
            Log::error('Tenant DB configuration failed', ['tenant' => $tenant->code, 'error' => $e->getMessage()]);
            return response()->json(['error' => 'Tenant DB configuration failed'], Response::HTTP_INTERNAL_SERVER_ERROR);
        }

        $durationMs = (int) ((microtime(true) - $start) * 1000);
        if ($durationMs > $this->logThresholdMs) {
            Log::warning('Slow tenant resolution', ['tenant' => $tenant->code, 'duration_ms' => $durationMs, 'path' => $request->path()]);
        } else {
            Log::info('Tenant resolved', ['tenant' => $tenant->code, 'duration_ms' => $durationMs]);
        }

        return $next($request);
    }

    /**
     * Resolve tenant using headers, route, cookie, or subdomain.
     *
     * @param Request $request
     * @return \App\Models\Tenant|null
     */
    protected function resolveTenantFromRequest(Request $request)
    {
        $headerTenantId = $request->header('X-Tenant-ID');
        $headerTenantCode = $request->header('X-Tenant-Code');
        $routeTenant = $request->route('tenant') ?? $request->route('tenant_code') ?? null;
        $cookieTenant = $request->cookie('tenant_code') ?? null;

        if ($headerTenantId) {
            $tenant = $this->tenantRepo->findById($headerTenantId);
            if ($tenant) {
                return $tenant;
            }
        }

        if ($headerTenantCode) {
            $tenant = $this->tenantRepo->findByCode($headerTenantCode);
            if ($tenant) {
                return $tenant;
            }
        }

        if ($routeTenant) {
            $tenant = $this->tenantRepo->findByCode($routeTenant);
            if ($tenant) {
                return $tenant;
            }
        }

        if ($cookieTenant) {
            $tenant = $this->tenantRepo->findByCode($cookieTenant);
            if ($tenant) {
                return $tenant;
            }
        }

        // Subdomain resolution - assume host like {tenant}.{domain}
        $host = $request->getHost();
        $parts = explode('.', $host);
        if (count($parts) > 2) {
            $possible = $parts[0];
            $tenant = $this->tenantRepo->findByCode($possible);
            if ($tenant) {
                return $tenant;
            }
        }

        // As a last resort, use default tenant code from config
        $default = config('tenancy.default_tenant_code', null);
        if ($default) {
            return $this->tenantRepo->findByCode($default);
        }

        return null;
    }

    /**
     * Configure database context (search_path or dynamic connection) for this tenant.
     *
     * Supports two strategies:
     *  - schema (Postgres schemas): sets search_path to tenant_{code},public
     *  - database (dedicated DB per tenant): configures a runtime connection and reconnects
     *
     * @param $tenant
     */
    protected function configureDatabaseForTenant($tenant): void
    {
        $strategy = env('TENANCY_STRATEGY', 'schema');
        $meta = (array) ($tenant->metadata ?? []);

        if ($strategy === 'schema') {
            // Use the default DB connection but change the search_path for this session (Postgres-specific)
            $schema = 'tenant_' . preg_replace('/[^a-z0-9_]+/i', '_', $tenant->code);
            $connection = DB::connection();
            // Do a best-effort create of schema if missing (requires privileges)
            try {
                DB::statement("CREATE SCHEMA IF NOT EXISTS \"" . str_replace('"', '""', $schema) . "\"");
            } catch (\Throwable $e) {
                // Ignore create failures - the schema might be provisioned elsewhere
                Log::debug('Create schema for tenant failed: ' . $e->getMessage());
            }
            // Set search_path for the current DB session
            DB::statement("SET search_path TO \"" . str_replace('"', '""', $schema) . "\", public");
            // Also optionally set a session variable for debugging
            try {
                DB::statement("SET LOCAL hussam.current_tenant = '" . addslashes($tenant->code) . "'");
            } catch (\Throwable $e) {
                // fine if DB does not accept custom settings
            }
            return;
        }

        if ($strategy === 'database') {
            // If metadata contains db_database info, create a runtime connection entry and reconnect
            if (empty($meta['db_database'])) {
                throw new \RuntimeException("Tenant metadata lacks db_database for database tenancy strategy.");
            }
            $connKey = 'tenant_runtime';
            $base = config('database.connections.' . config('database.default'));
            $cfg = array_merge($base, [
                'database' => $meta['db_database'],
                'username' => $meta['db_username'] ?? $base['username'] ?? null,
                'password' => $meta['db_password'] ?? $base['password'] ?? null,
                'host' => $meta['db_host'] ?? $base['host'] ?? null,
                'port' => $meta['db_port'] ?? $base['port'] ?? null,
            ]);
            config(["database.connections.{$connKey}" => $cfg]);
            DB::purge($connKey);
            DB::reconnect($connKey);
            // Set default connection for the current request to tenant_runtime
            config(['database.default' => $connKey]);
            return;
        }

        // If unknown strategy, do nothing
        Log::warning("Unknown tenancy strategy '{$strategy}' - skipping DB configuration");
    }
}
EOF

# 11) backend/app/Observers/TenantObserver.php
cat > "$ROOT_DIR/backend/app/Observers/TenantObserver.php" <<'EOF'
<?php
namespace App\Observers;

use App\Models\Tenant;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;
use Exception;

class TenantObserver
{
    /**
     * Handle operations before a tenant is created.
     *
     * - Ensure a unique code exists (slug from name).
     * - Sanitize metadata and sectors configuration.
     * - Ensure 'active' key is present in metadata.
     *
     * @param Tenant $tenant
     */
    public function creating(Tenant $tenant)
    {
        // Ensure name is provided
        if (empty($tenant->name) && !empty($tenant->code)) {
            $tenant->name = ucfirst(str_replace('-', ' ', $tenant->code));
        }

        // Generate or sanitize code
        if (empty($tenant->code)) {
            $candidate = Str::slug($tenant->name ?: 'tenant');
            $candidate = $this->ensureUniqueCodeCandidate($candidate);
            $tenant->code = $candidate;
        } else {
            $tenant->code = $this->sanitizeCode($tenant->code);
            if ($this->codeExists($tenant->code)) {
                $tenant->code = $this->ensureUniqueCodeCandidate($tenant->code);
            }
        }

        // Normalize metadata
        $metadata = (array) ($tenant->metadata ?? []);
        // Ensure 'active' present and boolean
        if (!array_key_exists('active', $metadata)) {
            $metadata['active'] = true;
        } else {
            $metadata['active'] = (bool) $metadata['active'];
        }

        // Normalize sectors: must be an array of lowercase strings, unique
        if (!empty($metadata['allowed_sectors']) && is_array($metadata['allowed_sectors'])) {
            $clean = [];
            foreach ($metadata['allowed_sectors'] as $s) {
                $sClean = mb_strtolower(trim((string)$s), 'UTF-8');
                if ($sClean !== '') {
                    $clean[$sClean] = true;
                }
            }
            $metadata['allowed_sectors'] = array_values(array_keys($clean));
        } elseif (empty($metadata['allowed_sectors'])) {
            // Default sectors for a new tenant - conservative default
            $metadata['allowed_sectors'] = ['commerce', 'logistics'];
        }

        // Trim long strings and keep values JSON-serializable
        foreach ($metadata as $k => $v) {
            if (is_string($v)) {
                $metadata[$k] = mb_substr($v, 0, 2048, 'UTF-8');
            }
        }

        $tenant->metadata = $metadata;
    }

    /**
     * Handle operations before a tenant is updated.
     *
     * - Sanitize changed metadata and codes.
     *
     * @param Tenant $tenant
     */
    public function updating(Tenant $tenant)
    {
        // Ensure code sanitation if changed
        if ($tenant->isDirty('code')) {
            $tenant->code = $this->sanitizeCode($tenant->code);
            if ($this->codeExists($tenant->code, $tenant->id)) {
                $tenant->code = $this->ensureUniqueCodeCandidate($tenant->code);
            }
        }

        // Normalize metadata similar to creating
        $metadata = (array) ($tenant->metadata ?? []);
        if (!array_key_exists('active', $metadata)) {
            $metadata['active'] = true;
        } else {
            $metadata['active'] = (bool) $metadata['active'];
        }

        if (!empty($metadata['allowed_sectors']) && is_array($metadata['allowed_sectors'])) {
            $clean = [];
            foreach ($metadata['allowed_sectors'] as $s) {
                $sClean = mb_strtolower(trim((string)$s), 'UTF-8');
                if ($sClean !== '') {
                    $clean[$sClean] = true;
                }
            }
            $metadata['allowed_sectors'] = array_values(array_keys($clean));
        }

        $tenant->metadata = $metadata;
    }

    /**
     * After the tenant is created, attempt to provision tenant-level artifacts like DB schema.
     *
     * @param Tenant $tenant
     */
    public function created(Tenant $tenant)
    {
        $meta = (array) ($tenant->metadata ?? []);
        $strategy = env('TENANCY_STRATEGY', 'schema');

        try {
            if ($strategy === 'schema') {
                $schema = 'tenant_' . preg_replace('/[^a-z0-9_]+/i', '_', $tenant->code);
                DB::statement("CREATE SCHEMA IF NOT EXISTS \"" . str_replace('"', '""', $schema) . "\"");
                // Optionally create default tables in the schema (best-effort): Idempotent SQL
                DB::statement(<<<'SQL'
SET search_path TO "%s", public;
CREATE TABLE IF NOT EXISTS example_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
SQL
                , [$schema]);
            } elseif (!empty($meta['db_database'])) {
                // Create a connection entry for tenant DB if allowed.
                $connKey = 'tenant_' . $tenant->code;
                $base = config('database.connections.' . config('database.default'));
                $cfg = array_merge($base, [
                    'database' => $meta['db_database'],
                    'username' => $meta['db_username'] ?? $base['username'] ?? null,
                    'password' => $meta['db_password'] ?? $base['password'] ?? null,
                    'host' => $meta['db_host'] ?? $base['host'] ?? null,
                    'port' => $meta['db_port'] ?? $base['port'] ?? null,
                ]);
                Config::set("database.connections.{$connKey}", $cfg);
                // Attempt to connect to ensure credentials work
                try {
                    DB::connection($connKey)->getPdo();
                } catch (Exception $e) {
                    Log::warning("Tenant DB connection failed for {$tenant->code}: " . $e->getMessage());
                }
            }
        } catch (Exception $e) {
            Log::warning("Provisioning artifacts for tenant {$tenant->code} failed: " . $e->getMessage());
        }

        Log::info("Tenant observer finished post-create tasks for {$tenant->code}");
    }

    /**
     * Ensure code candidate is unique by appending a random suffix until unique.
     *
     * @param string $candidate
     * @return string
     */
    protected function ensureUniqueCodeCandidate(string $candidate): string
    {
        $base = $candidate;
        $i = 0;
        while ($this->codeExists($candidate)) {
            $candidate = $base . '-' . Str::lower(Str::random(4));
            $i++;
            if ($i > 12) {
                $candidate = $base . '-' . (string) Str::uuid();
                break;
            }
        }
        return $candidate;
    }

    /**
     * Check whether a code exists, excluding an optional tenant id.
     *
     * @param string $code
     * @param string|null $excludeId
     * @return bool
     */
    protected function codeExists(string $code, ?string $excludeId = null): bool
    {
        $q = \App\Models\Tenant::where('code', $code);
        if ($excludeId) {
            $q->where('id', '!=', $excludeId);
        }
        return $q->exists();
    }

    /**
     * Sanitize a code string to safe characters.
     *
     * @param string $code
     * @return string
     */
    protected function sanitizeCode(string $code): string
    {
        $normalized = mb_strtolower($code, 'UTF-8');
        $normalized = preg_replace('/[^a-z0-9\-]+/', '-', $normalized);
        $normalized = preg_replace('/\-+/', '-', $normalized);
        $normalized = trim($normalized, '-');
        if ($normalized === '') {
            $normalized = 'tenant-' . Str::lower(Str::random(6));
        }
        return $normalized;
    }
}
EOF

# 12) backend/database/seeders/TenantSeeder.php
cat > "$ROOT_DIR/backend/database/seeders/TenantSeeder.php" <<'EOF'
<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Tenant;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class TenantSeeder extends Seeder
{
    /**
     * Seed initial national tenants and sectors for the Hussam platform.
     *
     * The seeder creates a default 'hussam' management tenant and several sector tenants:
     *  - commerce (national commerce marketplace)
     *  - logistics (national logistic network)
     *  - industrial (industrial manufacturing / supply)
     *  - regional-commerce (regional commerce aggregator)
     *
     * Each tenant receives realistic metadata including allowed_sectors, region codes, and default settings.
     */
    public function run()
    {
        // Common timestamp for seeded records for determinism
        $now = now();

        // Management/Platform tenant
        Tenant::updateOrCreate(
            ['code' => 'hussam'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Hussam National Platform',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['commerce', 'logistics', 'industrial', 'regional-commerce'],
                    'description' => 'Platform-level tenant for national orchestration and admin.',
                    'created_by' => 'system-seeder',
                    'settings' => [
                        'billing_provider' => 'internal',
                        'ai_model_default' => 'gpt-4',
                    ],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Commerce tenant
        Tenant::updateOrCreate(
            ['code' => 'commerce'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'National Commerce',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['commerce'],
                    'description' => 'E-commerce marketplace across Yemeni regions.',
                    'pricing' => ['currency' => 'YER', 'commission' => 0.025],
                    'settings' => ['max_listings_per_merchant' => 5000],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Logistics tenant
        Tenant::updateOrCreate(
            ['code' => 'logistics'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'National Logistics',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['logistics', 'commerce'],
                    'description' => 'Logistics and delivery network supporting commerce.',
                    'settings' => ['max_vehicle_capacity' => 1000, 'sla_hours' => 72],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Industrial tenant
        Tenant::updateOrCreate(
            ['code' => 'industrial'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Industrial Sector',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['industrial'],
                    'description' => 'Industrial manufacturers and B2B supply chain.',
                    'settings' => ['default_payment_terms_days' => 30],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Regional commerce aggregator (example: southern region)
        Tenant::updateOrCreate(
            ['code' => 'regional-commerce'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Regional Commerce Aggregator',
                'region' => 'YE-South',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['regional-commerce', 'commerce'],
                    'description' => 'Aggregation and routing for the southern economic region.',
                    'settings' => ['region_focus' => 'south'],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Optional: seed tenant settings entries if table exists
        if (DB::getSchemaBuilder()->hasTable('tenant_settings')) {
            $defaults = [
                ['tenant_code' => 'hussam', 'key' => 'ui.theme', 'value' => json_encode(['color' => 'green', 'logo' => null])],
                ['tenant_code' => 'commerce', 'key' => 'pricing.commission', 'value' => json_encode(0.025)],
            ];

            foreach ($defaults as $d) {
                $tenant = Tenant::where('code', $d['tenant_code'])->first();
                if ($tenant) {
                    DB::table('tenant_settings')->updateOrInsert(
                        ['tenant_id' => $tenant->id, 'key' => $d['key']],
                        ['value' => $d['value'], 'created_at' => now(), 'updated_at' => now()]
                    );
                }
            }
        }
    }
}
EOF

# 13) flutter_client/lib/core/network/api_client.dart
cat > "$ROOT_DIR/flutter_client/lib/core/network/api_client.dart" <<'EOF'
// flutter_client/lib/core/network/api_client.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef FutureStringCallback = Future<String?> Function();

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  ApiException(this.message, {this.statusCode, this.details});
  @override
  String toString() => "ApiException: $message (status: $statusCode) ${details ?? ''}";
}

class ApiClient {
  final Dio _dio;
  final FutureStringCallback? tokenProvider;
  final FutureStringCallback? tenantIdProvider;
  final int _maxRetries;
  final Duration _retryDelayBase;

  ApiClient({
    required String baseUrl,
    this.tokenProvider,
    this.tenantIdProvider,
    int maxRetries = 2,
    Duration retryDelayBase = const Duration(milliseconds: 300),
    bool enableLogging = false,
    Map<String, dynamic>? defaultHeaders,
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 30000),
          sendTimeout: const Duration(milliseconds: 15000),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'HussamClient/1.0',
            ...?defaultHeaders,
          },
        )),
        tokenProvider = tokenProvider,
        tenantIdProvider = tenantIdProvider,
        _maxRetries = maxRetries,
        _retryDelayBase = retryDelayBase {
    // Authentication & tenant interceptor
    _dio.interceptors.add(QueuedInterceptorsWrapper(onRequest: (options, handler) async {
      try {
        // Attach tenant header
        if (tenantIdProvider != null) {
          final tenantId = await tenantIdProvider!();
          if (tenantId != null && tenantId.isNotEmpty) {
            options.headers['X-Tenant-ID'] = tenantId;
          }
        }

        // Attach auth header
        if (tokenProvider != null) {
          final token = await tokenProvider!();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
      } catch (e) {
        // If provider fails, allow request to proceed without blocking
        if (kDebugMode) {
          print('ApiClient interceptor provider error: $e');
        }
      }
      handler.next(options);
    }, onError: (err, handler) async {
      // Automatic retry logic for transient network errors and 5xx responses
      final requestOptions = err.requestOptions;
      final extra = requestOptions.extra;
      int retryCount = (extra['retry_count'] as int?) ?? 0;

      final shouldRetry = _shouldRetry(err, retryCount);
      if (shouldRetry && retryCount < _maxRetries) {
        retryCount++;
        final waitDuration = _computeBackoffDelay(retryCount);
        requestOptions.extra['retry_count'] = retryCount;
        await Future.delayed(waitDuration);
        try {
          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e as DioError);
        }
      }

      return handler.next(err);
    }, onResponse: (response, handler) {
      handler.next(response);
    }));

    // Optional logging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) {
        debugPrint('ApiClient: $obj');
      }));
    }
  }

  bool _shouldRetry(DioError err, int retryCount) {
    if (err.type == DioErrorType.connectionTimeout ||
        err.type == DioErrorType.sendTimeout ||
        err.type == DioErrorType.receiveTimeout ||
        err.type == DioErrorType.unknown ||
        err.error is SocketException) {
      return true;
    }
    final status = err.response?.statusCode ?? 0;
    if (status >= 500 && status < 600) {
      return true;
    }
    // Do not retry on 4xx except 429 Too Many Requests
    if (status == 429) {
      return true;
    }
    return false;
  }

  Duration _computeBackoffDelay(int retryCount) {
    final factor = (1 << (retryCount - 1)); // exponential
    return Duration(
      milliseconds: _retryDelayBase.inMilliseconds * factor,
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.put(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.delete(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> uploadFile(String path, String fieldName, List<int> bytes, String filename, {String contentType = 'application/octet-stream'}) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename, contentType: MediaType(contentType.split('/')[0], contentType.split('/').last)),
    });

    try {
      final response = await _dio.post(path, data: formData, options: Options(headers: {'Content-Type': 'multipart/form-data'}));
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioError e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (e.type == DioErrorType.cancel) {
      return ApiException('Request cancelled', statusCode: status, details: body);
    }
    if (e.type == DioErrorType.unknown && e.error is SocketException) {
      return ApiException('Network error: ${e.error}', statusCode: status, details: body);
    }
    if (status != null && status >= 400 && status < 600) {
      final message = (body is Map && body['message'] != null) ? body['message'] : 'HTTP error: $status';
      return ApiException(message, statusCode: status, details: body);
    }
    return ApiException(e.message ?? 'Unknown network error', statusCode: status, details: body);
  }

  /// Expose underlying Dio for advanced usage
  Dio get dio => _dio;
}

// Helper MediaType class to avoid importing extra packages in minimal contexts
class MediaType {
  final String type;
  final String subtype;
  MediaType(this.type, this.subtype);
  @override
  String toString() => '$type/$subtype';
}
EOF

# 14) flutter_client/lib/core/network/supabase_service.dart
cat > "$ROOT_DIR/flutter_client/lib/core/network/supabase_service.dart" <<'EOF'
// flutter_client/lib/core/network/supabase_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class SupabaseService {
  final ApiClient apiClient;
  final String restEndpointPrefix;
  final String storageEndpointPrefix;
  final Map<String, String>? defaultHeaders;

  SupabaseService({
    required this.apiClient,
    required this.restEndpointPrefix,
    required this.storageEndpointPrefix,
    this.defaultHeaders,
  });

  /// Generic Supabase-style REST select (GET) on a table.
  /// Example: GET /rest/v1/{table}?select=*
  Future<List<dynamic>> selectTable(String table, {String select = '*', Map<String, dynamic>? query}) async {
    final path = '$restEndpointPrefix/$table';
    final params = <String, dynamic>{'select': select, ...?query};
    final opts = Options(headers: {...?defaultHeaders, 'Accept': 'application/json'});
    try {
      final resp = await apiClient.get(path, queryParameters: params, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Insert rows into table. Returns inserted rows (if server supports return=representation).
  Future<List<dynamic>> insert(String table, List<Map<String, dynamic>> rows, {bool upsert = false, String? onConflict}) async {
    final path = '$restEndpointPrefix/$table';
    final headers = {
      ...?defaultHeaders,
      'Prefer': upsert ? 'return=representation,resolution=merge-duplicates' : 'return=representation',
      'Content-Type': 'application/json',
    };
    final opts = Options(headers: headers);
    // If onConflict provided, attach query parameter
    String qs = '';
    if (onConflict != null && onConflict.isNotEmpty) {
      // Supabase uses ?on_conflict=column
      qs = '?on_conflict=$onConflict';
    }
    try {
      final resp = await apiClient.post('$path$qs', data: rows, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Upsert provided records into a table using POST with on_conflict.
  Future<List<dynamic>> upsert(String table, List<Map<String, dynamic>> rows, {required String onConflict}) async {
    return insert(table, rows, upsert: true, onConflict: onConflict);
  }

  /// Update rows using RPC style or direct PATCH if allowed; uses primary key in payload
  Future<List<dynamic>> updateByPk(String table, String pkName, dynamic pkValue, Map<String, dynamic> changes) async {
    final path = '$restEndpointPrefix/$table?$pkName=eq.$pkValue';
    final headers = {...?defaultHeaders, 'Prefer': 'return=representation', 'Content-Type': 'application/json'};
    final opts = Options(headers: headers);
    try {
      final resp = await apiClient.patch(path, data: changes, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Delete by primary key value
  Future<void> deleteByPk(String table, String pkName, dynamic pkValue) async {
    final path = '$restEndpointPrefix/$table?$pkName=eq.$pkValue';
    try {
      await apiClient.delete(path);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Upload a file to storage bucket (simple wrapper).
  Future<String> uploadFile(String bucketPath, String fileName, List<int> bytes, {required String contentType}) async {
    final path = '$storageEndpointPrefix/$bucketPath';
    try {
      final resp = await apiClient.uploadFile(path, 'file', bytes, fileName, contentType: contentType);
      final data = resp.data;
      if (data is Map && data['Key'] != null) {
        return data['Key'].toString();
      }
      return jsonEncode(data);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// High-level sync: upsert a batch of ai_logs (delegated to Supabase table "ai_logs")
  Future<void> syncAiLogsBatch(List<Map<String, dynamic>> logsBatch, {int batchSize = 100}) async {
    final chunks = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < logsBatch.length; i += batchSize) {
      chunks.add(logsBatch.sublist(i, i + batchSize > logsBatch.length ? logsBatch.length : i + batchSize));
    }
    for (final chunk in chunks) {
      try {
        await upsert('ai_logs', chunk, onConflict: 'request_id');
      } catch (e) {
        // On failure, attempt single-record retries to isolate bad payloads
        for (final record in chunk) {
          try {
            await upsert('ai_logs', [record], onConflict: 'request_id');
          } catch (singleErr) {
            // Log and swallow to avoid entire sync failing
            // Integrators should capture these via remote error tracking
            if (kDebugMode) {
              print('Failed to upsert ai_log record: $singleErr');
            }
          }
        }
      }
    }
  }

  /// Helper: Normalize Dio Response to a list of dynamic objects consistently
  List<dynamic> _normalizeData(Response resp) {
    if (resp.data == null) return [];
    if (resp.data is List) return resp.data as List<dynamic>;
    if (resp.data is Map && (resp.data as Map).containsKey('data')) {
      final d = (resp.data as Map)['data'];
      if (d is List) return d;
      return [d];
    }
    // Fallback to wrapping single object
    return [resp.data];
  }

  /// Map/unwrap errors into ApiException for callers to handle
  Exception _wrapError(Object e) {
    if (e is ApiException) return e;
    if (e is DioError) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && body['message'] != null) ? body['message'] : e.message;
      return ApiException(msg ?? 'Network error', statusCode: status, details: body);
    }
    return ApiException(e.toString());
  }
}
EOF

# Final validation echo and listing
echo "All files written. Verifying..."

# List the created files
created_files=(
  "$ROOT_DIR/scripts/apply_apex_core.sh"
  "$ROOT_DIR/backend/database/apex_core_sync.sql"
  "$ROOT_DIR/backend/sync_helper.php"
  "$ROOT_DIR/backend/database/migrations/create_tenants_table.php"
  "$ROOT_DIR/backend/database/migrations/create_tenant_settings_table.php"
  "$ROOT_DIR/backend/database/migrations/create_ai_logs_table.php"
  "$ROOT_DIR/backend/app/Models/Tenant.php"
  "$ROOT_DIR/backend/app/Models/AILog.php"
  "$ROOT_DIR/backend/app/Repositories/TenantRepository.php"
  "$ROOT_DIR/backend/app/Http/Middleware/TenantMiddleware.php"
  "$ROOT_DIR/backend/app/Observers/TenantObserver.php"
  "$ROOT_DIR/backend/database/seeders/TenantSeeder.php"
  "$ROOT_DIR/flutter_client/lib/core/network/api_client.dart"
  "$ROOT_DIR/flutter_client/lib/core/network/supabase_service.dart"
)

all_ok=true
for f in "${created_files[@]}"; do
  if [ -f "$f" ]; then
    echo "WROTE: $f"
  else
    echo "MISSING: $f"
    all_ok=false
  fi
done

if [ "$all_ok" = true ]; then
  echo "SUCCESS: All files have been written to disk."
  echo "You can now run: bash scripts/apply_apex_core.sh (after configuring .env and DB access)"
  exit 0
else
  echo "ERROR: Some files were not created. Inspect the output above."
  exit 2
fi
