<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLedgerTransactionsTable extends Migration
{
    public function up()
    {
        Schema::create('ledger_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete()->index();
            $table->uuid('uuid')->unique();
            $table->string('reference')->nullable()->index(); // external reference number
            $table->text('description')->nullable();
            $table->dateTime('posted_at')->index();
            $table->json('metadata')->nullable();
            $table->decimal('total_debits', 20, 4)->default(0);
            $table->decimal('total_credits', 20, 4)->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('ledger_transactions');
    }
}
