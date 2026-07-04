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
