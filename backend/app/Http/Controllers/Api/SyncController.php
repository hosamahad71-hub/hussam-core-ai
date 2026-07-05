<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use App\Models\User;

class SyncController extends Controller
{
    public function __construct()
    {
        // Ensure route is protected by Sanctum (API token) or other auth guard
        $this->middleware('auth:sanctum');
        // Ensure TenantMiddleware runs globally or on this routes group so app('currentTenant') is available
    }

    /**
     * POST /api/sync
     */
    public function sync(Request $request)
    {
        $currentTenant = $request->attributes->get('currentTenant') ?? app('currentTenant') ?? null;
        if (!$currentTenant) {
            return response()->json(['error' => 'Tenant not resolved'], Response::HTTP_NOT_FOUND);
        }

        $user = $request->user();
        if ($user && !$this->userAllowedForTenant($user, $currentTenant->id)) {
            return response()->json(['error' => 'User not authorized for tenant'], Response::HTTP_FORBIDDEN);
        }

        $data = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.request_id' => 'required|string',
            'items.*.model' => 'required|string',
            'items.*.prompt' => 'present',
        ]);

        $items = $data['items'];
        $results = [];

        DB::beginTransaction();
        try {
            foreach ($items as $item) {
                $requestId = (string) ($item['request_id'] ?? '');
                if (empty($requestId)) {
                    $results[] = ['request_id' => $requestId, 'status' => 'invalid_request_id'];
                    continue;
                }

                // Attempt insert; rely on unique constraint (tenant_id, request_id) to prevent duplicates
                $now = now();
                try {
                    DB::table('ai_logs')->insert([
                        'tenant_id' => $currentTenant->id,
                        'event_at' => $now,
                        'request_id' => $requestId,
                        'model' => $item['model'] ?? null,
                        'prompt' => is_array($item['prompt']) || is_object($item['prompt']) ? json_encode($item['prompt']) : ($item['prompt'] ?? null),
                        'response' => isset($item['response']) ? json_encode($item['response']) : null,
                        'cost' => $item['cost'] ?? 0.0,
                        'region' => $item['region'] ?? null,
                        'created_at' => $now,
                    ]);

                    $results[] = ['request_id' => $requestId, 'status' => 'created'];
                } catch (\Exception $e) {
                    // Handle unique violation (duplicate) vs other errors
                    if ($this->isUniqueViolation($e)) {
                        $results[] = ['request_id' => $requestId, 'status' => 'duplicate'];
                    } else {
                        Log::error('Sync item insert failed', ['tenant' => $currentTenant->id, 'error' => $e->getMessage(), 'item' => $item]);
                        $results[] = ['request_id' => $requestId, 'status' => 'failed', 'error' => $e->getMessage()];
                    }
                }
            }
            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Sync transaction failed', ['tenant' => $currentTenant->id ?? null, 'error' => $e->getMessage()]);
            return response()->json(['error' => 'Sync processing failed'], Response::HTTP_INTERNAL_SERVER_ERROR);
        }

        return response()->json(['results' => $results], Response::HTTP_OK);
    }

    protected function userAllowedForTenant(?User $user, string $tenantId): bool
    {
        if (!$user) return false;
        if (isset($user->tenant_id) && $user->tenant_id) {
            return (string) $user->tenant_id === (string) $tenantId;
        }
        if (method_exists($user, 'hasRole') && $user->hasRole('super-admin')) {
            return true;
        }
        return false;
    }

    protected function isUniqueViolation(\Throwable $e): bool
    {
        $msg = $e->getMessage();
        if (stripos($msg, 'duplicate key') !== false || stripos($msg, '23505') !== false || stripos($msg, 'unique') !== false) {
            return true;
        }
        return false;
    }
}
