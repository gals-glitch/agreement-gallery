-- Create storage bucket for agreement PDFs
INSERT INTO storage.buckets (id, name, public) VALUES ('agreements', 'agreements', false);

-- Create RLS policies for agreement PDFs
CREATE POLICY "Authenticated users can view agreement files" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'agreements' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload agreement files" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'agreements' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update agreement files" 
ON storage.objects 
FOR UPDATE 
USING (bucket_id = 'agreements' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete agreement files" 
ON storage.objects 
FOR DELETE 
USING (bucket_id = 'agreements' AND auth.role() = 'authenticated');

-- Add PDF file path to advanced_commission_rules table
ALTER TABLE advanced_commission_rules ADD COLUMN pdf_file_path text;

-- Add VAT mode and related fields for PRD compliance
ALTER TABLE advanced_commission_rules ADD COLUMN vat_mode text CHECK (vat_mode IN ('included', 'added')) DEFAULT 'added';
ALTER TABLE advanced_commission_rules ADD COLUMN vat_rate_table text DEFAULT 'IL_STANDARD';
ALTER TABLE advanced_commission_rules ADD COLUMN currency text DEFAULT 'USD';
ALTER TABLE advanced_commission_rules ADD COLUMN timing_mode text CHECK (timing_mode IN ('immediate', 'quarterly', 'on_event')) DEFAULT 'quarterly';
ALTER TABLE advanced_commission_rules ADD COLUMN lag_days integer DEFAULT 30;

-- Create credits table for repurchase and equalisation credits per PRD
CREATE TABLE public.credits (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    investor_id uuid NOT NULL,
    investor_name text NOT NULL,
    fund_name text,
    credit_type text NOT NULL CHECK (credit_type IN ('repurchase', 'equalisation')),
    amount numeric NOT NULL,
    remaining_balance numeric NOT NULL DEFAULT 0,
    currency text DEFAULT 'USD',
    date_posted date NOT NULL,
    status text DEFAULT 'active' CHECK (status IN ('active', 'exhausted', 'cancelled')),
    apply_policy text DEFAULT 'net_against_future_payables',
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS on credits table
ALTER TABLE public.credits ENABLE ROW LEVEL SECURITY;

-- Create policy for credits access
CREATE POLICY "Authenticated users can access credits" 
ON public.credits 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Create credit applications table to track how credits are applied
CREATE TABLE public.credit_applications (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    credit_id uuid NOT NULL REFERENCES public.credits(id) ON DELETE CASCADE,
    calculation_run_id uuid REFERENCES public.calculation_runs(id),
    distribution_id uuid REFERENCES public.investor_distributions(id),
    applied_amount numeric NOT NULL,
    applied_date date NOT NULL DEFAULT CURRENT_DATE,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS on credit applications
ALTER TABLE public.credit_applications ENABLE ROW LEVEL SECURITY;

-- Create policy for credit applications
CREATE POLICY "Authenticated users can access credit applications" 
ON public.credit_applications 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Add triggers for updated_at
CREATE TRIGGER update_credits_updated_at
BEFORE UPDATE ON public.credits
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();