-- ============================================
-- Verification: Ready-to-compute contributions
-- ============================================
-- Run this after DB-01 or IMP-01 to see how many
-- contributions are now eligible for commission computation

WITH eligible AS (
  SELECT
    c.id,
    c.amount,
    i.name AS investor_name,
    p.name AS party_name,
    d.name AS deal_name
  FROM contributions c
  JOIN investors i ON i.id = c.investor_id
  JOIN parties p ON p.id = i.introduced_by_party_id  -- Has party link
  JOIN deals d ON d.id = c.deal_id
  JOIN agreements a ON a.party_id = i.introduced_by_party_id
                   AND a.deal_id = c.deal_id
                   AND a.status = 'APPROVED'  -- Has approved agreement
  LEFT JOIN commissions m ON m.contribution_id = c.id
  WHERE m.id IS NULL  -- No commission created yet
)
SELECT
  COUNT(*) AS ready_to_compute,
  COUNT(DISTINCT investor_name) AS unique_investors,
  COUNT(DISTINCT party_name) AS unique_parties,
  SUM(amount) AS total_potential_contribution_value
FROM eligible;

-- Optional: Show first 10 eligible contributions
-- SELECT * FROM eligible ORDER BY amount DESC LIMIT 10;
