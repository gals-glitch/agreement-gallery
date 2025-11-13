-- STEP 1: Schema helpers for safe, auditable merging
-- Creates log table and adds merged_into_id column
-- Safe to run multiple times (all IF NOT EXISTS)

-- Log table to keep an audit trail of every merge
CREATE TABLE IF NOT EXISTS public.investor_merge_log (
  id BIGSERIAL PRIMARY KEY,
  src_id BIGINT NOT NULL,
  dst_id BIGINT NOT NULL,
  reason TEXT,
  moved_fk JSONB,
  run_by TEXT DEFAULT current_user,
  run_at TIMESTAMPTZ DEFAULT now()
);

-- Soft-link so the old record points to the canonical one
ALTER TABLE public.investors
  ADD COLUMN IF NOT EXISTS merged_into_id BIGINT NULL REFERENCES public.investors(id);

-- Add is_active column if it doesn't exist (to soft-delete merged records)
-- Note: Your schema might use 'active' or 'is_active' - adjust as needed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'investors'
      AND column_name = 'active'
  ) THEN
    ALTER TABLE public.investors ADD COLUMN active BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- Verify external_id unique constraint exists (from previous Vantage sync)
-- This ensures Vantage upserts remain idempotent
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'investors_external_id_unique'
      AND table_name = 'investors'
  ) THEN
    ALTER TABLE public.investors
      ADD CONSTRAINT investors_external_id_unique UNIQUE (external_id);
  END IF;
END $$;

-- Verify schema setup
SELECT
  'investor_merge_log exists' AS check_name,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='investor_merge_log')::text AS result
UNION ALL
SELECT
  'merged_into_id column exists',
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='investors' AND column_name='merged_into_id')::text
UNION ALL
SELECT
  'active column exists',
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='investors' AND column_name='active')::text
UNION ALL
SELECT
  'external_id unique constraint exists',
  EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='investors_external_id_unique')::text;
