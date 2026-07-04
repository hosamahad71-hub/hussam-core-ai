<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedgerEntry extends Model
{
    use HasFactory;

    protected $table = 'ledger_entries';

    protected $fillable = [
        'ledger_transaction_id', 'tenant_id', 'account_id', 'entry_side', 'amount', 'account_balance_after', 'metadata'
    ];

    protected $casts = [
        'metadata' => 'array',
        'amount' => 'decimal:4',
        'account_balance_after' => 'decimal:4',
    ];

    public function transaction()
    {
        return $this->belongsTo(LedgerTransaction::class, 'ledger_transaction_id');
    }

    public function account()
    {
        return $this->belongsTo(Account::class);
    }
}
