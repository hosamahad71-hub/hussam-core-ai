<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\SyncService;

class SyncController extends Controller
{
    protected SyncService $syncService;

    public function __construct(SyncService $syncService)
    {
        $this->syncService = $syncService;
    }

    public function sync(Request $req)
    {
        $tenant = $req->attributes->get('currentTenant');
        if (!$tenant) {
            return response()->json(['message' => 'Tenant not found'], 404);
        }

        $lastSync = $req->input('last_sync') ?? null;
        $payload = $this->syncService->buildInitialPayload($tenant, $lastSync);

        return response()->json($payload);
    }
}
