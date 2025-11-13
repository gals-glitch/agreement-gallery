-- ============================================================
-- STEP 1: Enable Commissions Engine Feature Flag
-- ============================================================
-- Purpose: Turn on commissions UI for admin and finance roles
-- Time: < 1 minute
-- ============================================================

-- Enable the commissions_engine feature flag
INSERT INTO feature_flags(key, name, description, enabled, allowed_roles)
VALUES ('commissions_engine', 'Commissions Engine', 'Enable distributor/referrer commissions', true, ARRAY['admin', 'finance'])
ON CONFLICT (key) DO UPDATE
SET enabled = true,
    allowed_roles = ARRAY['admin', 'finance'];

-- Verify it's enabled
SELECT key, enabled, allowed_roles, created_at, updated_at
FROM feature_flags
WHERE key = 'commissions_engine';

-- Expected result:
-- key                  | enabled | allowed_roles      | created_at | updated_at
-- ---------------------|---------|-------------------|------------|------------
-- commissions_engine   | true    | {admin,finance}   | timestamp  | timestamp

-- ✅ SUCCESS: Feature flag enabled. Frontend will now show Commissions in sidebar for admin/finance users.
