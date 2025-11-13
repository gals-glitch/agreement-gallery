-- COV-01: Default Agreement Seeder
-- ================================================================
-- Creates default agreements for party-deal pairs that have
-- contributions but no agreement, enabling commission computation
--
-- Default Terms:
-- - Pricing Mode: TIERED
-- - Upfront: 100 bps (1.0%)
-- - Deferred: 0 bps (0.0%)
-- - VAT: 17% (current Israeli rate)
-- - Status: active
--
-- Impact:
-- - Enables commission calculation for previously unmatched contributions
-- - Increases demo/testing data visibility
-- - Provides baseline agreements that can be edited later
-- ================================================================

BEGIN;

-- Insert default agreements for party-deal pairs with contributions but no agreement
INSERT INTO agreements (
  party_id,
  deal_id,
  pricing_mode,
  upfront_bps,
  deferred_bps,
  vat_policy_id,
  snapshot_json,
  status
)
SELECT DISTINCT
  c.party_id,
  c.deal_id,
  'TIERED' as pricing_mode,
  100 as upfront_bps,
  0 as deferred_bps,
  (SELECT id FROM vat_policies WHERE rate = 0.17 ORDER BY effective_from DESC LIMIT 1) as vat_policy_id,
  jsonb_build_object(
    'resolved_upfront_bps', 100,
    'resolved_deferred_bps', 0,
    'vat_rate', 0.17
  ) as snapshot_json,
  'active' as status
FROM contributions c
WHERE NOT EXISTS (
  SELECT 1
  FROM agreements a
  WHERE a.party_id = c.party_id
    AND a.deal_id = c.deal_id
)
AND c.party_id IS NOT NULL
AND c.deal_id IS NOT NULL;

COMMIT;

-- Report: How many agreements were created?
SELECT
  'Default Agreements Created' as action,
  COUNT(*) as count
FROM agreements
WHERE upfront_bps = 100
  AND deferred_bps = 0
  AND pricing_mode = 'TIERED';

-- Show sample of newly created agreements
SELECT
  a.id as agreement_id,
  a.party_id,
  p.name as party_name,
  a.deal_id,
  d.name as deal_name,
  a.upfront_bps,
  a.deferred_bps,
  a.vat_policy_id,
  a.status
FROM agreements a
JOIN parties p ON a.party_id = p.id
JOIN deals d ON a.deal_id = d.id
WHERE a.upfront_bps = 100
  AND a.deferred_bps = 0
  AND a.pricing_mode = 'TIERED'
ORDER BY a.id DESC
LIMIT 10;

-- Check: How many party-deal pairs now have agreements vs contributions?
SELECT
  (SELECT COUNT(DISTINCT (party_id, deal_id)) FROM contributions WHERE party_id IS NOT NULL AND deal_id IS NOT NULL) as total_contribution_pairs,
  (SELECT COUNT(*) FROM agreements) as total_agreements,
  (SELECT COUNT(DISTINCT (party_id, deal_id)) FROM contributions WHERE party_id IS NOT NULL AND deal_id IS NOT NULL) -
  (SELECT COUNT(*) FROM agreements) as remaining_gaps;
