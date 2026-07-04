<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedgerTransaction extends Model
{
    use HasFactory;

    protected $table = 'ledger_transactions';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['id', 'tenant_id', 'account_id', 'reference', 'total_amount', 'metadata'];

    protected $casts = [
        'metadata' => 'array',
        'total_amount' => 'float',
    ];

    public function entries()
    {
        return $this->hasMany(LedgerEntry::class, 'transaction_id');
    }

    public function account()
    {
        return $this->belongsTo(Account::class, 'account_id');
    }
}
