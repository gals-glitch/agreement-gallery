-- ============================================
-- Migration: Investor Deal Participation Tracking
-- Purpose: Track investor deal participation count for tiered commission calculations
-- Date: 2025-10-26
-- Version: 1.10.0
-- Ticket: Track investor deal count for tiered commissions
-- ============================================
--
-- BUSINESS CONTEXT:
-- We have 26 investor agreements with tiered commission rates based on deal count:
-- - Deal 1: 1.5% equity commission
-- - Deals 2-3: 1% equity commission
-- - Deals 4-5: 0.5% equity commission
--
-- REQUIREMENT:
-- When calculating commissions, we need to know "this is investor X's Nth deal"
-- to apply the correct tier rate.
--
-- DESIGN DECISION: Junction Table Approach (Option B)
--
-- WHY NOT Option A (deal_count column on investors table)?
-- - Loses historical audit trail
-- - Cannot reconstruct participation history
-- - Vulnerable to data corruption
-- - Cannot answer "which deals did this investor participate in?"
--
-- WHY NOT Option C (derive from contributions table)?
-- - Performance: requires complex aggregation on every query
-- - Ambiguity: multiple contributions to same deal = one participation?
-- - No explicit participation_sequence tracking
--
-- WHY Option B (junction table)?
-- ✅ Complete audit trail preserved
-- ✅ Explicit participation_sequence per investor
-- ✅ Immutable once recorded (safe for financial calculations)
-- ✅ Can reconstruct history at any point in time
-- ✅ Efficient queries with proper indexing
-- ✅ Supports "which deals?" and "how many?" queries equally well
-- ✅ Enables future features (e.g., participation status, notes)
--
-- ============================================

-- ============================================
-- STEP 1: Create investor_deal_participations table
-- ============================================

CREATE TABLE IF NOT EXISTS investor_deal_participations (
  id                    BIGSERIAL PRIMARY KEY,

  -- Core relationships
  investor_id           BIGINT NOT NULL REFERENCES investors(id) ON DELETE RESTRICT,
  deal_id               BIGINT NOT NULL REFERENCES deals(id) ON DELETE RESTRICT,

  -- Participation tracking
  participation_sequence INT NOT NULL CHECK (participation_sequence > 0),

  -- Key dates
  first_contribution_date DATE NOT NULL,
  first_contribution_id   BIGINT NOT NULL REFERENCES contributions(id) ON DELETE RESTRICT,

  -- Audit trail
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by            UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Metadata (optional, for future use)
  notes                 TEXT,

  -- ============================================
  -- CONSTRAINTS
  -- ============================================

  -- One participation record per investor per deal (idempotency)
  CONSTRAINT investor_deal_unique UNIQUE (investor_id, deal_id),

  -- For each investor, participation_sequence must be unique and sequential
  CONSTRAINT investor_sequence_unique UNIQUE (investor_id, participation_sequence)
);

COMMENT ON TABLE investor_deal_participations IS
'Tracks each investor''s deal participation for tiered commission calculations. Each participation gets a sequence number (1, 2, 3...) per investor.';

COMMENT ON COLUMN investor_deal_participations.investor_id IS
'Investor who participated in the deal';

COMMENT ON COLUMN investor_deal_participations.deal_id IS
'Deal that the investor participated in';

COMMENT ON COLUMN investor_deal_participations.participation_sequence IS
'Sequential participation number for this investor (1 = first deal, 2 = second deal, etc.). Determines commission tier.';

COMMENT ON COLUMN investor_deal_participations.first_contribution_date IS
'Date of the investor''s first contribution to this deal (determines participation order)';

COMMENT ON COLUMN investor_deal_participations.first_contribution_id IS
'Reference to the first contribution that established this participation';

COMMENT ON COLUMN investor_deal_participations.notes IS
'Optional notes about this participation (e.g., "Early bird discount applied")';

-- ============================================
-- STEP 2: Create indexes for performance
-- ============================================

