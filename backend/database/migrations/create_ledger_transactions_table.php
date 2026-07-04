<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class CreateLedgerTransactionsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('ledger_transactions')) {
            Schema::create('ledger_transactions', function (Blueprint $table) {
                $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
                $table->uuid('tenant_id')->index();
                $table->uuid('account_id')->nullable()->index();
                $table->string('reference')->nullable();
                $table->decimal('total_amount', 20, 6)->default(0);
                $table->jsonb('metadata')->nullable();
                $table->timestampTz('created_at')->useCurrent();
                $table->timestampTz('updated_at')->useCurrent();

                $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
                $table->foreign('account_id')->references('id')->on('accounts')->onDelete('set null');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('ledger_transactions');
    }
}
