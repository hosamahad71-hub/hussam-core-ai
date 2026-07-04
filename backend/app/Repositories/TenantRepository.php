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
