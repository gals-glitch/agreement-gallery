-- ============================================
-- P1 Features Verification Queries
-- Purpose: Validate migration 20251019110000_rbac_settings_credits.sql
-- Date: 2025-10-19
-- ============================================

-- ============================================
-- SECTION 1: RBAC Tables Verification
-- ============================================

-- Query 1.1: Verify roles table and seed data
SELECT
  key,
  name,
  description,
  created_at
FROM roles
ORDER BY key;

-- Expected output: 5 rows (admin, finance, manager, ops, viewer)

-- Query 1.2: Verify user_roles table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_roles'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected columns: user_id, role_key, granted_by, granted_at

-- Query 1.3: Check user_roles indexes
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'user_roles'
  AND schemaname = 'public'
ORDER BY indexname;

-- Expected indexes: idx_user_roles_user_id, idx_user_roles_role_key, idx_user_roles_granted_by

-- Query 1.4: Verify user_roles RLS policies
SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'user_roles'
  AND schemaname = 'public'
ORDER BY policyname;

-- Expected policies: Authenticated users can read user_roles, Admins can manage user_roles

-- ============================================
-- SECTION 2: Audit Log Verification
-- ============================================

-- Query 2.1: Verify audit_log table structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'audit_log'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected columns: id, event_type, actor_id, target_id, entity_type, entity_id, payload, timestamp, ip_address, user_agent

-- Query 2.2: Check audit_log indexes
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'audit_log'
  AND schemaname = 'public'
ORDER BY indexname;

-- Expected indexes: idx_audit_log_event_type, idx_audit_log_actor_id, idx_audit_log_target_id, idx_audit_log_timestamp, idx_audit_log_payload (GIN)

-- Query 2.3: Test JSONB index (GIN) functionality
EXPLAIN (COSTS OFF)
SELECT * FROM audit_log
WHERE payload @> '{"role_key": "admin"}'::jsonb;

-- Expected plan: Should use Bitmap Index Scan on idx_audit_log_payload (if data exists)

-- ============================================
-- SECTION 3: Organization Settings Verification
-- ============================================

-- Query 3.1: Verify org_settings singleton
SELECT
  id,
  org_name,
  default_currency,
  timezone,
  invoice_prefix,
  vat_display_mode,
  created_at,
  updated_at,
  updated_by
FROM org_settings;

-- Expected: Exactly 1 row with id=1

-- Query 3.2: Test singleton constraint (should fail)
-- Uncomment to test:
-- INSERT INTO org_settings (id, org_name) VALUES (2, 'Test Org');
-- Expected error: new row for relation "org_settings" violates check constraint "org_settings_id_check"

-- Query 3.3: Verify updated_at trigger exists
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'org_settings'
  AND trigger_schema = 'public'
ORDER BY trigger_name;

-- Expected: org_settings_update_timestamp trigger

-- ============================================
-- SECTION 4: Credits Table Verification
-- ============================================

-- Query 4.1: Verify credits table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  is_generated
FROM information_schema.columns
WHERE table_name = 'credits'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected: available_amount should have is_generated = 'ALWAYS'

-- Query 4.2: Check credits indexes (especially FIFO index)
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'credits'
  AND schemaname = 'public'
ORDER BY indexname;

-- Expected: idx_credits_available_fifo (partial index with WHERE available_amount > 0)

-- Query 4.3: Verify credits CHECK constraints
SELECT
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'credits'
  AND con.contype = 'c'  -- CHECK constraints
ORDER BY con.conname;

-- Expected constraints: credits_scope_check, credits_original_amount_check, credits_applied_amount_check, credits_reason_check, credits_status_check

-- Query 4.4: Test FIFO index query plan
EXPLAIN (COSTS ON)
SELECT
  id,
  investor_id,
  reason,
  original_amount,
  applied_amount,
  available_amount,
  created_at
FROM credits
WHERE investor_id = 1
  AND available_amount > 0
ORDER BY created_at ASC
LIMIT 5;

-- Expected plan: Index Scan using idx_credits_available_fifo

-- Query 4.5: Verify auto-status trigger exists
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'credits'
  AND trigger_schema = 'public'
ORDER BY trigger_name;

-- Expected: credits_auto_status_update trigger

-- ============================================
-- SECTION 5: Credit Applications Verification
-- ============================================

