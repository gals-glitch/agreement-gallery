-- Add sub-agents table
CREATE TABLE public.sub_agents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  distributor_id UUID NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  split_percentage NUMERIC(5,2) NOT NULL CHECK (split_percentage >= 0 AND split_percentage <= 100),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add discounts table
CREATE TABLE public.discounts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_name TEXT NOT NULL,
  fund_name TEXT NOT NULL,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('Management-Fee', 'Performance-Fee', 'Other')),
  amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  percentage NUMERIC(5,2),
  is_refunded_via_distributions BOOLEAN NOT NULL DEFAULT false,
  effective_date DATE NOT NULL,
  expiry_date DATE,
  status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Expired', 'Pending')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID
);

-- Add calculation traces table
CREATE TABLE public.calculation_traces (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  calculation_id UUID NOT NULL,
  rule_id UUID,
  input_data JSONB NOT NULL,
  formula_used TEXT NOT NULL,
  calculation_result JSONB NOT NULL,
  execution_order INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add workflow approvals table
CREATE TABLE public.workflow_approvals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('rule', 'calculation_run', 'discount')),
  entity_id UUID NOT NULL,
  approval_type TEXT NOT NULL CHECK (approval_type IN ('create', 'update', 'delete')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_by UUID,
  approved_by UUID,
  rejection_reason TEXT,
  requires_two_person_approval BOOLEAN NOT NULL DEFAULT false,
  first_approver UUID,
  second_approver UUID,
  requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  approved_at TIMESTAMP WITH TIME ZONE,
  entity_data JSONB
);

-- Add activity log table
CREATE TABLE public.activity_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('create', 'update', 'delete', 'approve', 'reject')),
  description TEXT NOT NULL,
  old_values JSONB,
  new_values JSONB,
  performed_by UUID,
  performed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add multiple rules per distributor support
CREATE TABLE public.distributor_rules (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  distributor_id UUID NOT NULL,
  rule_id UUID NOT NULL,
  priority INTEGER NOT NULL DEFAULT 100,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(distributor_id, rule_id)
);

-- Add notification emails table
CREATE TABLE public.notification_emails (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  entity_id UUID NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('distributor', 'sub_agent')),
  email TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on all new tables
ALTER TABLE public.sub_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calculation_traces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.distributor_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_emails ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for authenticated users
CREATE POLICY "Authenticated users can access sub agents"
ON public.sub_agents FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access discounts"
ON public.discounts FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access calculation traces"
ON public.calculation_traces FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access workflow approvals"
ON public.workflow_approvals FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access activity log"
ON public.activity_log FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access distributor rules"
ON public.distributor_rules FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can access notification emails"
ON public.notification_emails FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Add triggers for updated_at columns
CREATE TRIGGER update_sub_agents_updated_at
BEFORE UPDATE ON public.sub_agents
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_discounts_updated_at
BEFORE UPDATE ON public.discounts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add indexes for better performance
CREATE INDEX idx_sub_agents_distributor_id ON public.sub_agents(distributor_id);
CREATE INDEX idx_discounts_investor_fund ON public.discounts(investor_name, fund_name);
CREATE INDEX idx_calculation_traces_calculation_id ON public.calculation_traces(calculation_id);
CREATE INDEX idx_workflow_approvals_entity ON public.workflow_approvals(entity_type, entity_id);
CREATE INDEX idx_activity_log_entity ON public.activity_log(entity_type, entity_id);
CREATE INDEX idx_distributor_rules_distributor ON public.distributor_rules(distributor_id);
CREATE INDEX idx_notification_emails_entity ON public.notification_emails(entity_type, entity_id);