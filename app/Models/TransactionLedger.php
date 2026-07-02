<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TransactionLedger extends Model
{
    use HasFactory;

    // توجيه الموديل صراحةً إلى جدول العمليات المالي
    protected $table = 'transactions_ledger';

    /**
     * الحقول المسموح بحقنها جماعياً (Mass Assignment)
     * تم ضبطها لحماية رصيد النظام ومنع التلاعب الثغري
     */
    protected $fillable = [
        'user_id',
        'reference_id',
        'type',
        'amount',
        'running_balance',
        'sector',
        'metadata',
        'description',
    ];

    /**
     * تحويل الأنواع (Casting) تلقائياً عند التعامل مع البيانات
     * حقل metadata يتم تحويله من JSON إلى مصفوفة Array برمجية فوراً
     */
    protected $casts = [
        'metadata' => 'array',
        'amount' => 'decimal:2',
        'running_balance' => 'decimal:2',
    ];

    /**
     * علاقة الارتباط: كل عملية مالية تنتمي إلى مستخدم محدد (تاجر أو عميل)
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
