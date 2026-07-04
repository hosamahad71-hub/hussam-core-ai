<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTenantsTable extends Migration
{
    public function up()
    {
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('domain')->nullable()->index();
            $table->enum('sector', ['ecommerce', 'medical', 'services', 'general'])->default('general')->index();
            // Generic config and industry-specific attributes
            $table->json('config')->nullable(); // general tenant configuration
            $table->json('industry_attributes')->nullable(); // sector-specific fields (JSON)
            // Billing / status
            $table->string('currency', 8)->default('USD');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('tenants');
    }
}
