/**
 * Feature Flags System - Database Schema
 * Ticket: ORC-001
 * Date: 2025-10-19
 *
 * Purpose: Enable gradual, role-based rollout of new features
 *
 * Design:
 * - feature_flags table stores flag definitions
 * - Flags can be enabled globally or for specific roles
 * - rollout_percentage allows gradual rollout (future use)
 * - RLS ensures all users can read, only admins can write
 */

-- ============================================
-- CREATE TABLE: feature_flags
-- ============================================
CREATE TABLE IF NOT EXISTS feature_flags (
  key TEXT PRIMARY KEY,
  enabled BOOLEAN DEFAULT FALSE NOT NULL,
  enabled_for_roles TEXT[], -- NULL means all roles when enabled=true, specific roles otherwise
  description TEXT NOT NULL,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled) WHERE enabled = true;

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read flags
CREATE POLICY "feature_flags_select_all"
  ON feature_flags
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Only admins can insert flags
CREATE POLICY "feature_flags_insert_admin"
  ON feature_flags
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Policy: Only admins can update flags
CREATE POLICY "feature_flags_update_admin"
  ON feature_flags
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Policy: Only admins can delete flags
CREATE POLICY "feature_flags_delete_admin"
  ON feature_flags
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- ============================================
-- TRIGGER: Auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_feature_flags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_feature_flags_updated_at
  BEFORE UPDATE ON feature_flags
  FOR EACH ROW
  EXECUTE FUNCTION update_feature_flags_updated_at();

-- ============================================
-- SEED DATA: Initial Feature Flags
-- ============================================
INSERT INTO feature_flags (key, enabled, enabled_for_roles, description, rollout_percentage)
VALUES
  ('docs_repository', FALSE, ARRAY['admin'], 'Enable document repository and PDF upload features', 0),
  ('charges_engine', FALSE, ARRAY['admin', 'finance'], 'Enable automated fee calculation engine', 0),
  ('credits_management', FALSE, ARRAY['admin', 'finance'], 'Enable credits ledger and credit application features', 0),
  ('vat_admin', FALSE, ARRAY['admin'], 'Enable VAT rate management and configuration', 0),
  ('reports_dashboard', FALSE, ARRAY['admin', 'finance', 'ops'], 'Enable advanced reporting dashboard with exports', 0)
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE feature_flags IS 'Feature flag configuration for gradual rollout and role-based access';
COMMENT ON COLUMN feature_flags.key IS 'Unique identifier for the feature flag (e.g., docs_repository)';
COMMENT ON COLUMN feature_flags.enabled IS 'Global enable/disable switch for the feature';
COMMENT ON COLUMN feature_flags.enabled_for_roles IS 'Array of roles that can access this feature when enabled. NULL means all roles.';
COMMENT ON COLUMN feature_flags.description IS 'Human-readable description of what this flag controls';
COMMENT ON COLUMN feature_flags.rollout_percentage IS 'Percentage rollout (0-100) for gradual deployment. 0=off, 100=all users';