-- Primary lookup: get all participations for an investor (ordered by sequence)
CREATE INDEX IF NOT EXISTS idx_investor_deal_part_investor
  ON investor_deal_participations(investor_id, participation_sequence);

-- Reverse lookup: which investors participated in a deal
CREATE INDEX IF NOT EXISTS idx_investor_deal_part_deal
  ON investor_deal_participations(deal_id);

-- Date-based queries: participations by date range
CREATE INDEX IF NOT EXISTS idx_investor_deal_part_contrib_date
  ON investor_deal_participations(first_contribution_date);

-- Performance optimization for sequence lookups
CREATE INDEX IF NOT EXISTS idx_investor_deal_part_sequence
  ON investor_deal_participations(participation_sequence);

-- Audit trail queries
CREATE INDEX IF NOT EXISTS idx_investor_deal_part_created
  ON investor_deal_participations(created_at DESC);

-- ============================================
-- STEP 3: Create helper functions
-- ============================================

-- Function: Get investor's current deal count
CREATE OR REPLACE FUNCTION get_investor_deal_count(p_investor_id BIGINT)
RETURNS INT
LANGUAGE SQL
STABLE
AS $$
  SELECT COALESCE(MAX(participation_sequence), 0)
  FROM investor_deal_participations
  WHERE investor_id = p_investor_id;
$$;

COMMENT ON FUNCTION get_investor_deal_count(BIGINT) IS
'Returns the total number of deals an investor has participated in (max participation_sequence). Returns 0 if no participations.';

-- Function: Get investor's participation sequence for a specific deal
CREATE OR REPLACE FUNCTION get_investor_deal_sequence(p_investor_id BIGINT, p_deal_id BIGINT)
RETURNS INT
LANGUAGE SQL
STABLE
AS $$
  SELECT participation_sequence
  FROM investor_deal_participations
  WHERE investor_id = p_investor_id
    AND deal_id = p_deal_id;
$$;

COMMENT ON FUNCTION get_investor_deal_sequence(BIGINT, BIGINT) IS
'Returns the participation sequence number for a specific investor-deal combination. Returns NULL if no participation exists.';

-- Function: Get commission tier rate based on deal count
CREATE OR REPLACE FUNCTION get_commission_tier_rate(p_deal_sequence INT)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_deal_sequence = 1 THEN 150  -- 1.5% = 150 bps
    WHEN p_deal_sequence IN (2, 3) THEN 100  -- 1.0% = 100 bps
    WHEN p_deal_sequence IN (4, 5) THEN 50   -- 0.5% = 50 bps
    ELSE 0  -- No commission for deals 6+
  END;
$$;

COMMENT ON FUNCTION get_commission_tier_rate(INT) IS
'Returns the commission rate in basis points for a given deal sequence number. Tiers: Deal 1=150bps, Deals 2-3=100bps, Deals 4-5=50bps, Deals 6+=0bps.';

