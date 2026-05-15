-- Migration: 002_profiles.sql
-- Profiles: extends Supabase auth.users with org membership and role

CREATE TYPE user_role AS ENUM (
  'super_admin',
  'admin',
  'manager',
  'staff',
  'viewer'
);

CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  org_id      UUID NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
  full_name   TEXT NOT NULL DEFAULT '',
  role        user_role NOT NULL DEFAULT 'viewer',
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_org_id ON profiles (org_id);
CREATE INDEX idx_profiles_role   ON profiles (role);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Authenticated users see all profiles within their own org
CREATE POLICY "profiles_select_same_org"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    org_id = (
      SELECT org_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Users can insert their own profile (triggered on sign-up)
CREATE POLICY "profiles_insert_self"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Users update their own profile; admin/above can update anyone in same org
CREATE POLICY "profiles_update_self_or_admin"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.org_id = profiles.org_id
        AND p.role IN ('super_admin', 'admin')
    )
  )
  WITH CHECK (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.org_id = profiles.org_id
        AND p.role IN ('super_admin', 'admin')
    )
  );

-- Only admin and above can remove a profile from the org
CREATE POLICY "profiles_delete_admin"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.org_id = profiles.org_id
        AND p.role IN ('super_admin', 'admin')
    )
  );