-- Query 5.1: Verify credit_applications table structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'credit_applications'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected columns: id, credit_id, charge_id, amount_applied, applied_at, applied_by, reversed_at, reversed_by, reversal_reason

-- Query 5.2: Check credit_applications indexes
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'credit_applications'
  AND schemaname = 'public'
ORDER BY indexname;

-- Expected: idx_credit_applications_credit_id, idx_credit_applications_charge_id, idx_credit_applications_active (partial)

-- Query 5.3: Verify partial index for active applications
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'credit_applications'
  AND indexname = 'idx_credit_applications_active';

-- Expected: Index with WHERE reversed_at IS NULL

-- ============================================
-- SECTION 6: RLS Policies Verification
-- ============================================

-- Query 6.1: List all RLS policies for new tables
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  CASE
    WHEN qual IS NOT NULL THEN 'USING clause present'
    ELSE 'No USING clause'
  END AS using_clause,
  CASE
    WHEN with_check IS NOT NULL THEN 'WITH CHECK present'
    ELSE 'No WITH CHECK'
  END AS with_check_clause
FROM pg_policies
WHERE tablename IN ('roles', 'user_roles', 'audit_log', 'org_settings', 'credits', 'credit_applications')
  AND schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected: Multiple policies per table (SELECT, INSERT/UPDATE/DELETE)

-- Query 6.2: Verify RLS is enabled on all new tables
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename IN ('roles', 'user_roles', 'audit_log', 'org_settings', 'credits', 'credit_applications')
  AND schemaname = 'public'
ORDER BY tablename;

-- Expected: rowsecurity = true for all tables

-- ============================================
-- SECTION 7: Foreign Key Integrity Verification
-- ============================================

-- Query 7.1: Verify all foreign keys
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.update_rule,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
  AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('user_roles', 'audit_log', 'org_settings', 'credits', 'credit_applications')
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- Expected foreign keys:
-- user_roles: user_id -> auth.users, role_key -> roles, granted_by -> auth.users
-- audit_log: actor_id -> auth.users
-- org_settings: updated_by -> auth.users
-- credits: investor_id -> investors, fund_id -> funds, deal_id -> deals, created_by -> auth.users
-- credit_applications: credit_id -> credits, applied_by -> auth.users, reversed_by -> auth.users

-- ============================================
-- SECTION 8: Sample Data Tests
-- ============================================

-- Query 8.1: Insert test role assignment (requires admin user)
-- Uncomment to test (replace 'admin-user-uuid'):
-- INSERT INTO user_roles (user_id, role_key, granted_by)
-- VALUES (
--   'admin-user-uuid',
--   'admin',
--   'admin-user-uuid'
-- );

-- Query 8.2: Insert test credit
-- Uncomment to test (requires valid investor_id and fund_id):
-- INSERT INTO credits (investor_id, fund_id, reason, original_amount, notes)
-- VALUES (
--   1,  -- investor_id
--   1,  -- fund_id
--   'MANUAL',
--   10000.00,
--   'Test credit for verification'
-- );

-- Query 8.3: Verify computed column (available_amount)
-- Uncomment after inserting test credit:
-- SELECT
--   id,
--   original_amount,
--   applied_amount,
--   available_amount,
--   available_amount = (original_amount - applied_amount) AS computed_correct
-- FROM credits
-- WHERE notes = 'Test credit for verification';

-- Expected: computed_correct = true

-- Query 8.4: Test auto-status trigger
-- Uncomment to test (replace credit_id):
-- UPDATE credits
-- SET applied_amount = original_amount
-- WHERE id = 1;  -- Replace with actual credit_id
--
-- SELECT id, status, available_amount
-- FROM credits
-- WHERE id = 1;

-- Expected: status = 'FULLY_APPLIED', available_amount = 0

-- ============================================
-- SECTION 9: Performance Tests
-- ============================================

-- Query 9.1: Test FIFO query performance (without data)
EXPLAIN ANALYZE
SELECT
  id,
  investor_id,
  available_amount,
  created_at
FROM credits
WHERE investor_id = 1
  AND available_amount > 0
ORDER BY created_at ASC
LIMIT 10;

-- Expected: Index Scan using idx_credits_available_fifo (even with no data)

-- Query 9.2: Test audit log JSONB query performance
EXPLAIN ANALYZE
SELECT
  event_type,
  payload,
  timestamp
