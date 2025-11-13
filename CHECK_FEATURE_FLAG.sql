-- ========================================
-- Check Feature Flag Status
-- ========================================

SELECT
    key,
    enabled,
    enabled_for_roles,
    description
FROM feature_flags
WHERE key = 'charges_engine';

-- Expected Result:
-- key: charges_engine
-- enabled: true
-- enabled_for_roles: {admin,finance}
-- description: Charge workflow engine

-- If enabled = false, run:
-- UPDATE feature_flags SET enabled = true WHERE key = 'charges_engine';
