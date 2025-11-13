-- Manually create test commission records to verify the system works
-- This simulates what the compute API would do

BEGIN;

-- Create a commission for contribution #5 (Adam Gotskind, Avi Fried, 201 Triple Diamond)
-- Agreement 17 should have the rate details

WITH contribution_data AS (
  SELECT
    c.id as contribution_id,
    i.id as investor_id,
    i.introduced_by_party_id as party_id,
    c.deal_id,
    c.amount as contribution_amount,
    a.id as agreement_id,
    c.paid_in_date
  FROM contributions c
  JOIN investors i ON c.investor_id = i.id
  JOIN agreements a ON a.party_id = i.introduced_by_party_id
    AND a.deal_id = c.deal_id
    AND a.status = 'APPROVED'
  WHERE c.id = 5
)
INSERT INTO commissions (
  party_id,
  investor_id,
  contribution_id,
  deal_id,
  status,
  base_amount,
  vat_amount,
  total_amount,
  computation_date,
  notes
)
SELECT
  cd.party_id,
  cd.investor_id,
  cd.contribution_id,
  cd.deal_id,
  'draft',
  0.0,  -- Would be calculated based on agreement rates
  0.0,
  0.0,
  cd.paid_in_date,
  'Manual test commission'
FROM contribution_data cd;

-- Show the created commission
SELECT
  co.id,
  p.name as party_name,
  i.name as investor_name,
  c.amount as contribution_amount,
  co.base_amount,
  co.total_amount,
  co.status
FROM commissions co
JOIN parties p ON co.party_id = p.id
JOIN investors i ON co.investor_id = i.id
JOIN contributions c ON co.contribution_id = c.id
ORDER BY co.id DESC
LIMIT 5;

COMMIT;
