<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ledger_transactions', function (Blueprint $table) {
            $table->id();
            
            // 1. الأعمدة السيادية الأصلية الخاصة بك (محتفظ بها بالكامل)
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('tenant_id')->index();
            $table->foreignId('account_id')->nullable()->index();
            $table->string('reference')->nullable();
            $table->decimal('total_amount', 15, 2)->default(0); // قيد الأموال الذهبي من ملفك الأصلي
            $table->json('json_metadata')->nullable();

            // 2. التحصينات الجديدة المضافة لضمان الحتمية والنزاهة المالية
            $table->string('request_id')->nullable()->unique(); // لمنع تكرار المعاملة عند تذبذب الشبكة
            $table->string('description')->nullable(); // تفاصيل وشرح القيد المحاسبي
            $table->string('currency', 3)->default('YER'); // العملة الافتراضية (ريال يمني)
            $table->enum('status', ['draft', 'posted', 'voided'])->default('draft'); // حالة المعاملة
            
            $table->timestamps();
            $table->softDeletes(); // حظر الحذف النهائي لحفظ التاريخ المالي من التلاعب

            // 3. القيود والعلاقات البرمجية (الربط المباشر والآمن)
            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
            $table->foreign('account_id')->references('id')->on('accounts')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ledger_transactions');
    }
};
