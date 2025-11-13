# OP-05: Staging Data Seeding for Pilot

**Owner:** orchestrator-pm
**Status:** APPROVED
**Last Updated:** 2025-10-21

---

## Staging Data Requirements

This document provides complete SQL scripts to seed staging database with realistic test data for v1.8.0 pilot validation.

### Test Data Overview

| Entity | Count | Details |
|--------|-------|---------|
| Investors | 5 | 3 individuals, 2 entities |
| Distributors | 1 | Referrer for fuzzy matching tests |
| Agreements | 5 | All APPROVED with snapshot_json |
| Contributions | 6 | 3 fund-scoped, 3 deal-scoped |
| Credits | 3 | Various amounts, fund/deal scoped |
| Expected Charges | 6 | All DRAFT status initially |

---

## Seed SQL Script

**File:** `pm/v1.8.0/staging-seed.sql`

```sql
-- ============================================================================
-- v1.8.0 Staging Data Seed Script
-- ============================================================================
-- Purpose: Seed staging database with test data for pilot validation
-- Prerequisites:
--   - Clean staging database (or use reset script first)
--   - funds table has at least 2 funds (fund_id 1, 2)
--   - deals table has at least 1 deal (deal_id 1)
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTIES (Investors and Distributor)
-- ============================================================================

-- Individual Investors (3)
INSERT INTO parties (id, party_type, full_name, legal_name, email, created_at, updated_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'INDIVIDUAL', 'John Smith', 'John Smith', 'john.smith@test.com', NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'INDIVIDUAL', 'Jane Doe', 'Jane Doe', 'jane.doe@test.com', NOW(), NOW()),
  ('55555555-5555-5555-5555-555555555555', 'INDIVIDUAL', 'Test Investor', 'Test Investor', 'test.investor@test.com', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Entity Investors (2)
INSERT INTO parties (id, party_type, full_name, legal_name, email, created_at, updated_at)
VALUES
  ('33333333-3333-3333-3333-333333333333', 'ENTITY', 'ACME Corp', 'ACME Corporation Ltd', 'contact@acme.com', NOW(), NOW()),
  ('44444444-4444-4444-4444-444444444444', 'ENTITY', 'Smith Family Trust', 'Smith Family Trust', 'trustee@smithfamily.com', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Distributor (Referrer)
INSERT INTO parties (id, party_type, full_name, legal_name, email, created_at, updated_at)
VALUES
  ('66666666-6666-6666-6666-666666666666', 'DISTRIBUTOR', 'Bob Referrer', 'Bob Referrer', 'bob.referrer@test.com', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- AGREEMENTS (5 total, all APPROVED with snapshot_json)
-- ============================================================================

-- Agreement 1: John Smith (fund-scoped)
INSERT INTO agreements (id, investor_party_id, fund_id, deal_id, status, snapshot_json, created_at, updated_at, approved_at)
VALUES
  ('a1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id (fund-scoped)
   'APPROVED',
   '{"pricing": {"upfront_bps": 100, "deferred_bps": 0, "vat_rate": 0.20}}',
   NOW() - INTERVAL '60 days',
   NOW() - INTERVAL '30 days',
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- Agreement 2: Jane Doe (deal-scoped)
INSERT INTO agreements (id, investor_party_id, fund_id, deal_id, status, snapshot_json, created_at, updated_at, approved_at)
VALUES
  ('a2222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   NULL,  -- fund_id (deal-scoped)
   1,  -- deal_id
   'APPROVED',
   '{"pricing": {"upfront_bps": 100, "deferred_bps": 0, "vat_rate": 0.20}}',
   NOW() - INTERVAL '60 days',
   NOW() - INTERVAL '30 days',
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- Agreement 3: ACME Corp (fund-scoped)
INSERT INTO agreements (id, investor_party_id, fund_id, deal_id, status, snapshot_json, created_at, updated_at, approved_at)
VALUES
  ('a3333333-3333-3333-3333-333333333333',
   '33333333-3333-3333-3333-333333333333',
   2,  -- fund_id
   NULL,  -- deal_id (fund-scoped)
   'APPROVED',
   '{"pricing": {"upfront_bps": 100, "deferred_bps": 0, "vat_rate": 0.20}}',
   NOW() - INTERVAL '60 days',
   NOW() - INTERVAL '30 days',
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- Agreement 4: Smith Family Trust (deal-scoped)
INSERT INTO agreements (id, investor_party_id, fund_id, deal_id, status, snapshot_json, created_at, updated_at, approved_at)
VALUES
  ('a4444444-4444-4444-4444-444444444444',
   '44444444-4444-4444-4444-444444444444',
   NULL,  -- fund_id (deal-scoped)
   1,  -- deal_id
   'APPROVED',
   '{"pricing": {"upfront_bps": 100, "deferred_bps": 0, "vat_rate": 0.20}}',
   NOW() - INTERVAL '60 days',
   NOW() - INTERVAL '30 days',
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- Agreement 5: Test Investor (fund-scoped)
INSERT INTO agreements (id, investor_party_id, fund_id, deal_id, status, snapshot_json, created_at, updated_at, approved_at)
VALUES
  ('a5555555-5555-5555-5555-555555555555',
   '55555555-5555-5555-5555-555555555555',
   1,  -- fund_id
   NULL,  -- deal_id (fund-scoped)
   'APPROVED',
   '{"pricing": {"upfront_bps": 100, "deferred_bps": 0, "vat_rate": 0.20}}',
   NOW() - INTERVAL '60 days',
   NOW() - INTERVAL '30 days',
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- CONTRIBUTIONS (6 total: 3 fund-scoped, 3 deal-scoped)
-- ============================================================================

-- Contribution 1: John Smith, $50,000 (fund-scoped, with referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c1111111-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id
   50000.00,
   'USD',
   NOW() - INTERVAL '25 days',
   '66666666-6666-6666-6666-666666666666',  -- Bob Referrer (for testing)
   NOW() - INTERVAL '25 days',
   NOW() - INTERVAL '25 days')
ON CONFLICT (id) DO NOTHING;

-- Contribution 2: John Smith, $25,000 (fund-scoped, with referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c1111112-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id
   25000.00,
   'USD',
   NOW() - INTERVAL '20 days',
   '66666666-6666-6666-6666-666666666666',  -- Bob Referrer
   NOW() - INTERVAL '20 days',
   NOW() - INTERVAL '20 days')
ON CONFLICT (id) DO NOTHING;

-- Contribution 3: Jane Doe, $100,000 (deal-scoped, with referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c2222222-2222-2222-2222-222222222222',
   'a2222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   NULL,  -- fund_id
   1,  -- deal_id
   100000.00,
   'USD',
   NOW() - INTERVAL '15 days',
   '66666666-6666-6666-6666-666666666666',  -- Bob Referrer
   NOW() - INTERVAL '15 days',
   NOW() - INTERVAL '15 days')
ON CONFLICT (id) DO NOTHING;

-- Contribution 4: ACME Corp, $250,000 (fund-scoped, no referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c3333333-3333-3333-3333-333333333333',
   'a3333333-3333-3333-3333-333333333333',
   '33333333-3333-3333-3333-333333333333',
   2,  -- fund_id
   NULL,  -- deal_id
   250000.00,
   'USD',
   NOW() - INTERVAL '10 days',
   NULL,  -- No referrer
   NOW() - INTERVAL '10 days',
   NOW() - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;

-- Contribution 5: Smith Family Trust, $75,000 (deal-scoped, no referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c4444444-4444-4444-4444-444444444444',
   'a4444444-4444-4444-4444-444444444444',
   '44444444-4444-4444-4444-444444444444',
   NULL,  -- fund_id
   1,  -- deal_id
   75000.00,
   'USD',
   NOW() - INTERVAL '5 days',
   NULL,  -- No referrer
   NOW() - INTERVAL '5 days',
   NOW() - INTERVAL '5 days')
ON CONFLICT (id) DO NOTHING;

-- Contribution 6: Test Investor, $10,000 (fund-scoped, with referrer)
INSERT INTO contributions (id, agreement_id, investor_party_id, fund_id, deal_id, paid_in_amount, currency, paid_in_date, introduced_by_party_id, created_at, updated_at)
VALUES
  ('c5555555-5555-5555-5555-555555555555',
   'a5555555-5555-5555-5555-555555555555',
   '55555555-5555-5555-5555-555555555555',
   1,  -- fund_id
   NULL,  -- deal_id
   10000.00,
   'USD',
   NOW() - INTERVAL '2 days',
   '66666666-6666-6666-6666-666666666666',  -- Bob Referrer
   NOW() - INTERVAL '2 days',
   NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- CREDITS (3 total: test FIFO logic)
-- ============================================================================

-- Credit 1: John Smith, $500 available (fund-scoped, oldest)
INSERT INTO credits_ledger (id, investor_party_id, fund_id, deal_id, amount, available_amount, applied_amount, currency, credit_type, created_at, updated_at)
VALUES
  ('cr111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id
   500.00,
   500.00,  -- Fully available
   0.00,
   'USD',
   'MANUAL_CREDIT',
   NOW() - INTERVAL '40 days',  -- Oldest credit (FIFO first)
   NOW() - INTERVAL '40 days')
ON CONFLICT (id) DO NOTHING;

-- Credit 2: Jane Doe, $250 available (deal-scoped, middle)
INSERT INTO credits_ledger (id, investor_party_id, fund_id, deal_id, amount, available_amount, applied_amount, currency, credit_type, created_at, updated_at)
VALUES
  ('cr222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   NULL,  -- fund_id
   1,  -- deal_id
   250.00,
   250.00,  -- Fully available
   0.00,
   'USD',
   'MANUAL_CREDIT',
   NOW() - INTERVAL '35 days',  -- Middle credit (FIFO second)
   NOW() - INTERVAL '35 days')
ON CONFLICT (id) DO NOTHING;

-- Credit 3: ACME Corp, $1000 available (fund-scoped, newest)
INSERT INTO credits_ledger (id, investor_party_id, fund_id, deal_id, amount, available_amount, applied_amount, currency, credit_type, created_at, updated_at)
VALUES
  ('cr333333-3333-3333-3333-333333333333',
   '33333333-3333-3333-3333-333333333333',
   2,  -- fund_id
   NULL,  -- deal_id
   1000.00,
   1000.00,  -- Fully available
   0.00,
   'USD',
   'MANUAL_CREDIT',
   NOW() - INTERVAL '30 days',  -- Newest credit (FIFO last)
   NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- CHARGES (6 total, all DRAFT status - will be auto-computed by T06 hook)
-- ============================================================================
-- Note: Charges should be auto-created by contribution hook (T06).
-- This section pre-populates them for testing if hook is not enabled yet.

-- Charge 1: John Smith contribution 1, $50,000 → $500 base + $100 VAT = $600 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch111111-1111-1111-1111-111111111111',
   'c1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id
   500.00,  -- $50,000 * 100 bps = $500
   100.00,  -- $500 * 20% VAT = $100
   600.00,  -- $500 + $100 = $600
   0.00,  -- No credits applied yet (DRAFT status)
   600.00,  -- Net = gross (no credits)
   'USD',
   'DRAFT',
   NOW() - INTERVAL '25 days',
   NOW() - INTERVAL '25 days')
ON CONFLICT (id) DO NOTHING;

-- Charge 2: John Smith contribution 2, $25,000 → $250 base + $50 VAT = $300 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch111112-1111-1111-1111-111111111111',
   'c1111112-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111',
   1,  -- fund_id
   NULL,  -- deal_id
   250.00,  -- $25,000 * 100 bps = $250
   50.00,  -- $250 * 20% VAT = $50
   300.00,  -- $250 + $50 = $300
   0.00,
   300.00,
   'USD',
   'DRAFT',
   NOW() - INTERVAL '20 days',
   NOW() - INTERVAL '20 days')
ON CONFLICT (id) DO NOTHING;

-- Charge 3: Jane Doe, $100,000 → $1,000 base + $200 VAT = $1,200 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch222222-2222-2222-2222-222222222222',
   'c2222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   'a2222222-2222-2222-2222-222222222222',
   NULL,  -- fund_id
   1,  -- deal_id
   1000.00,  -- $100,000 * 100 bps = $1,000
   200.00,  -- $1,000 * 20% VAT = $200
   1200.00,  -- $1,000 + $200 = $1,200
   0.00,
   1200.00,
   'USD',
   'DRAFT',
   NOW() - INTERVAL '15 days',
   NOW() - INTERVAL '15 days')
ON CONFLICT (id) DO NOTHING;

-- Charge 4: ACME Corp, $250,000 → $2,500 base + $500 VAT = $3,000 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch333333-3333-3333-3333-333333333333',
   'c3333333-3333-3333-3333-333333333333',
   '33333333-3333-3333-3333-333333333333',
   'a3333333-3333-3333-3333-333333333333',
   2,  -- fund_id
   NULL,  -- deal_id
   2500.00,  -- $250,000 * 100 bps = $2,500
   500.00,  -- $2,500 * 20% VAT = $500
   3000.00,  -- $2,500 + $500 = $3,000
   0.00,
   3000.00,
   'USD',
   'DRAFT',
   NOW() - INTERVAL '10 days',
   NOW() - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;

-- Charge 5: Smith Family Trust, $75,000 → $750 base + $150 VAT = $900 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch444444-4444-4444-4444-444444444444',
   'c4444444-4444-4444-4444-444444444444',
   '44444444-4444-4444-4444-444444444444',
   'a4444444-4444-4444-4444-444444444444',
   NULL,  -- fund_id
   1,  -- deal_id
   750.00,  -- $75,000 * 100 bps = $750
   150.00,  -- $750 * 20% VAT = $150
   900.00,  -- $750 + $150 = $900
   0.00,
   900.00,
   'USD',
   'DRAFT',
   NOW() - INTERVAL '5 days',
   NOW() - INTERVAL '5 days')
ON CONFLICT (id) DO NOTHING;

-- Charge 6: Test Investor, $10,000 → $100 base + $20 VAT = $120 gross
INSERT INTO charges (id, contribution_id, investor_party_id, agreement_id, fund_id, deal_id, base_amount, vat_amount, gross_amount, credits_applied, net_amount, currency, status, created_at, updated_at)
VALUES
  ('ch555555-5555-5555-5555-555555555555',
   'c5555555-5555-5555-5555-555555555555',
   '55555555-5555-5555-5555-555555555555',
   'a5555555-5555-5555-5555-555555555555',
   1,  -- fund_id
   NULL,  -- deal_id
   100.00,  -- $10,000 * 100 bps = $100
   20.00,  -- $100 * 20% VAT = $20
   120.00,  -- $100 + $20 = $120
   0.00,
   120.00,
   'USD',
   'DRAFT',
   NOW() - INTERVAL '2 days',
   NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ============================================================================
-- SEED COMPLETE
-- ============================================================================
-- Summary:
--   - 5 investors (3 individual, 2 entity)
--   - 1 distributor (Bob Referrer)
--   - 5 agreements (all APPROVED with 100 bps upfront, 20% VAT)
--   - 6 contributions ($50k, $25k, $100k, $250k, $75k, $10k)
--   - 3 credits ($500, $250, $1000)
--   - 6 charges (all DRAFT, $600, $300, $1200, $3000, $900, $120)
-- ============================================================================
```

