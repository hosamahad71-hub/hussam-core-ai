-- apex_core_sync.sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tenants_region ON tenants(region);

CREATE TABLE IF NOT EXISTS tenant_settings (
  id BIGSERIAL PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, key)
);
CREATE INDEX IF NOT EXISTS idx_tenant_settings_tenant ON tenant_settings(tenant_id);

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

DO $$
DECLARE
  i INT := 0;
  p_name TEXT;
  p_start TIMESTAMP;
  p_end TIMESTAMP;
BEGIN
  WHILE i < 18 LOOP
    p_start := date_trunc('month', now()) + (interval '1 month' * i);
    p_end := p_start + interval '1 month';
    p_name := format('ai_logs_p_%s', to_char(p_start, 'YYYY_MM'));
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = p_name) THEN
      EXECUTE format('CREATE TABLE %I PARTITION OF ai_logs FOR VALUES FROM (%L) TO (%L)', p_name, p_start, p_end);
    END IF;
    i := i + 1;
  END LOOP;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_ai_logs_tenant_event ON ai_logs (tenant_id, event_at DESC);

CREATE TABLE IF NOT EXISTS ai_logs_daily_summary (
  id BIGSERIAL PRIMARY KEY,
  tenant_id UUID NOT NULL,
  day DATE NOT NULL,
  total_requests BIGINT NOT NULL DEFAULT 0,
  total_cost NUMERIC(14,6) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_ai_logs_daily_tenant_day ON ai_logs_daily_summary (tenant_id, day);

COMMIT;
