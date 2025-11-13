-- scripts/cov01_seed_missing_agreements.sql
-- COV-01: Seed Missing Agreements (Coverage Booster)
-- Creates default 100 bps agreements for party-deal pairs with contributions but no agreement
-- Run AFTER gateA_close_gaps.sql to maximize commission computation coverage

BEGIN;

-- Find party-deal combinations that:
--   1. Have ≥1 contribution
--   2. Investor has party link
--   3. No approved agreement exists
-- Create draft agreements (admin must approve before use)

WITH gaps AS (
  SELECT
    i.introduced_by_party_id AS party_id,
    c.deal_id,
    MIN(c.paid_in_date) AS earliest_contribution_date,
    COUNT(c.id) AS blocked_contributions,
    SUM(c.amount) AS total_blocked_amount
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id
  LEFT JOIN agreements a ON a.party_id = i.introduced_by_party_id
                        AND a.deal_id = c.deal_id
                        AND a.status = 'APPROVED'
  WHERE i.introduced_by_party_id IS NOT NULL  -- Has party link
    AND a.id IS NULL  -- No approved agreement
  GROUP BY i.introduced_by_party_id, c.deal_id
  HAVING COUNT(c.id) >= 1  -- At least 1 contribution
)
INSERT INTO agreements (
  party_id,
  scope,
  deal_id,
  kind,
  pricing_mode,
  status,
  effective_from,
  effective_to,
  snapshot_json
)
SELECT
  g.party_id,
  'DEAL',  -- Scope: agreement applies to specific deal
  g.deal_id,
  'investor_fee',  -- Kind: investor fee agreement
  'CUSTOM',
  'DRAFT',  -- Must be approved by admin before use
  g.earliest_contribution_date,
  NULL,  -- Open-ended
  jsonb_build_object(
    'rate_bps', 100,
    'vat_mode', 'on_top',
    'vat_rate', 0.17,
    'auto_seeded', true,
    'seeded_at', NOW(),
    'blocked_contributions', g.blocked_contributions,
    'total_blocked_amount', g.total_blocked_amount,
    'notes', 'Auto-seeded default agreement (100 bps + 17% VAT). Review and approve to enable commission computation.'
  )
FROM gaps g
WHERE NOT EXISTS (
  -- Double-check no agreement exists (including drafts)
  SELECT 1 FROM agreements a2
  WHERE a2.party_id = g.party_id
    AND a2.deal_id = g.deal_id
);

-- Insert custom terms for the newly created agreements
INSERT INTO agreement_custom_terms (
  agreement_id,
  upfront_bps,
  deferred_bps,
  caps_json,
  tiers_json
)
SELECT
  a.id,
  100,  -- 100 bps (1.0%) upfront
  0,    -- 0 bps deferred
  NULL, -- No caps
  NULL  -- No tiers (flat rate)
FROM agreements a
WHERE a.snapshot_json->>'auto_seeded' = 'true'
  AND a.created_at >= NOW() - INTERVAL '1 minute'
  AND NOT EXISTS (
    SELECT 1 FROM agreement_custom_terms act
    WHERE act.agreement_id = a.id
  );

-- Report what was created
SELECT
  COUNT(*) AS agreements_created,
  SUM((snapshot_json->>'blocked_contributions')::int) AS contributions_now_eligible,
  SUM((snapshot_json->>'total_blocked_amount')::decimal) AS total_value_unblocked
FROM agreements
WHERE snapshot_json->>'auto_seeded' = 'true'
  AND created_at >= NOW() - INTERVAL '1 minute';

COMMIT;

-- Verification query: Show newly seeded agreements
-- Uncomment to see what was created:
/*
SELECT
  a.id,
  p.name AS party_name,
  d.name AS deal_name,
  a.status,
  a.snapshot_json->>'blocked_contributions' AS contributions,
  a.snapshot_json->>'total_blocked_amount' AS amount,
  a.effective_from
FROM agreements a
JOIN parties p ON p.id = a.party_id
JOIN deals d ON d.id = a.deal_id
WHERE a.snapshot_json->>'auto_seeded' = 'true'
  AND a.created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY (a.snapshot_json->>'blocked_contributions')::int DESC
LIMIT 20;
*/

-- Next steps after running:
-- 1. Review seeded agreements in admin UI
-- 2. Approve those that should use 100 bps rate
-- 3. Delete or modify those needing different terms
-- 4. Run batch compute to create commissions