-- Function: Get commission tier description
CREATE OR REPLACE FUNCTION get_commission_tier_description(p_deal_sequence INT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_deal_sequence = 1 THEN 'Tier 1: First Deal (1.5%)'
    WHEN p_deal_sequence IN (2, 3) THEN 'Tier 2: Deals 2-3 (1.0%)'
    WHEN p_deal_sequence IN (4, 5) THEN 'Tier 3: Deals 4-5 (0.5%)'
    ELSE 'No Commission (Deals 6+)'
  END;
$$;

COMMENT ON FUNCTION get_commission_tier_description(INT) IS
'Returns a human-readable description of the commission tier for a given deal sequence number.';

-- ============================================
-- STEP 4: Create trigger to auto-populate participations from contributions
-- ============================================

-- Trigger function: automatically create participation record when first contribution is made
CREATE OR REPLACE FUNCTION auto_create_investor_participation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_next_sequence INT;
BEGIN
  -- Only process contributions to deals (not fund-level contributions)
  IF NEW.deal_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Check if participation already exists for this investor-deal combination
  IF EXISTS (
    SELECT 1 FROM investor_deal_participations
    WHERE investor_id = NEW.investor_id
      AND deal_id = NEW.deal_id
  ) THEN
    -- Participation already recorded, nothing to do
    RETURN NEW;
  END IF;

  -- Get next sequence number for this investor
  SELECT COALESCE(MAX(participation_sequence), 0) + 1
  INTO v_next_sequence
  FROM investor_deal_participations
  WHERE investor_id = NEW.investor_id;

  -- Create participation record
  INSERT INTO investor_deal_participations (
    investor_id,
    deal_id,
    participation_sequence,
    first_contribution_date,
    first_contribution_id,
    created_at
  ) VALUES (
    NEW.investor_id,
    NEW.deal_id,
    v_next_sequence,
    NEW.paid_in_date,
    NEW.id,
    now()
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION auto_create_investor_participation() IS
'Trigger function that automatically creates an investor_deal_participations record when an investor makes their first contribution to a deal.';

-- Create trigger on contributions table
DROP TRIGGER IF EXISTS trigger_auto_create_participation ON contributions;

CREATE TRIGGER trigger_auto_create_participation
  AFTER INSERT ON contributions
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_investor_participation();

COMMENT ON TRIGGER trigger_auto_create_participation ON contributions IS
'Automatically creates investor_deal_participations records when new contributions are inserted.';

-- ============================================
-- STEP 5: Create views for reporting
-- ============================================

-- View: Investor deal participation summary
CREATE OR REPLACE VIEW investor_participation_summary AS
SELECT
  i.id as investor_id,
  i.name as investor_name,
  COUNT(idp.id) as total_deals,
  MIN(idp.first_contribution_date) as first_participation_date,
  MAX(idp.first_contribution_date) as latest_participation_date,
  array_agg(d.name ORDER BY idp.participation_sequence) as deal_sequence,
  get_commission_tier_rate((COUNT(idp.id) + 1)::INT) as next_deal_tier_rate_bps,
  get_commission_tier_description((COUNT(idp.id) + 1)::INT) as next_deal_tier_description
FROM investors i
LEFT JOIN investor_deal_participations idp ON idp.investor_id = i.id
LEFT JOIN deals d ON d.id = idp.deal_id
GROUP BY i.id, i.name;

COMMENT ON VIEW investor_participation_summary IS
'Summary view showing each investor''s total deal count, participation dates, and what tier their next deal would fall into.';

-- View: Deal participation with tier information
CREATE OR REPLACE VIEW deal_participation_with_tiers AS
SELECT
  idp.id,
  idp.investor_id,
  i.name as investor_name,
  idp.deal_id,
  d.name as deal_name,
  idp.participation_sequence,
  get_commission_tier_rate(idp.participation_sequence) as tier_rate_bps,
  get_commission_tier_description(idp.participation_sequence) as tier_description,
  idp.first_contribution_date,
  c.amount as first_contribution_amount,
  c.currency,
  idp.created_at
FROM investor_deal_participations idp
INNER JOIN investors i ON i.id = idp.investor_id
INNER JOIN deals d ON d.id = idp.deal_id
INNER JOIN contributions c ON c.id = idp.first_contribution_id;

COMMENT ON VIEW deal_participation_with_tiers IS
'Complete view of all investor deal participations with tier information, rates, and contribution details.';

-- ============================================
-- STEP 6: Row Level Security (RLS) Policies
-- ============================================

ALTER TABLE investor_deal_participations ENABLE ROW LEVEL SECURITY;

-- Finance/Ops/Manager/Admin can read all participations
CREATE POLICY "Finance+ can read all participations"
  ON investor_deal_participations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key IN ('admin', 'finance', 'ops', 'manager')
    )
  );

-- Only Finance and Admin can manually create participations (trigger handles auto-creation)
CREATE POLICY "Finance/Admin can create participations"
  ON investor_deal_participations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key IN ('admin', 'finance')
    )
  );

-- Only Admin can update participations (should be rare - immutable by design)
CREATE POLICY "Admin can update participations"
  ON investor_deal_participations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key = 'admin'
    )
  );

