<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddUniqueTenantRequestIdToAiLogs extends Migration
{
    /**
     * Run the migrations.
     * Adds a unique constraint on (tenant_id, request_id) to make sync idempotent.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('ai_logs', function (Blueprint $table) {
            // Create a unique index if it does not already exist
            $sm = Schema::getConnection()->getDoctrineSchemaManager();
            $indexes = array_map(function ($idx) { return $idx->getName(); }, $sm->listTableIndexes('ai_logs'));
            if (!in_array('ux_ai_logs_tenant_request_id', $indexes, true)) {
                $table->unique(['tenant_id', 'request_id'], 'ux_ai_logs_tenant_request_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('ai_logs', function (Blueprint $table) {
            $sm = Schema::getConnection()->getDoctrineSchemaManager();
            $indexes = array_map(function ($idx) { return $idx->getName(); }, $sm->listTableIndexes('ai_logs'));
            if (in_array('ux_ai_logs_tenant_request_id', $indexes, true)) {
                $table->dropUnique('ux_ai_logs_tenant_request_id');
            }
        });
    }
}
