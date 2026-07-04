<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Tenant extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'tenants';

    protected $fillable = [
        'uuid', 'name', 'slug', 'domain', 'sector',
        'config', 'industry_attributes', 'currency', 'is_active',
    ];

    protected $casts = [
        'config' => 'array',
        'industry_attributes' => 'array',
        'is_active' => 'boolean',
    ];

    public function accounts()
    {
        return $this->hasMany(Account::class);
    }

    public function ledgerTransactions()
    {
        return $this->hasMany(LedgerTransaction::class);
    }
}
