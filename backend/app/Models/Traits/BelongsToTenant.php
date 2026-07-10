<?php

namespace App\Models\Traits;

use Illuminate\Database\Eloquent\Builder;

trait BelongsToTenant
{
    /**
     * الإيقاظ التلقائي للسمة لتأمين وحقن معرف المستأجر سيادياً.
     */
    protected static function bootBelongsToTenant(): void
    {
        // 1. حقن الـ tenant_id تلقائياً عند إنشاء أي سجل جديد
        static::creating(function ($model) {
            if (auth()->check() && empty($model->tenant_id)) {
                $model->tenant_id = auth()->user()->tenant_id;
            }
        });

        // 2. تطبيق السكوب العالمي لمنع المتجر من قراءة بيانات متجر آخر
        static::addGlobalScope('tenant_isolation', function (Builder $builder) {
            if (auth()->check()) {
                $builder->where('tenant_id', auth()->user()->tenant_id);
            }
        });
    }
}
