-- Migration: 001_organizations.sql
-- Organizations: root tenant table for multi-tenancy ERP

CREATE TABLE IF NOT EXISTS organizations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  plan        TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'enterprise')),
  settings    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_organizations_slug ON organizations (slug);
CREATE INDEX idx_organizations_plan ON organizations (plan);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Users see only their own org (via profiles join)
CREATE POLICY "organizations_select_own"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT org_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Only super_admin can insert new organizations
CREATE POLICY "organizations_insert_super_admin"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Admin and above can update their own org
CREATE POLICY "organizations_update_admin"
  ON organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT org_id FROM profiles
      WHERE id = auth.uid() AND role IN ('super_admin', 'admin')
    )
  )
  WITH CHECK (
    id IN (
      SELECT org_id FROM profiles
      WHERE id = auth.uid() AND role IN ('super_admin', 'admin')
    )
  );

-- Only super_admin can delete organizations
CREATE POLICY "organizations_delete_super_admin"
  ON organizations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );
