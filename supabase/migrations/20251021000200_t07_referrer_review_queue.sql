-- ============================================
-- T07: Referrer Review Queue Table
-- Ticket: P2 Move 2A
-- Date: 2025-10-21
--
-- Purpose:
-- Store fuzzy-matched referrer names for human review.
-- When importing investor data, referrer names are matched against parties table using fuzzy matching.
-- Matches with score 80-89 are queued for review. Matches ≥90 are auto-applied.
--
-- Workflow:
-- 1. Import service fuzzy-matches referrer name → finds suggested party
-- 2. If score ≥90: Auto-apply (update investor source fields immediately)
-- 3. If score 80-89: Queue in referrer_review_queue for admin review
-- 4. Admin reviews and resolves (approve or reject)
-- 5. On approval: Update investor source fields with resolved party_id
-- ============================================

-- Step 1: Create referrer_review_queue table
CREATE TABLE IF NOT EXISTS referrer_review_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Original referrer name from import
  referrer_name text NOT NULL,

  -- Suggested match from fuzzy resolver
  suggested_party_id integer REFERENCES parties(id) ON DELETE SET NULL,
  suggested_party_name text,
  fuzzy_score numeric(5,2) NOT NULL CHECK (fuzzy_score >= 0 AND fuzzy_score <= 100),

  -- Review status
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),

  -- Resolution details
  resolved_party_id integer REFERENCES parties(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  resolution_notes text,

  -- Link to investor (if applicable)
  investor_id integer REFERENCES investors(id) ON DELETE CASCADE,

  -- Import metadata
  import_batch_id text, -- Optional: link to CSV import batch
  import_row_number integer,

  -- Audit fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Step 2: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_referrer_review_queue_status
  ON referrer_review_queue(status)
  WHERE status = 'pending'; -- Partial index for active reviews

CREATE INDEX IF NOT EXISTS idx_referrer_review_queue_created_at
  ON referrer_review_queue(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referrer_review_queue_investor_id
  ON referrer_review_queue(investor_id)
  WHERE investor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referrer_review_queue_import_batch
  ON referrer_review_queue(import_batch_id)
  WHERE import_batch_id IS NOT NULL;

-- Step 3: Add comments
COMMENT ON TABLE referrer_review_queue IS 'Queue for manual review of fuzzy-matched referrer names (T07)';
COMMENT ON COLUMN referrer_review_queue.fuzzy_score IS 'Similarity score 0-100 from RapidFuzz matching';
COMMENT ON COLUMN referrer_review_queue.status IS 'pending: awaiting review, approved: match confirmed, rejected: match rejected';

-- Step 4: Create RLS policies (Admin and Finance only)
ALTER TABLE referrer_review_queue ENABLE ROW LEVEL SECURITY;

-- Policy: Admin and Finance can view all
CREATE POLICY referrer_review_queue_select_policy
  ON referrer_review_queue
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
        AND user_roles.role_key IN ('admin', 'finance')
    )
  );

-- Policy: Admin and Finance can update (resolve)
CREATE POLICY referrer_review_queue_update_policy
  ON referrer_review_queue
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
        AND user_roles.role_key IN ('admin', 'finance')
    )
  );

-- Policy: Service role can insert
CREATE POLICY referrer_review_queue_insert_policy
  ON referrer_review_queue
  FOR INSERT
  WITH CHECK (true); -- Allow service role to insert (import jobs)

-- Step 5: Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_referrer_review_queue_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_referrer_review_queue_timestamp ON referrer_review_queue;

CREATE TRIGGER trigger_update_referrer_review_queue_timestamp
  BEFORE UPDATE ON referrer_review_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_referrer_review_queue_timestamp();
