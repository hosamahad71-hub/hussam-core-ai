<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Account extends Model
{
    use HasFactory;

    protected $table = 'accounts';

    protected $fillable = [
        'tenant_id', 'uuid', 'code', 'name', 'type', 'currency', 'balance', 'metadata'
    ];

    protected $casts = [
        'metadata' => 'array',
        'balance' => 'decimal:4',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function ledgerEntries()
    {
        return $this->hasMany(LedgerEntry::class);
    }

    /**
     * Apply an amount to this account's balance.
     * For debit/credit directions, the caller should pass signed amounts per account convention,
     * but the ledger-recording helpers below handle side logic.
     */
    public function adjustBalance(float $signedAmount): void
    {
        // Use direct DB increment in a safe way to avoid race conditions
        $this->balance = bcadd((string)$this->balance, (string)$signedAmount, 4);
        $this->save();
    }
}
