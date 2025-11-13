-- =============================================================================
-- Find Investors with Contributions
-- Purpose: Identify investors who have existing contributions for testing
-- Date: 2025-11-11
-- =============================================================================

-- Basic query: Show investors with contributions
SELECT
  i.id,
  i.name,
  i.source_kind,
  i.introduced_by_party_id,
  COUNT(c.id) as contribution_count,
  SUM(c.amount) as total_contributed,
  MIN(c.paid_in_date) as first_contribution,
  MAX(c.paid_in_date) as last_contribution
FROM investors i
INNER JOIN contributions c ON c.investor_id = i.id
GROUP BY i.id, i.name, i.source_kind, i.introduced_by_party_id
HAVING COUNT(c.id) > 0
ORDER BY contribution_count DESC
LIMIT 20;

-- =============================================================================
-- Alternative: Show investors WITHOUT distributors assigned (good test candidates)
-- =============================================================================

-- SELECT
--   i.id,
--   i.name,
--   i.source_kind,
--   COUNT(c.id) as contribution_count,
--   SUM(c.amount) as total_contributed
-- FROM investors i
-- INNER JOIN contributions c ON c.investor_id = i.id
-- WHERE i.source_kind != 'DISTRIBUTOR'
--    OR i.introduced_by_party_id IS NULL
-- GROUP BY i.id, i.name, i.source_kind
-- HAVING COUNT(c.id) > 0
-- ORDER BY contribution_count DESC
-- LIMIT 10;

-- =============================================================================
-- Alternative: Show contributions by investor (detailed view)
-- =============================================================================

-- SELECT
--   i.id as investor_id,
--   i.name as investor_name,
--   c.id as contribution_id,
--   c.amount,
--   c.paid_in_date,
--   f.name as fund_name,
--   d.name as deal_name
-- FROM investors i
-- INNER JOIN contributions c ON c.investor_id = i.id
-- LEFT JOIN funds f ON f.id = c.fund_id
-- LEFT JOIN deals d ON d.id = c.deal_id
-- WHERE i.id = 3105  -- Replace with specific investor ID
-- ORDER BY c.paid_in_date DESC;
