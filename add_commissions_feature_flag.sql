-- ============================================
-- Add commissions_engine feature flag
-- ============================================

-- Insert feature flag for commissions engine
INSERT INTO feature_flags (key, name, description, enabled, allowed_roles)
VALUES (
  'commissions_engine',
  'Commissions Engine',
  'Enable commission calculation and payment workflow for distributors/referrers',
  true,  -- Enabled by default for pilot
  ARRAY['admin', 'finance']::text[]
)
ON CONFLICT (key) DO UPDATE
SET
  enabled = EXCLUDED.enabled,
  allowed_roles = EXCLUDED.allowed_roles,
  updated_at = now();

-- Verify feature flag was created/updated
SELECT key, name, enabled, allowed_roles
FROM feature_flags
WHERE key = 'commissions_engine';
