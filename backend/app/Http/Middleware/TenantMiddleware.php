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
