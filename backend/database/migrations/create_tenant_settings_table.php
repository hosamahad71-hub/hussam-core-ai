<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTenantSettingsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('tenant_settings')) {
            Schema::create('tenant_settings', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->uuid('tenant_id');
                $table->string('key');
                $table->jsonb('value');
                $table->timestampTz('created_at')->useCurrent();
                $table->timestampTz('updated_at')->useCurrent();

                $table->unique(['tenant_id','key']);
                $table->index('tenant_id');
            });

            Schema::table('tenant_settings', function (Blueprint $table) {
                $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('tenant_settings');
    }
}