---

## Reset SQL Script

**File:** `pm/v1.8.0/staging-reset.sql`

This script cleans up all v1.8.0 test data without affecting other staging data.

```sql
-- ============================================================================
-- v1.8.0 Staging Data Reset Script
-- ============================================================================
-- Purpose: Clean up v1.8.0 test data from staging database
-- WARNING: This will delete all test data seeded by staging-seed.sql
-- ============================================================================

BEGIN;

-- Delete charges (cascade will handle audit_trail if FK exists)
DELETE FROM charges WHERE id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
);

-- Delete credits
DELETE FROM credits_ledger WHERE id IN (
  'cr111111-1111-1111-1111-111111111111',
  'cr222222-2222-2222-2222-222222222222',
  'cr333333-3333-3333-3333-333333333333'
);

-- Delete contributions
DELETE FROM contributions WHERE id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
);

-- Delete agreements
DELETE FROM agreements WHERE id IN (
  'a1111111-1111-1111-1111-111111111111',
  'a2222222-2222-2222-2222-222222222222',
  'a3333333-3333-3333-3333-333333333333',
  'a4444444-4444-4444-4444-444444444444',
  'a5555555-5555-5555-5555-555555555555'
);

-- Delete parties (investors and distributor)
DELETE FROM parties WHERE id IN (
  '11111111-1111-1111-1111-111111111111',  -- John Smith
  '22222222-2222-2222-2222-222222222222',  -- Jane Doe
  '33333333-3333-3333-3333-333333333333',  -- ACME Corp
  '44444444-4444-4444-4444-444444444444',  -- Smith Family Trust
  '55555555-5555-5555-5555-555555555555',  -- Test Investor
  '66666666-6666-6666-6666-666666666666'   -- Bob Referrer
);

-- Clean up referrer review queue (if table exists)
DELETE FROM referrer_review_queue WHERE contribution_id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
);

-- Clean up audit trail (if table exists)
DELETE FROM audit_trail WHERE charge_id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
);

COMMIT;

-- ============================================================================
-- RESET COMPLETE
-- ============================================================================
-- All v1.8.0 test data removed. Staging database ready for new seed.
-- ============================================================================
```

