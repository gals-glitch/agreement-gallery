-- Migration: Add workflow_approvals table for approval workflow
-- Feature: FEATURE_APPROVALS
-- Reversible: Yes (see down migration at bottom)

-- Create workflow_approvals table
CREATE TABLE IF NOT EXISTS public.workflow_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES public.calculation_runs(id) ON DELETE CASCADE,
  step text NOT NULL CHECK (step IN ('ops_review', 'finance_review', 'final_approval')),
  approver_role text NOT NULL CHECK (approver_role IN ('ops', 'finance', 'manager', 'admin')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  comment text,
  acted_by uuid REFERENCES auth.users(id),
  acted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_workflow_approvals_run_id ON public.workflow_approvals(run_id);
CREATE INDEX IF NOT EXISTS idx_workflow_approvals_status ON public.workflow_approvals(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_workflow_approvals_step ON public.workflow_approvals(step, status);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_workflow_approvals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workflow_approvals_updated_at
  BEFORE UPDATE ON public.workflow_approvals
  FOR EACH ROW
  EXECUTE FUNCTION update_workflow_approvals_updated_at();

-- Enable RLS
ALTER TABLE public.workflow_approvals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admin and managers can view all approvals"
  ON public.workflow_approvals FOR SELECT
  USING (is_admin_or_manager(auth.uid()));

CREATE POLICY "Users can view approvals for their runs"
  ON public.workflow_approvals FOR SELECT
  USING (
    run_id IN (
      SELECT id FROM public.calculation_runs WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Admin and managers can create approvals"
  ON public.workflow_approvals FOR INSERT
  WITH CHECK (is_admin_or_manager(auth.uid()));

CREATE POLICY "Users with appropriate role can update their step approvals"
  ON public.workflow_approvals FOR UPDATE
  USING (
    (approver_role = 'ops' AND has_role(auth.uid(), 'ops')) OR
    (approver_role = 'finance' AND has_role(auth.uid(), 'finance')) OR
    (approver_role = 'manager' AND has_role(auth.uid(), 'manager')) OR
    (approver_role = 'admin' AND has_role(auth.uid(), 'admin'))
  );

-- Add new statuses to calculation_runs (non-breaking)
-- Only add if not exists (idempotent)
DO $$
BEGIN
  -- Check if constraint exists and drop it
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'calculation_runs_status_check'
    AND table_name = 'calculation_runs'
  ) THEN
    ALTER TABLE public.calculation_runs DROP CONSTRAINT calculation_runs_status_check;
  END IF;

  -- Add new constraint with additional statuses
  ALTER TABLE public.calculation_runs ADD CONSTRAINT calculation_runs_status_check
    CHECK (status IN ('draft', 'in_progress', 'awaiting_approval', 'approved', 'completed', 'failed', 'invoiced'));
END $$;

-- Comment for documentation
COMMENT ON TABLE public.workflow_approvals IS 'Approval workflow tracking for calculation runs. Feature: FEATURE_APPROVALS';
COMMENT ON COLUMN public.workflow_approvals.step IS 'Approval step: ops_review, finance_review, or final_approval';
COMMENT ON COLUMN public.workflow_approvals.approver_role IS 'Role required to approve this step';
COMMENT ON COLUMN public.workflow_approvals.status IS 'Status: pending, approved, or rejected';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP TRIGGER IF EXISTS workflow_approvals_updated_at ON public.workflow_approvals;
-- DROP FUNCTION IF EXISTS update_workflow_approvals_updated_at();
-- DROP TABLE IF EXISTS public.workflow_approvals CASCADE;
--
-- -- Restore original status constraint
-- ALTER TABLE public.calculation_runs DROP CONSTRAINT IF EXISTS calculation_runs_status_check;
-- ALTER TABLE public.calculation_runs ADD CONSTRAINT calculation_runs_status_check
--   CHECK (status IN ('draft', 'in_progress', 'completed', 'failed'));
