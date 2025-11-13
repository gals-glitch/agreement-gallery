-- STEP 1: Create Schema Helpers
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
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'investors'
      AND column_name = 'merged_into_id'
  ) THEN
    ALTER TABLE public.investors ADD COLUMN merged_into_id BIGINT NULL;
    ALTER TABLE public.investors ADD CONSTRAINT fk_investors_merged_into
      FOREIGN KEY (merged_into_id) REFERENCES public.investors(id);
  END IF;
END $$;

-- Check if is_active column exists, if not add it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'investors'
      AND column_name = 'is_active'
  ) THEN
    ALTER TABLE public.investors ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- Verify external_id unique constraint exists (from previous Vantage sync)
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
  'is_active column exists',
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='investors' AND column_name='is_active')::text
UNION ALL
SELECT
  'external_id unique constraint exists',
  EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='investors_external_id_unique')::text;
