-- Enable Feature Flags for Admin Testing
-- Version: 1.5.0
-- Date: 2025-10-19
-- Purpose: Enable new features for admin-only testing (Week 1 rollout)

-- Safety: This script enables features ONLY for admin role
-- All features default to OFF, this script turns them ON for testing

BEGIN;

-- 1. Enable VAT Admin (admin-only, always restricted)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin'],
    updated_at = now()
WHERE key = 'vat_admin';

-- 2. Enable Agreement Docs Repository (admin-only initially)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin'],
    updated_at = now()
WHERE key = 'docs_repository';

-- 3. Enable Charges Engine (admin-only initially)
UPDATE feature_flags
SET enabled = true,
    enabled_for_roles = ARRAY['admin'],
    updated_at = now()
WHERE key = 'charges_engine';

-- 4. Credits Management remains OFF (enable in Week 2)
-- UPDATE feature_flags
-- SET enabled = true,
--     enabled_for_roles = ARRAY['admin']
-- WHERE key = 'credits_management';

-- 5. Reports Dashboard remains OFF (future release)
-- UPDATE feature_flags
-- SET enabled = true,
--     enabled_for_roles = ARRAY['admin']
-- WHERE key = 'reports_dashboard';

-- Verify changes
SELECT
    key,
    enabled,
    enabled_for_roles,
    description,
    updated_at
FROM feature_flags
ORDER BY key;

-- Expected output:
-- charges_engine     | t | {admin}         | Transactions and charges stub
-- credits_management | f | NULL            | Credits ledger stub
-- docs_repository    | t | {admin}         | Agreement documents repository
-- reports_dashboard  | f | NULL            | Dashboard and reports
-- vat_admin          | t | {admin}         | VAT rates administration

COMMIT;

-- Rollback command (if needed):
-- UPDATE feature_flags SET enabled = false WHERE key IN ('vat_admin', 'docs_repository', 'charges_engine');
