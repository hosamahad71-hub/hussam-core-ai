<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Account extends Model
{
    use HasFactory;

    protected $table = 'accounts';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['id', 'tenant_id', 'name', 'type', 'balance', 'metadata'];

    protected $casts = [
        'metadata' => 'array',
        'balance' => 'float',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class, 'tenant_id');
    }

    public function transactions()
    {
        return $this->hasMany(LedgerTransaction::class, 'account_id');
    }
}
