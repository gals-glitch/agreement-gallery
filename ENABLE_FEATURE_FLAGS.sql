-- ========================================
-- Move 1.4: Enable Feature Flags
-- ========================================
-- Run this in Supabase SQL Editor
-- Date: 2025-10-21

-- Enable charges engine + admin UI features
UPDATE feature_flags
SET enabled = true
WHERE key IN ('charges_engine', 'vat_admin', 'docs_repository');

-- Verify flags are enabled
SELECT key, enabled, enabled_for_roles, description
FROM feature_flags
WHERE key IN ('charges_engine', 'vat_admin', 'docs_repository')
ORDER BY key;

-- Expected output:
-- charges_engine    | t | {admin,finance}
-- docs_repository   | t | {admin}
-- vat_admin         | t | {admin}