FROM audit_log
WHERE payload @> '{"role_key": "admin"}'::jsonb
ORDER BY timestamp DESC
LIMIT 10;

-- Expected: Bitmap Index Scan on idx_audit_log_payload (if data exists)

-- Query 9.3: Test user_roles lookup performance
EXPLAIN ANALYZE
SELECT EXISTS (
  SELECT 1 FROM user_roles
  WHERE user_id = 'test-uuid'::uuid
    AND role_key = 'admin'
) AS has_admin_role;

-- Expected: Index Scan using idx_user_roles_user_id or primary key

-- ============================================
-- SECTION 10: Migration Safety Checks
-- ============================================

-- Query 10.1: Verify no duplicate role keys
SELECT
  key,
  COUNT(*) AS count
FROM roles
GROUP BY key
HAVING COUNT(*) > 1;

-- Expected: No rows (all role keys unique)

-- Query 10.2: Verify org_settings singleton constraint
SELECT COUNT(*) AS org_settings_count
FROM org_settings;

-- Expected: Exactly 1 row

-- Query 10.3: Check for orphaned user_roles (invalid role_key)
SELECT ur.user_id, ur.role_key
FROM user_roles ur
LEFT JOIN roles r ON ur.role_key = r.key
WHERE r.key IS NULL;

-- Expected: No rows (all role_keys valid)

-- Query 10.4: Verify credits scope constraint (mutual exclusion)
SELECT
  id,
  investor_id,
  fund_id,
  deal_id,
  CASE
    WHEN fund_id IS NOT NULL AND deal_id IS NULL THEN 'Fund scope OK'
    WHEN fund_id IS NULL AND deal_id IS NOT NULL THEN 'Deal scope OK'
    ELSE 'ERROR: Both or neither scope set'
  END AS scope_validation
FROM credits;

-- Expected: All rows should have 'Fund scope OK' or 'Deal scope OK'

-- ============================================
-- SECTION 11: Cleanup Test Data (Optional)
-- ============================================

-- Uncomment to clean up test data created in Section 8:
-- DELETE FROM user_roles WHERE role_key = 'admin' AND user_id = 'admin-user-uuid';
-- DELETE FROM credits WHERE notes = 'Test credit for verification';

-- ============================================
-- SUMMARY REPORT
-- ============================================

-- Query 11.1: Count all tables and their row counts
SELECT
  'roles' AS table_name,
  COUNT(*) AS row_count
FROM roles
UNION ALL
SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL
SELECT 'audit_log', COUNT(*) FROM audit_log
UNION ALL
SELECT 'org_settings', COUNT(*) FROM org_settings
UNION ALL
SELECT 'credits', COUNT(*) FROM credits
UNION ALL
SELECT 'credit_applications', COUNT(*) FROM credit_applications
ORDER BY table_name;

-- Expected:
-- roles: 5 rows
-- user_roles: 0+ rows (depends on assignments)
-- audit_log: 0+ rows (depends on events)
-- org_settings: 1 row
-- credits: 0+ rows (depends on data)
-- credit_applications: 0+ rows (depends on data)

-- Query 11.2: Summary of indexes created
SELECT
  tablename,
  COUNT(*) AS index_count
FROM pg_indexes
WHERE tablename IN ('roles', 'user_roles', 'audit_log', 'org_settings', 'credits', 'credit_applications')
  AND schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected index counts:
-- roles: 1 (primary key)
-- user_roles: 4 (primary key + 3 indexes)
-- audit_log: 6 (primary key + 5 indexes including GIN)
-- org_settings: 1 (primary key)
-- credits: 7 (primary key + 6 indexes)
-- credit_applications: 4 (primary key + 3 indexes)

-- Query 11.3: Summary of RLS policies
SELECT
  tablename,
  COUNT(*) AS policy_count
FROM pg_policies
WHERE tablename IN ('roles', 'user_roles', 'audit_log', 'org_settings', 'credits', 'credit_applications')
  AND schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected policy counts:
-- roles: 2
-- user_roles: 2
-- audit_log: 2
-- org_settings: 2
-- credits: 2
-- credit_applications: 2

-- ============================================
-- END VERIFICATION QUERIES
-- ============================================

-- All queries should execute without errors if migration was successful.
-- Review any unexpected results and compare with expected outputs above.
