-- Drop existing overly permissive RLS policies
DROP POLICY IF EXISTS "Authenticated users can access activity log" ON activity_log;
DROP POLICY IF EXISTS "Authenticated users can access advanced calculations" ON advanced_commission_calculations;
DROP POLICY IF EXISTS "Authenticated users can access advanced commission rules" ON advanced_commission_rules;
DROP POLICY IF EXISTS "Authenticated users can access calculation runs" ON calculation_runs;
DROP POLICY IF EXISTS "Authenticated users can access calculation traces" ON calculation_traces;
DROP POLICY IF EXISTS "Authenticated users can access commission tiers" ON commission_tiers;
DROP POLICY IF EXISTS "Authenticated users can access credit applications" ON credit_applications;
DROP POLICY IF EXISTS "Authenticated users can access credits" ON credits;
DROP POLICY IF EXISTS "Authenticated users can access discounts" ON discounts;
DROP POLICY IF EXISTS "Authenticated users can access distributor rules" ON distributor_rules;
DROP POLICY IF EXISTS "Authenticated users can access entities" ON entities;
DROP POLICY IF EXISTS "Authenticated users can access investor distributions" ON investor_distributions;
DROP POLICY IF EXISTS "Authenticated users can access notification emails" ON notification_emails;
DROP POLICY IF EXISTS "Authenticated users can access rule conditions" ON rule_conditions;
DROP POLICY IF EXISTS "Authenticated users can access rule execution history" ON rule_execution_history;
DROP POLICY IF EXISTS "Authenticated users can access sub agents" ON sub_agents;
DROP POLICY IF EXISTS "Authenticated users can access workflow approvals" ON workflow_approvals;

-- Drop existing entity policies
DROP POLICY IF EXISTS "Authenticated users can create entities" ON entities;
DROP POLICY IF EXISTS "Authenticated users can delete entities" ON entities;
DROP POLICY IF EXISTS "Authenticated users can update entities" ON entities;
DROP POLICY IF EXISTS "Authenticated users can view entities" ON entities;

-- Create user roles system
CREATE TYPE IF NOT EXISTS public.app_role AS ENUM ('admin', 'manager', 'user');

-- Create user_roles table for proper access control
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role app_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, role)
);

-- Enable RLS on user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create security definer function to check user roles
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Create function to check if user is admin or manager
CREATE OR REPLACE FUNCTION public.is_admin_or_manager(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role IN ('admin', 'manager')
  )
$$;

-- Create RLS policy for user_roles table
CREATE POLICY "Users can view their own roles" ON public.user_roles
FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all roles" ON public.user_roles
FOR ALL USING (public.has_role(auth.uid(), 'admin'));

-- Create secure RLS policies for financial tables
-- Activity Log - Admin/Manager access only
CREATE POLICY "Admin/Manager can access activity log" ON public.activity_log
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Advanced Commission Calculations - Admin/Manager access only
CREATE POLICY "Admin/Manager can access commission calculations" ON public.advanced_commission_calculations
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Advanced Commission Rules - Admin/Manager access only
CREATE POLICY "Admin/Manager can access commission rules" ON public.advanced_commission_rules
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Calculation Runs - Admin/Manager access only
CREATE POLICY "Admin/Manager can access calculation runs" ON public.calculation_runs
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Calculation Traces - Admin/Manager access only
CREATE POLICY "Admin/Manager can access calculation traces" ON public.calculation_traces
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Commission Tiers - Admin/Manager access only
CREATE POLICY "Admin/Manager can access commission tiers" ON public.commission_tiers
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Credit Applications - Admin/Manager access only
CREATE POLICY "Admin/Manager can access credit applications" ON public.credit_applications
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Credits - Admin/Manager access only
CREATE POLICY "Admin/Manager can access credits" ON public.credits
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Discounts - Admin/Manager access only
CREATE POLICY "Admin/Manager can access discounts" ON public.discounts
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Distributor Rules - Admin/Manager access only
CREATE POLICY "Admin/Manager can access distributor rules" ON public.distributor_rules
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Entities - Admin/Manager access only (contains sensitive PII)
CREATE POLICY "Admin/Manager can access entities" ON public.entities
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Investor Distributions - Admin/Manager access only
CREATE POLICY "Admin/Manager can access investor distributions" ON public.investor_distributions
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Notification Emails - Admin/Manager access only
CREATE POLICY "Admin/Manager can access notification emails" ON public.notification_emails
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Rule Conditions - Admin/Manager access only
CREATE POLICY "Admin/Manager can access rule conditions" ON public.rule_conditions
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Rule Execution History - Admin/Manager access only
CREATE POLICY "Admin/Manager can access rule execution history" ON public.rule_execution_history
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Sub Agents - Admin/Manager access only (contains email addresses)
CREATE POLICY "Admin/Manager can access sub agents" ON public.sub_agents
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Workflow Approvals - Admin/Manager access only
CREATE POLICY "Admin/Manager can access workflow approvals" ON public.workflow_approvals
FOR ALL USING (public.is_admin_or_manager(auth.uid()));

-- Insert a default admin user (you'll need to replace this with your actual user ID)
-- This is commented out - you'll need to get your user ID from auth.users and insert manually
-- INSERT INTO public.user_roles (user_id, role) VALUES ('your-user-id-here', 'admin');