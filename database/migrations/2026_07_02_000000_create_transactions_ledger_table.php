<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions_ledger', function (Blueprint $table) {
            $table->id();
            
            // ربط العملية بالمستخدم (تاجر أو عميل)
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            
            // تفاصيل العملية المالية
            $table->string('reference_id')->unique(); // رقم مرجعي فريد للعملية
            $table->enum('type', ['credit', 'debit']); // دائن أو مدين
            
            // الحقول المالية مجهزة لعملة الريال اليمني (YER) وبدقة العملات الكبيرة
            $table->decimal('amount', 15, 2); // قيمة العملية الحالية
            $table->decimal('running_balance', 15, 2); // الرصيد الإجمالي التراكمي بعد العملية لمنع التلاعب
            
            // تصنيف القطاع (Luxury Ledger, Clinic Intelligence, Retail)
            $table->string('sector')->default('General');
            
            // تفاصيل وبيانات إضافية مشفرة (JSON) للمرونة المستقبلية
            $table->json('metadata')->nullable();
            
            $table->string('description')->nullable(); // شرح يدوي للعملية
            $table->timestamps();
            
            // الفهارس (Indexes) لضمان سرعة البحث الصاروخية في الواجهات
            $table->index(['user_id', 'reference_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions_ledger');
    }
};
