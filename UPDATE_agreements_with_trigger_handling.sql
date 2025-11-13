-- ============================================================================
-- [UPDATE] Set Parsed Terms for All 110 Investor Agreements
-- ============================================================================
-- NOTE: Temporarily disables immutability trigger for initial data setup
-- After this one-time update, the trigger will be re-enabled to protect data
-- ============================================================================

-- Step 1: Temporarily disable the immutability trigger
ALTER TABLE agreements DISABLE TRIGGER prevent_update_on_approved;

-- Step 2: Update all agreements with their parsed terms
-- (The UPDATE statements will be appended here by PowerShell)
