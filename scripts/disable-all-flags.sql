-- Disable All Feature Flags (Emergency Rollback)
-- Version: 1.5.0
-- Date: 2025-10-19
-- Purpose: Instant rollback - disable all new features with zero downtime

-- This script provides instant rollback capability
-- Users will see pre-v1.5.0 interface immediately

BEGIN;

-- Disable all flags (instant rollback)
UPDATE feature_flags
SET enabled = false,
    updated_at = now()
WHERE enabled = true;

-- Verify all flags are OFF
SELECT
    key,
    enabled,
    enabled_for_roles,
    updated_at
FROM feature_flags
ORDER BY key;

-- Expected output: All enabled = false

COMMIT;

-- Re-enable command (if rollback was mistake):
-- See: scripts/enable-flags-admin.sql
