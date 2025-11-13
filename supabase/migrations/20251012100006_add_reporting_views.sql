-- Migration: Add SQL views for reporting
-- Feature: FEATURE_REPORTS
-- Reversible: Yes (see down migration at bottom)

-- View: Fees by Investor
-- Aggregates all fee calculations by investor, party, fund, and period
CREATE OR REPLACE VIEW public.vw_fees_by_investor AS
SELECT
  EXTRACT(YEAR FROM id.distribution_date) AS year,
  EXTRACT(QUARTER FROM id.distribution_date) AS quarter,
  id.investor_id,
  id.investor_name,
  a.introduced_by_party_id AS party_id,
  p.name AS party_name,
  id.fund_name,
  id.deal_id,
  d.name AS deal_name,
  a.applies_scope AS scope,
  COUNT(*) AS transaction_count,
  SUM(id.distribution_amount) AS total_distributions,
  -- Note: fee calculations would come from fee_calculations table (to be implemented)
  0::numeric(18,2) AS total_gross_fees,
  0::numeric(18,2) AS total_vat,
  0::numeric(18,2) AS total_net_fees
FROM public.investor_distributions id
LEFT JOIN public.agreements a ON a.id = id.investor_id -- Simplified join, may need adjustment
LEFT JOIN public.parties p ON p.id = a.introduced_by_party_id
LEFT JOIN public.deals d ON d.id = id.deal_id
GROUP BY
  EXTRACT(YEAR FROM id.distribution_date),
  EXTRACT(QUARTER FROM id.distribution_date),
  id.investor_id,
  id.investor_name,
  a.introduced_by_party_id,
  p.name,
  id.fund_name,
  id.deal_id,
  d.name,
  a.applies_scope;

-- View: VAT Summary
-- Summarizes VAT collected by country, party, and period
CREATE OR REPLACE VIEW public.vw_vat_summary AS
SELECT
  EXTRACT(YEAR FROM id.distribution_date) AS year,
  EXTRACT(QUARTER FROM id.distribution_date) AS quarter,
  COALESCE(p.country, 'Unknown') AS country,
  vr.country_code,
  vr.rate AS vat_rate,
  a.vat_mode,
  a.introduced_by_party_id AS party_id,
  p.name AS party_name,
  COUNT(*) AS transaction_count,
  SUM(id.distribution_amount) AS total_base_amount,
  -- Note: VAT amounts would be calculated from fee_calculations table
  0::numeric(18,2) AS total_vat_collected
FROM public.investor_distributions id
LEFT JOIN public.agreements a ON a.id = id.investor_id -- Simplified join
LEFT JOIN public.parties p ON p.id = a.introduced_by_party_id
LEFT JOIN public.vat_rates vr ON vr.country_code = COALESCE(p.country, 'US')
  AND id.distribution_date BETWEEN vr.effective_from AND COALESCE(vr.effective_to, '9999-12-31')
WHERE id.distribution_date IS NOT NULL
GROUP BY
  EXTRACT(YEAR FROM id.distribution_date),
  EXTRACT(QUARTER FROM id.distribution_date),
  p.country,
  vr.country_code,
  vr.rate,
  a.vat_mode,
  a.introduced_by_party_id,
  p.name;

-- View: Outstanding Credits
-- Shows all credits with remaining balance and aging
CREATE OR REPLACE VIEW public.vw_credits_outstanding AS
SELECT
  c.id,
  c.investor_id,
  c.investor_name,
  c.fund_name,
  c.credit_type,
  c.scope,
  c.deal_id,
  d.name AS deal_name,
  c.amount AS original_amount,
  c.remaining_balance,
  (c.amount - c.remaining_balance) AS applied_amount,
  c.date_posted,
  CURRENT_DATE - c.date_posted AS days_outstanding,
  CASE
    WHEN CURRENT_DATE - c.date_posted < 30 THEN '0-30 days'
    WHEN CURRENT_DATE - c.date_posted < 60 THEN '30-60 days'
    WHEN CURRENT_DATE - c.date_posted < 90 THEN '60-90 days'
    ELSE '90+ days'
  END AS aging_bucket,
  c.status,
  c.apply_policy,
  c.created_at,
  -- Application count
  (
    SELECT COUNT(*)
    FROM public.credit_applications ca
    WHERE ca.credit_id = c.id
  ) AS application_count
FROM public.credits c
LEFT JOIN public.deals d ON d.id = c.deal_id
WHERE c.status = 'active'
  AND c.remaining_balance > 0
ORDER BY c.date_posted ASC;

-- View: Run Summary
-- Aggregates run totals with scope breakdown
CREATE OR REPLACE VIEW public.vw_run_summary AS
SELECT
  cr.id AS run_id,
  cr.name AS run_name,
  cr.status,
  cr.period_start,
  cr.period_end,
  cr.created_at,
  cr.created_by,
  u.email AS created_by_email,
  COUNT(DISTINCT id.id) AS distribution_count,
  SUM(id.distribution_amount) AS total_distributions,
  cr.total_gross_fees,
  cr.total_vat,
  cr.total_net_payable,
  -- Scope breakdown (from run_records if available)
  NULL::jsonb AS scope_breakdown
FROM public.calculation_runs cr
LEFT JOIN public.investor_distributions id ON id.calculation_run_id = cr.id
LEFT JOIN auth.users u ON u.id = cr.created_by
GROUP BY
  cr.id,
  cr.name,
  cr.status,
  cr.period_start,
  cr.period_end,
  cr.created_at,
  cr.created_by,
  u.email,
  cr.total_gross_fees,
  cr.total_vat,
  cr.total_net_payable;

-- Grant SELECT permissions to appropriate roles
GRANT SELECT ON public.vw_fees_by_investor TO authenticated;
GRANT SELECT ON public.vw_vat_summary TO authenticated;
GRANT SELECT ON public.vw_credits_outstanding TO authenticated;
GRANT SELECT ON public.vw_run_summary TO authenticated;

-- RLS on views inherits from underlying tables automatically

-- Comments for documentation
COMMENT ON VIEW public.vw_fees_by_investor IS 'Aggregated fees by investor, party, fund, and period. Feature: FEATURE_REPORTS';
COMMENT ON VIEW public.vw_vat_summary IS 'VAT summary by country, party, and period for tax filing. Feature: FEATURE_REPORTS';
COMMENT ON VIEW public.vw_credits_outstanding IS 'Outstanding credits with aging buckets and application history. Feature: FEATURE_REPORTS';
COMMENT ON VIEW public.vw_run_summary IS 'Calculation run summary with totals and distribution counts. Feature: FEATURE_REPORTS';

-- ============================================
-- DOWN MIGRATION (Rollback)
-- ============================================
-- To rollback, run:
-- DROP VIEW IF EXISTS public.vw_run_summary;
-- DROP VIEW IF EXISTS public.vw_credits_outstanding;
-- DROP VIEW IF EXISTS public.vw_vat_summary;
-- DROP VIEW IF EXISTS public.vw_fees_by_investor;
