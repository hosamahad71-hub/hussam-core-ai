<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Sector extends Model
{
    use HasFactory;

    // الحقول المسموح بتعبئتها تلقائياً
    protected $fillable = ['name', 'slug', 'icon', 'is_enabled', 'schema_definition'];

    // تحويل البيانات تلقائياً عند استخراجها (مثل تحويل الـ JSON إلى مصفوفة PHP)
    protected $casts = [
        'is_enabled' => 'boolean',
        'schema_definition' => 'array'
    ];

    // علاقة القطاع بالخدمات (القطاع الواحد يحتوي على خدمات متعددة)
    public function services()
    {
        return $this->hasMany(Service::class);
    }
}
