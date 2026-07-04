<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAccountsTable extends Migration
{
    public function up()
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete()->index();
            $table->uuid('uuid')->unique();
            $table->string('code')->nullable()->index(); // optional accounting code
            $table->string('name');
            $table->enum('type', ['asset','liability','equity','revenue','expense','other'])->default('other')->index();
            $table->string('currency', 8)->nullable(); // override tenant currency if needed
            $table->decimal('balance', 20, 4)->default(0); // running balance (cached)
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'code']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('accounts');
    }
}