---

## Validation SQL Queries

**File:** `pm/v1.8.0/staging-validation.sql`

Run these queries after seeding to verify data is correct.

```sql
-- ============================================================================
-- v1.8.0 Staging Data Validation Queries
-- ============================================================================

-- ============================================================================
-- 1. PARTIES VALIDATION
-- ============================================================================

-- Count parties (should be 6: 5 investors + 1 distributor)
SELECT
  party_type,
  COUNT(*) as count
FROM parties
WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444',
  '55555555-5555-5555-5555-555555555555',
  '66666666-6666-6666-6666-666666666666'
)
GROUP BY party_type;

-- Expected:
-- party_type   | count
-- -------------|------
-- INDIVIDUAL   | 3
-- ENTITY       | 2
-- DISTRIBUTOR  | 1

-- ============================================================================
-- 2. AGREEMENTS VALIDATION
-- ============================================================================

-- Count agreements (should be 5, all APPROVED)
SELECT
  status,
  COUNT(*) as count
FROM agreements
WHERE id IN (
  'a1111111-1111-1111-1111-111111111111',
  'a2222222-2222-2222-2222-222222222222',
  'a3333333-3333-3333-3333-333333333333',
  'a4444444-4444-4444-4444-444444444444',
  'a5555555-5555-5555-5555-555555555555'
)
GROUP BY status;

-- Expected:
-- status   | count
-- ---------|------
-- APPROVED | 5

-- Verify snapshot_json has pricing
SELECT
  id,
  investor_party_id,
  snapshot_json->'pricing'->>'upfront_bps' as upfront_bps,
  snapshot_json->'pricing'->>'vat_rate' as vat_rate
FROM agreements
WHERE id IN (
  'a1111111-1111-1111-1111-111111111111',
  'a2222222-2222-2222-2222-222222222222',
  'a3333333-3333-3333-3333-333333333333',
  'a4444444-4444-4444-4444-444444444444',
  'a5555555-5555-5555-5555-555555555555'
);

-- Expected: All rows should have upfront_bps=100, vat_rate=0.20

-- ============================================================================
-- 3. CONTRIBUTIONS VALIDATION
-- ============================================================================

-- Count contributions (should be 6)
SELECT
  COUNT(*) as total_contributions,
  SUM(paid_in_amount) as total_paid_in,
  COUNT(CASE WHEN introduced_by_party_id IS NOT NULL THEN 1 END) as with_referrer,
  COUNT(CASE WHEN introduced_by_party_id IS NULL THEN 1 END) as without_referrer
FROM contributions
WHERE id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
);

-- Expected:
-- total_contributions | total_paid_in | with_referrer | without_referrer
-- --------------------|---------------|---------------|------------------
-- 6                   | 510000.00     | 4             | 2

-- List contributions with scope
SELECT
  c.id,
  p.full_name as investor,
  c.paid_in_amount,
  CASE
    WHEN c.fund_id IS NOT NULL THEN 'fund-scoped'
    WHEN c.deal_id IS NOT NULL THEN 'deal-scoped'
    ELSE 'unknown'
  END as scope,
  CASE
    WHEN c.introduced_by_party_id IS NOT NULL THEN 'Yes'
    ELSE 'No'
  END as has_referrer
FROM contributions c
JOIN parties p ON c.investor_party_id = p.id
WHERE c.id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
)
ORDER BY c.paid_in_date;

-- Expected: 3 fund-scoped, 3 deal-scoped; 4 with referrer, 2 without

-- ============================================================================
-- 4. CREDITS VALIDATION
-- ============================================================================

-- Count credits (should be 3, all available)
SELECT
  COUNT(*) as total_credits,
  SUM(amount) as total_amount,
  SUM(available_amount) as total_available,
  SUM(applied_amount) as total_applied
FROM credits_ledger
WHERE id IN (
  'cr111111-1111-1111-1111-111111111111',
  'cr222222-2222-2222-2222-222222222222',
  'cr333333-3333-3333-3333-333333333333'
);

-- Expected:
-- total_credits | total_amount | total_available | total_applied
-- --------------|--------------|-----------------|---------------
-- 3             | 1750.00      | 1750.00         | 0.00

-- List credits in FIFO order (oldest first)
SELECT
  cl.id,
  p.full_name as investor,
  cl.amount,
  cl.available_amount,
  CASE
    WHEN cl.fund_id IS NOT NULL THEN CONCAT('fund:', cl.fund_id)
    WHEN cl.deal_id IS NOT NULL THEN CONCAT('deal:', cl.deal_id)
    ELSE 'unknown'
  END as scope,
  cl.created_at
FROM credits_ledger cl
JOIN parties p ON cl.investor_party_id = p.id
WHERE cl.id IN (
  'cr111111-1111-1111-1111-111111111111',
  'cr222222-2222-2222-2222-222222222222',
  'cr333333-3333-3333-3333-333333333333'
)
ORDER BY cl.created_at ASC;

-- Expected: 3 rows ordered by created_at (oldest to newest)
-- Credit 1 (John Smith, $500) should be oldest
-- Credit 2 (Jane Doe, $250) should be middle
-- Credit 3 (ACME Corp, $1000) should be newest

-- ============================================================================
-- 5. CHARGES VALIDATION
-- ============================================================================

-- Count charges (should be 6, all DRAFT)
SELECT
  status,
  COUNT(*) as count
FROM charges
WHERE id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
)
GROUP BY status;

-- Expected:
-- status | count
-- -------|------
-- DRAFT  | 6

-- Verify charge calculations
SELECT
  ch.id,
  p.full_name as investor,
  ch.base_amount,
  ch.vat_amount,
  ch.gross_amount,
  ch.credits_applied,
  ch.net_amount,
  CASE
    WHEN ch.fund_id IS NOT NULL THEN 'fund-scoped'
    WHEN ch.deal_id IS NOT NULL THEN 'deal-scoped'
    ELSE 'unknown'
  END as scope
FROM charges ch
JOIN parties p ON ch.investor_party_id = p.id
WHERE ch.id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
)
ORDER BY ch.created_at;

-- Expected: 6 charges with correct calculations
-- Charge 1: $500 base + $100 VAT = $600 gross
-- Charge 2: $250 base + $50 VAT = $300 gross
-- Charge 3: $1000 base + $200 VAT = $1200 gross
-- Charge 4: $2500 base + $500 VAT = $3000 gross
-- Charge 5: $750 base + $150 VAT = $900 gross
-- Charge 6: $100 base + $20 VAT = $120 gross

-- Verify all charges have credits_applied=0 and net_amount=gross_amount (DRAFT status)
SELECT
  id,
  gross_amount,
  credits_applied,
  net_amount,
  CASE
    WHEN credits_applied = 0 AND net_amount = gross_amount THEN 'OK'
    ELSE 'ERROR'
  END as validation
FROM charges
WHERE id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
);

-- Expected: All rows should have validation='OK'

-- ============================================================================
-- 6. DATA INTEGRITY CHECKS
-- ============================================================================

-- Verify all contributions have corresponding charges
SELECT
  c.id as contribution_id,
  c.paid_in_amount,
  ch.id as charge_id,
  ch.gross_amount
FROM contributions c
LEFT JOIN charges ch ON c.id = ch.contribution_id
WHERE c.id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
);

-- Expected: All 6 contributions should have matching charge_id (not NULL)

-- Verify all charges reference APPROVED agreements
SELECT
  ch.id as charge_id,
  a.status as agreement_status
FROM charges ch
JOIN agreements a ON ch.agreement_id = a.id
WHERE ch.id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
);

-- Expected: All 6 charges should have agreement_status='APPROVED'

-- ============================================================================
-- VALIDATION SUMMARY
-- ============================================================================

SELECT
  'Parties' as entity,
  COUNT(*) as count,
  6 as expected,
  CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END as status
FROM parties
WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444',
  '55555555-5555-5555-5555-555555555555',
  '66666666-6666-6666-6666-666666666666'
)

UNION ALL

SELECT
  'Agreements' as entity,
  COUNT(*) as count,
  5 as expected,
  CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END as status
FROM agreements
WHERE id IN (
  'a1111111-1111-1111-1111-111111111111',
  'a2222222-2222-2222-2222-222222222222',
  'a3333333-3333-3333-3333-333333333333',
  'a4444444-4444-4444-4444-444444444444',
  'a5555555-5555-5555-5555-555555555555'
)

UNION ALL

SELECT
  'Contributions' as entity,
  COUNT(*) as count,
  6 as expected,
  CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END as status
FROM contributions
WHERE id IN (
  'c1111111-1111-1111-1111-111111111111',
  'c1111112-1111-1111-1111-111111111111',
  'c2222222-2222-2222-2222-222222222222',
  'c3333333-3333-3333-3333-333333333333',
  'c4444444-4444-4444-4444-444444444444',
  'c5555555-5555-5555-5555-555555555555'
)

UNION ALL

SELECT
  'Credits' as entity,
  COUNT(*) as count,
  3 as expected,
  CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'FAIL' END as status
FROM credits_ledger
WHERE id IN (
  'cr111111-1111-1111-1111-111111111111',
  'cr222222-2222-2222-2222-222222222222',
  'cr333333-3333-3333-3333-333333333333'
)

UNION ALL

SELECT
  'Charges' as entity,
  COUNT(*) as count,
  6 as expected,
  CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END as status
FROM charges
WHERE id IN (
  'ch111111-1111-1111-1111-111111111111',
  'ch111112-1111-1111-1111-111111111111',
  'ch222222-2222-2222-2222-222222222222',
  'ch333333-3333-3333-3333-333333333333',
  'ch444444-4444-4444-4444-444444444444',
  'ch555555-5555-5555-5555-555555555555'
);

-- Expected: All entities should show status='PASS'
-- ============================================================================
```

