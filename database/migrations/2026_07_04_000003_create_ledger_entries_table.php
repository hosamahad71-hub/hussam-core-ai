<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLedgerEntriesTable extends Migration
{
    public function up()
    {
        Schema::create('ledger_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ledger_transaction_id')->constrained('ledger_transactions')->cascadeOnDelete()->index();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete()->index();
            $table->foreignId('account_id')->constrained('accounts')->cascadeOnDelete()->index();
            $table->enum('entry_side', ['debit','credit'])->index();
            $table->decimal('amount', 20, 4);
            // balance snapshot after this entry (for fast reads / auditing)
            $table->decimal('account_balance_after', 20, 4)->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['tenant_id','account_id']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('ledger_entries');
    }
}
