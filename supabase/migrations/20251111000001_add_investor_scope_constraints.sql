-- ============================================================================
-- Migration: Add INVESTOR Scope to Agreements (Part 2)
-- Date: 2025-11-11
-- Purpose: Update constraints to support investor-level agreements
--
-- NOTE: Run this AFTER Part 1 has been committed
-- Part 1 adds the enum value, this part updates the constraints
-- ============================================================================

-- Step 1: Drop old scope constraint
ALTER TABLE agreements DROP CONSTRAINT IF EXISTS agreements_scope_target_ck;

-- Step 2: Add new constraint that supports INVESTOR scope
ALTER TABLE agreements
ADD CONSTRAINT agreements_scope_target_ck CHECK (
  -- FUND scope: requires fund_id, no deal_id, no investor_id
  (scope='FUND' AND fund_id IS NOT NULL AND deal_id IS NULL AND investor_id IS NULL)
  OR
  -- DEAL scope: requires deal_id, no fund_id, no investor_id
  (scope='DEAL' AND deal_id IS NOT NULL AND fund_id IS NULL AND investor_id IS NULL)
  OR
  -- INVESTOR scope: requires investor_id, no fund_id, no deal_id
  (scope='INVESTOR' AND investor_id IS NOT NULL AND fund_id IS NULL AND deal_id IS NULL)
);

-- Step 3: Drop old pricing constraint
ALTER TABLE agreements DROP CONSTRAINT IF EXISTS agreements_pricing_ck;

-- Step 4: Add new pricing constraint that supports INVESTOR scope
ALTER TABLE agreements
ADD CONSTRAINT agreements_pricing_ck CHECK (
  -- FUND scope must use TRACK pricing
  (scope='FUND' AND pricing_mode='TRACK' AND selected_track IS NOT NULL)
  OR
  -- DEAL scope can use TRACK or CUSTOM
  (scope='DEAL' AND (
     (pricing_mode='TRACK' AND selected_track IS NOT NULL)
     OR pricing_mode='CUSTOM'
  ))
  OR
  -- INVESTOR scope must use CUSTOM pricing
  (scope='INVESTOR' AND pricing_mode='CUSTOM')
);

-- ============================================================================
-- Verification Queries (run after migration)
-- ============================================================================

-- Verify enum values
-- SELECT unnest(enum_range(NULL::agreement_scope));
-- Expected: FUND, DEAL, INVESTOR

-- Verify constraint works - Test INVESTOR scope
-- INSERT INTO agreements (party_id, investor_id, kind, scope, pricing_mode, effective_from, status)
-- VALUES (1, 1, 'distributor_commission', 'INVESTOR', 'CUSTOM', '2025-01-01', 'DRAFT');
-- Expected: Success

-- Verify constraint rejects invalid data
-- INSERT INTO agreements (party_id, kind, scope, pricing_mode, effective_from, status)
-- VALUES (1, 'distributor_commission', 'INVESTOR', 'CUSTOM', '2025-01-01', 'DRAFT');
-- Expected: Failure (missing investor_id)