---

## Usage Instructions

### Seeding Staging Database

1. **Connect to staging database:**
   ```bash
   psql -h <staging-host> -U <user> -d <database>
   ```

2. **Run seed script:**
   ```bash
   \i pm/v1.8.0/staging-seed.sql
   ```

3. **Verify seed data:**
   ```bash
   \i pm/v1.8.0/staging-validation.sql
   ```

4. **Check validation summary:**
   - All entities should show status='PASS'
   - If any FAIL, review seed script and rerun

### Resetting Staging Database

1. **Connect to staging database:**
   ```bash
   psql -h <staging-host> -U <user> -d <database>
   ```

2. **Run reset script:**
   ```bash
   \i pm/v1.8.0/staging-reset.sql
   ```

3. **Verify cleanup:**
   ```bash
   \i pm/v1.8.0/staging-validation.sql
   ```
   - All counts should be 0 or status='FAIL' (indicating no test data)

4. **Re-seed if needed:**
   ```bash
   \i pm/v1.8.0/staging-seed.sql
   ```

---

## Test Scenarios Enabled by Seed Data

### Scenario 1: FIFO Credit Application
- **Setup:** John Smith has $500 credit (oldest), charge $600
- **Test:** Submit charge, verify credit fully applied ($500), net=$100
- **Expected:** Credit 1 exhausted (available=$0), charge net=$100

