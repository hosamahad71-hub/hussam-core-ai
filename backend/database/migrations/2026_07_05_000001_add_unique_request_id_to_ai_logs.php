<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddUniqueRequestIdToAiLogs extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds a unique index over tenant_id + request_id to prevent duplicate sync entries.
     */
    public function up()
    {
        Schema::table('ai_logs', function (Blueprint $table) {
            // Defensive: ensure the columns exist; if not, migration will fail and should be adapted to the project DB schema.
            // Add a named index for clarity.
            $table->unique(['tenant_id', 'request_id'], 'ai_logs_tenant_request_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::table('ai_logs', function (Blueprint $table) {
            $table->dropUnique('ai_logs_tenant_request_unique');
        });
    }
}
