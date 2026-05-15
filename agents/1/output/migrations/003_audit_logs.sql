-- Migration: 003_audit_logs.sql
-- Audit Logs: immutable record of every significant action in the system

CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      UUID NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users (id) ON DELETE SET NULL,
  action      TEXT NOT NULL,
  table_name  TEXT NOT NULL,
  record_id   UUID,
  old_data    JSONB,
  new_data    JSONB,
  ip_address  INET,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- No updated_at — audit rows are immutable after insert

CREATE INDEX idx_audit_logs_org_id      ON audit_logs (org_id);
CREATE INDEX idx_audit_logs_user_id     ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_table_name  ON audit_logs (table_name);
CREATE INDEX idx_audit_logs_record_id   ON audit_logs (record_id);
CREATE INDEX idx_audit_logs_created_at  ON audit_logs (created_at DESC);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Admin and above can read audit logs within their own org
CREATE POLICY "audit_logs_select_admin"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    org_id = (
      SELECT org_id FROM profiles WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin', 'manager')
    )
  );

-- Only the system (service role) or internal triggers insert audit rows;
-- regular authenticated users cannot insert directly.
CREATE POLICY "audit_logs_insert_service"
  ON audit_logs FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Audit rows are immutable — no UPDATE allowed
-- (No UPDATE policy created — effectively denied for all roles)

-- Audit rows are immutable — no DELETE allowed
-- (No DELETE policy created — effectively denied for all roles)
