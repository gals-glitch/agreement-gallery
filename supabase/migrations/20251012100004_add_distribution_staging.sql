-- Migration: Add distribution_staging table for CSV import hardening
-- Feature: FEATURE_IMPORT_STAGING
-- Reversible: Yes (see down migration at bottom)

-- Distribution staging for CSV import validation
CREATE TABLE IF NOT EXISTS public.distribution_staging (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL,
  row_number integer NOT NULL,
  raw_data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'valid', 'invalid', 'committed')),
  errors text[],
  -- Resolved fields (after validation)
  investor_id uuid,
  investor_name text,
  fund_id uuid,
  fund_name text,
  deal_id uuid,
  deal_code text,
  deal_name text,
  distribution_amount numeric(18,2),
  distribution_date date,
  -- Processing metadata
  validated_at timestamptz,
  committed_at timestamptz,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_distribution_staging_batch ON public.distribution_staging(batch_id);
CREATE INDEX IF NOT EXISTS idx_distribution_staging_status ON public.distribution_staging(status);
CREATE INDEX IF NOT EXISTS idx_distribution_staging_created ON public.distribution_staging(created_at DESC);

-- Function to commit valid rows to investor_distributions
CREATE OR REPLACE FUNCTION commit_staged_distributions(
  p_batch_id uuid,
  p_calculation_run_id uuid DEFAULT NULL
)
RETURNS TABLE (
  committed_count integer,
  skipped_count integer,
  error_message text
) AS $$
DECLARE
  v_committed_count integer := 0;
  v_skipped_count integer := 0;
BEGIN
  -- Insert valid rows into investor_distributions
  INSERT INTO public.investor_distributions (
    investor_id,
    investor_name,
    fund_name,
    deal_id,
    distribution_amount,
    distribution_date,
    calculation_run_id,
    created_by
  )
  SELECT
    investor_id,
    investor_name,
    fund_name,
    deal_id,
    distribution_amount,
    distribution_date,
    p_calculation_run_id,
    created_by
  FROM public.distribution_staging
  WHERE batch_id = p_batch_id
    AND status = 'valid'
    AND committed_at IS NULL;

  GET DIAGNOSTICS v_committed_count = ROW_COUNT;

  -- Mark staged rows as committed
  UPDATE public.distribution_staging
  SET
    status = 'committed',
    committed_at = now()
  WHERE batch_id = p_batch_id
    AND status = 'valid';

  -- Count skipped rows
  SELECT COUNT(*) INTO v_skipped_count
  FROM public.distribution_staging
  WHERE batch_id = p_batch_id
    AND status IN ('invalid', 'pending');

  RETURN QUERY SELECT
    v_committed_count,
    v_skipped_count,
    NULL::text;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT
    0,
    0,
    SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE public.distribution_staging ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own staged distributions"
  ON public.distribution_staging FOR SELECT
  USING (created_by = auth.uid() OR is_admin_or_manager(auth.uid()));

CREATE POLICY "Users can insert their own staged distributions"
  ON public.distribution_staging FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update their own staged distributions"
  ON public.distribution_staging FOR UPDATE
  USING (created_by = auth.uid() OR is_admin_or_manager(auth.uid()));

CREATE POLICY "Admin can delete staged distributions"
  ON public.distribution_staging FOR DELETE
  USING (is_admin_or_manager(auth.uid()));

-- Comments for documentation
COMMENT ON TABLE public.distribution_staging IS 'Staging area for CSV distribution imports with validation. Feature: FEATURE_IMPORT_STAGING';
COMMENT ON COLUMN public.distribution_staging.batch_id IS 'Batch identifier for grouping uploaded rows';
COMMENT ON COLUMN public.distribution_staging.raw_data IS 'Original CSV row data in JSON format';
COMMENT ON COLUMN public.distribution_staging.status IS 'Status: pending (not validated), valid, invalid, committed (moved to investor_distributions)';
COMMENT ON COLUMN public.distribution_staging.errors IS 'Array of validation error messages';
COMMENT ON FUNCTION commit_staged_distributions IS 'Commits valid staged distributions to investor_distributions table';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP FUNCTION IF EXISTS commit_staged_distributions(uuid, uuid);
-- DROP TABLE IF EXISTS public.distribution_staging CASCADE;
