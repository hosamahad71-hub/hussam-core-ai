<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use HasFactory;

    // الحقول المسموح بتعبئتها تلقائياً (Mass Assignment)
    protected $fillable = [
        'sector_id',
        'name',
        'slug',
        'price',
        'is_active',
        'config',
        'features',
        'custom_data'
    ];

    // تحويل البيانات تلقائياً لتبسيط التعامل معها في فرونت إند التطبيق (Flutter)
    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
        'config' => 'array',
        'features' => 'array',
        'custom_data' => 'array'
    ];

    // علاقة الخدمة بالقطاع (كل خدمة تنتمي إلى قطاع واحد محدد)
    public function sector()
    {
        return $this->belongsTo(Sector::class);
    }
}
