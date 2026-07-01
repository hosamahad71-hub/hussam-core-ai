<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('services', function (Blueprint $table) {
            $table->id();
            // ربط الخدمة بالقطاع الخاص بها (foreign key)
            $table->foreignId('sector_id')->constrained()->onDelete('cascade'); 
            $table->string('name'); 
            $table->string('slug')->unique();
            $table->decimal('price', 12, 2)->default(0.00);
            $table->boolean('is_active')->default(true);
            
            // حقول مرنة بصيغة JSON لاستيعاب أي بيانات ذكية ومستقبلية للمنصة
            $table->json('config')->nullable();   
            $table->json('features')->nullable(); 
            $table->json('custom_data')->nullable(); 
            
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('services');
    }
};