-- Only Admin can delete participations (should be very rare)
CREATE POLICY "Admin can delete participations"
  ON investor_deal_participations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key = 'admin'
    )
  );

-- ============================================
-- STEP 7: Validation and integrity checks
-- ============================================

-- Function: Validate participation sequence integrity for an investor
CREATE OR REPLACE FUNCTION validate_investor_participation_sequence(p_investor_id BIGINT)
RETURNS TABLE(
  is_valid BOOLEAN,
  error_message TEXT,
  expected_sequence INT[],
  actual_sequence INT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_max_seq INT;
  v_expected INT[];
  v_actual INT[];
BEGIN
  -- Get max sequence
  SELECT COALESCE(MAX(participation_sequence), 0)
  INTO v_max_seq
  FROM investor_deal_participations
  WHERE investor_id = p_investor_id;

  -- Build expected sequence [1, 2, 3, ..., max]
  v_expected := ARRAY(SELECT generate_series(1, v_max_seq));

  -- Get actual sequence
  SELECT array_agg(participation_sequence ORDER BY participation_sequence)
  INTO v_actual
  FROM investor_deal_participations
  WHERE investor_id = p_investor_id;

  -- Check if they match
  IF v_expected = v_actual OR v_max_seq = 0 THEN
    RETURN QUERY SELECT TRUE, NULL::TEXT, v_expected, v_actual;
  ELSE
    RETURN QUERY SELECT FALSE,
      'Participation sequence has gaps or duplicates',
      v_expected,
      v_actual;
  END IF;
END;
$$;

COMMENT ON FUNCTION validate_investor_participation_sequence(BIGINT) IS
'Validates that an investor''s participation sequence is sequential with no gaps. Returns is_valid=TRUE if sequence is correct.';

-- ============================================
-- VERIFICATION QUERIES (commented out - for testing only)
-- ============================================

-- Check if table was created successfully
-- SELECT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'investor_deal_participations');

-- Check indexes
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'investor_deal_participations';

-- Check RLS policies
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'investor_deal_participations';

-- Check functions
-- SELECT proname, pg_get_functiondef(oid) FROM pg_proc WHERE proname LIKE '%investor%deal%' OR proname LIKE '%commission_tier%';

-- Check triggers
-- SELECT tgname, pg_get_triggerdef(oid) FROM pg_trigger WHERE tgrelid = 'contributions'::regclass AND tgname LIKE '%participation%';

-- ============================================
-- MIGRATION NOTES
-- ============================================

-- NEXT STEPS:
-- 1. Run this migration to create the schema
-- 2. Run the historical data initialization script to populate from existing contributions
-- 3. Test the trigger with new contributions
-- 4. Verify sequence numbers are correct
-- 5. Update commission calculation logic to use get_investor_deal_sequence()

-- ROLLBACK INSTRUCTIONS:
-- To rollback this migration (WARNING: destroys all participation data):
/*
DROP VIEW IF EXISTS deal_participation_with_tiers;
DROP VIEW IF EXISTS investor_participation_summary;
DROP TRIGGER IF EXISTS trigger_auto_create_participation ON contributions;
DROP FUNCTION IF EXISTS auto_create_investor_participation();
DROP FUNCTION IF EXISTS validate_investor_participation_sequence(BIGINT);
DROP FUNCTION IF EXISTS get_commission_tier_description(INT);
DROP FUNCTION IF EXISTS get_commission_tier_rate(INT);
DROP FUNCTION IF EXISTS get_investor_deal_sequence(BIGINT, BIGINT);
DROP FUNCTION IF EXISTS get_investor_deal_count(BIGINT);
DROP POLICY IF EXISTS "Finance+ can read all participations" ON investor_deal_participations;
DROP POLICY IF EXISTS "Finance/Admin can create participations" ON investor_deal_participations;
DROP POLICY IF EXISTS "Admin can update participations" ON investor_deal_participations;
DROP POLICY IF EXISTS "Admin can delete participations" ON investor_deal_participations;
DROP TABLE IF EXISTS investor_deal_participations CASCADE;
*/
