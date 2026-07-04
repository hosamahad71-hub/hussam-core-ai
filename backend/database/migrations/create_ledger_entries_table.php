<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class CreateLedgerEntriesTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('ledger_entries')) {
            Schema::create('ledger_entries', function (Blueprint $table) {
                $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
                $table->uuid('tenant_id')->index();
                $table->uuid('transaction_id')->index();
                $table->uuid('account_id')->nullable()->index();
                $table->decimal('amount', 20, 6)->default(0);
                $table->enum('side', ['debit','credit'])->default('debit');
                $table->jsonb('metadata')->nullable();
                $table->timestampTz('created_at')->useCurrent();

                $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
                $table->foreign('transaction_id')->references('id')->on('ledger_transactions')->onDelete('cascade');
                $table->foreign('account_id')->references('id')->on('accounts')->onDelete('set null');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('ledger_entries');
    }
}
