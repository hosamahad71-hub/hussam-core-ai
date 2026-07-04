<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedgerEntry extends Model
{
    use HasFactory;

    protected $table = 'ledger_entries';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['id', 'tenant_id', 'transaction_id', 'account_id', 'amount', 'side', 'metadata'];

    protected $casts = [
        'metadata' => 'array',
        'amount' => 'float',
    ];

    public function transaction()
    {
        return $this->belongsTo(LedgerTransaction::class, 'transaction_id');
    }

    public function account()
    {
        return $this->belongsTo(Account::class, 'account_id');
    }
}
