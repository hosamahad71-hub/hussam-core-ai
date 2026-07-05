<?php

namespace App\Repositories;

use App\Models\Account;
use Illuminate\Contracts\Cache\Repository as CacheRepository;

class AccountRepository
{
    protected CacheRepository $cache;

    public function __construct(CacheRepository $cache)
    {
        $this->cache = $cache;
    }

    public function findByTenant(string $tenantId)
    {
        return Account::where('tenant_id', $tenantId)->get();
    }
}
