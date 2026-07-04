<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class CreateAiLogsTable extends Migration
{
    public function up()
    {
        DB::statement(<<<'SQL'
CREATE TABLE IF NOT EXISTS ai_logs (
  id BIGSERIAL NOT NULL,
  tenant_id UUID NOT NULL,
  event_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_id UUID DEFAULT gen_random_uuid(),
  model TEXT NOT NULL,
  prompt JSONB NOT NULL,
  response JSONB,
  cost NUMERIC(12,6) DEFAULT 0.0,
  region TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (event_at);
SQL
        );
    }

    public function down()
    {
        DB::statement('DROP TABLE IF EXISTS ai_logs CASCADE');
    }
}
