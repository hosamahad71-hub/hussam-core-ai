<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class Tenant extends Model
{
    use HasFactory;

    protected $table = 'tenants';
    public $incrementing = false;
    protected $keyType = 'string';
    protected $fillable = ['id', 'code', 'name', 'region', 'metadata'];
    protected $casts = [
        'metadata' => 'array',
    ];

    protected static function booted()
    {
        static::creating(function ($model) {
            if (empty($model->id)) {
                $model->id = (string) Str::uuid();
            }
        });
    }

    public static function findByCode(string $code)
    {
        return static::where('code', $code)->first();
    }
}
