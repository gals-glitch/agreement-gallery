-- ============================================
-- Quick Migration Verification (Returns Rows)
-- Run this to verify migrations applied successfully
-- ============================================

-- Check 1: Verify charges table exists with all columns
SELECT
  'Table Structure' AS check_type,
  'charges table' AS item,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 23 THEN '✅ PASS'
    ELSE '❌ FAIL (expected 23 columns)'
  END AS status
FROM information_schema.columns
WHERE table_name = 'charges'

UNION ALL

-- Check 2: Verify indexes
SELECT
  'Indexes' AS check_type,
  'Total indexes' AS item,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) >= 8 THEN '✅ PASS'
    ELSE '❌ FAIL (expected >= 8 indexes)'
  END AS status
FROM pg_indexes
WHERE tablename = 'charges'

UNION ALL

-- Check 3: Verify RLS policies
SELECT
  'RLS Policies' AS check_type,
  'Total policies' AS item,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) >= 2 THEN '✅ PASS'
    ELSE '❌ FAIL (expected >= 2 policies)'
  END AS status
FROM pg_policies
WHERE tablename = 'charges'

UNION ALL

-- Check 4: Verify charge_status enum
SELECT
  'Enum Values' AS check_type,
  'charge_status' AS item,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 5 THEN '✅ PASS'
    ELSE '❌ FAIL (expected 5 values)'
  END AS status
FROM pg_enum
WHERE enumtypid = 'charge_status'::regtype

UNION ALL

-- Check 5: Verify id column type (UUID)
SELECT
  'Column Types' AS check_type,
  'charges.id' AS item,
  1 AS count,
  CASE
    WHEN data_type = 'uuid' THEN '✅ PASS (UUID)'
    ELSE '❌ FAIL (expected uuid, got ' || data_type || ')'
  END AS status
FROM information_schema.columns
WHERE table_name = 'charges' AND column_name = 'id'

UNION ALL

-- Check 6: Verify numeric_id column type (BIGINT)
SELECT
  'Column Types' AS check_type,
  'charges.numeric_id' AS item,
  1 AS count,
  CASE
    WHEN data_type = 'bigint' THEN '✅ PASS (BIGINT)'
    ELSE '❌ FAIL (expected bigint, got ' || COALESCE(data_type, 'NULL') || ')'
  END AS status
FROM information_schema.columns
WHERE table_name = 'charges' AND column_name = 'numeric_id'

UNION ALL

-- Check 7: Verify credits_applied_amount column
SELECT
  'Credits Columns' AS check_type,
  'credits_applied_amount' AS item,
  1 AS count,
  CASE
    WHEN data_type = 'numeric' THEN '✅ PASS (NUMERIC)'
    ELSE '❌ FAIL (expected numeric, got ' || COALESCE(data_type, 'NULL') || ')'
  END AS status
FROM information_schema.columns
WHERE table_name = 'charges' AND column_name = 'credits_applied_amount'

UNION ALL

-- Check 8: Verify net_amount column
SELECT
  'Credits Columns' AS check_type,
  'net_amount' AS item,
  1 AS count,
  CASE
    WHEN data_type = 'numeric' THEN '✅ PASS (NUMERIC)'
    ELSE '❌ FAIL (expected numeric, got ' || COALESCE(data_type, 'NULL') || ')'
  END AS status
FROM information_schema.columns
WHERE table_name = 'charges' AND column_name = 'net_amount'

UNION ALL

-- Check 9: Verify FK from credit_applications to charges
SELECT
  'Foreign Keys' AS check_type,
  'credit_applications → charges' AS item,
  1 AS count,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conname = 'credit_applications_charge_numeric_id_fkey'
    ) THEN '✅ PASS (FK exists)'
    ELSE '❌ FAIL (FK not found)'
  END AS status

UNION ALL

-- Check 10: Verify RLS enabled
SELECT
  'Row Level Security' AS check_type,
  'RLS enabled' AS item,
  1 AS count,
  CASE
    WHEN relrowsecurity THEN '✅ PASS (enabled)'
    ELSE '❌ FAIL (not enabled)'
  END AS status
FROM pg_class
WHERE relname = 'charges'

ORDER BY check_type, item;