### Scenario 2: Multiple Credits FIFO
- **Setup:** John Smith has $500 credit, create another $200 credit (newer), charge $600
- **Test:** Submit charge, verify oldest credit applied first
- **Expected:** Credit 1 fully applied ($500), Credit 2 partially applied ($100), net=$0

### Scenario 3: Scope Matching (Fund)
- **Setup:** John Smith charge (fund_id=1), ACME Corp credit (fund_id=2)
- **Test:** Submit John charge, verify no cross-scope credit application
- **Expected:** ACME credit NOT applied (scope mismatch), charge net=gross

### Scenario 4: Scope Matching (Deal)
- **Setup:** Jane Doe charge (deal_id=1), Jane credit (deal_id=1)
- **Test:** Submit charge, verify deal-scoped credit applied
- **Expected:** Credit applied (scope match), net reduced

### Scenario 5: Credit Reversal on Reject
- **Setup:** Submit charge with credits applied, approve, then reject
- **Test:** Reject charge, verify credits restored
- **Expected:** Credits available_amount restored, charge status=REJECTED

### Scenario 6: Referrer Fuzzy Matching
- **Setup:** CSV import with "Referrer" column: "Bob Referrer", "bob referrer", "B. Referrer"
- **Test:** Import CSV, verify auto-link accuracy
- **Expected:** Exact match auto-links, fuzzy matches review queue or auto-link based on confidence

---

## Data Seed Maintenance

**Owner:** orchestrator-pm

**Review Schedule:**
- Before pilot phase: verify seed data accurate
- After pilot phase: update seed data based on feedback
- Before each release: refresh staging database

**Versioning:**
- Seed script versioned with release (v1.8.0)
- Changes tracked in git (commit message: "Update v1.8.0 seed data")

---

**Document Status:** APPROVED
**Last Updated:** 2025-10-21
**Next Review:** Before pilot deployment
