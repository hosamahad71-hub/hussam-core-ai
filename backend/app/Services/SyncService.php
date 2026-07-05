<?php

namespace App\Services;

use App\Repositories\AccountRepository;

class SyncService
{
    protected AccountRepository $accountRepo;

    public function __construct(AccountRepository $accountRepo)
    {
        $this->accountRepo = $accountRepo;
    }

    public function buildInitialPayload($tenant, $lastSync = null)
    {
        // For initial minimal payload, provide tenant, accounts, and sync token
        $accounts = $this->accountRepo->findByTenant($tenant->id);

        return [
            'tenant' => [
                'id' => $tenant->id,
                'code' => $tenant->code,
                'name' => $tenant->name,
            ],
            'accounts' => $accounts,
            'sync_token' => now()->toIso8601String(),
        ];
    }
}
