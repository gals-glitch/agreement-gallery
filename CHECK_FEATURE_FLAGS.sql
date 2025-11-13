-- ========================================
-- Check Current Feature Flags State
-- ========================================
-- Run this in Supabase SQL Editor to see what flags exist

-- List all feature flags
SELECT
    key,
    enabled,
    enabled_for_roles,
    description,
    rollout_percentage
FROM feature_flags
ORDER BY key;

-- If this returns empty, you need to insert the flags first!
-- If it returns rows but the flags you need are missing, see below.

-- ========================================
-- INSERT MISSING FLAGS (if needed)
-- ========================================
-- Only run this section if the above query shows missing flags

-- INSERT INTO feature_flags (key, enabled, enabled_for_roles, description, rollout_percentage)
-- VALUES
--   ('charges_engine', false, ARRAY['admin', 'finance'], 'Charge computation and workflow engine', 100),
--   ('vat_admin', false, ARRAY['admin'], 'VAT rate administration interface', 100),
--   ('docs_repository', false, ARRAY['admin'], 'Agreement documents repository', 100),
--   ('credits_management', false, ARRAY['admin', 'finance'], 'Credits ledger management', 100),
--   ('reports_dashboard', false, ARRAY['admin', 'finance', 'ops'], 'Reports and analytics dashboard', 100)
-- ON CONFLICT (key) DO NOTHING;
