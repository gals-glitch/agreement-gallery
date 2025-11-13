-- ============================================================================
-- Migration: Add INVESTOR Scope to Agreements (Part 1)
-- Date: 2025-11-11
-- Purpose: Enable investor-level commission agreements
--
-- NOTE: Split into 2 parts because PostgreSQL requires enum values to be
-- committed before they can be referenced in constraints
--
-- Part 1: Add enum value and columns
-- Part 2: Update constraints (run separately after this commits)
-- ============================================================================

-- Step 1: Add 'INVESTOR' to agreement_scope enum (must be separate transaction)
ALTER TYPE agreement_scope ADD VALUE IF NOT EXISTS 'INVESTOR';

-- Step 2: Add investor_id column if it doesn't exist
ALTER TABLE agreements
ADD COLUMN IF NOT EXISTS investor_id BIGINT REFERENCES investors(id);

-- Step 3: Create index for fast lookups (if not exists)
CREATE INDEX IF NOT EXISTS idx_agreements_investor_id
ON agreements(investor_id);

-- Step 4: Add helpful comments
COMMENT ON COLUMN agreements.investor_id IS 'For INVESTOR scope: specific investor this agreement applies to';
COMMENT ON COLUMN agreements.scope IS 'FUND = applies to entire fund; DEAL = applies to specific deal; INVESTOR = applies to specific investor';

-- ============================================================================
-- Verification Queries (run after migration)
-- ============================================================================

-- Verify enum values
-- SELECT unnest(enum_range(NULL::agreement_scope));
-- Expected: FUND, DEAL, INVESTOR

-- Verify constraint works
-- Test INVESTOR scope
-- INSERT INTO agreements (party_id, investor_id, scope, pricing_mode, effective_from, status, kind)
-- VALUES (1, 1, 'INVESTOR', 'CUSTOM', '2025-01-01', 'DRAFT', 'distributor_commission');
-- Expected: Success

-- Test INVESTOR scope without investor_id (should fail)
-- INSERT INTO agreements (party_id, scope, pricing_mode, effective_from, status, kind)
-- VALUES (1, 'INVESTOR', 'CUSTOM', '2025-01-01', 'DRAFT', 'distributor_commission');
-- Expected: Failure (violates constraint)
