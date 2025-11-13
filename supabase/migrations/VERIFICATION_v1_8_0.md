# v1.8.0 Schema Verification Guide

This document provides comprehensive verification queries and test procedures for v1.8.0 schema changes.

## Migration Summary

**File:** `20251021000000_v1_8_0_schema_prep.sql`

**Changes:**
- DB-01: Verified unique index on `charges.contribution_id` (for idempotent compute)
- DB-02: Verified FK constraint `credit_applications.credit_id` → `credits_ledger.id`
- DB-03: Updated RLS policies for `charges` table (split granular permissions)
- DB-04: Documented service role behavior (bypasses RLS)

---

## DB-01: Unique Index Verification

### 1.1 Check Index Exists

```sql
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'charges'
AND indexname = 'idx_charges_contribution_unique';
```

**Expected Output:**
```
schemaname | tablename | indexname                        | indexdef
-----------+-----------+----------------------------------+--------------------------------------------------
public     | charges   | idx_charges_contribution_unique  | CREATE UNIQUE INDEX idx_charges_contribution_unique ON charges USING btree (contribution_id)
```

### 1.2 Test Idempotent Upsert

```sql
DO $$
DECLARE
  test_charge_id UUID;
  first_charge_id UUID;
  second_charge_id UUID;
BEGIN
  -- First insert
  INSERT INTO charges (
    investor_id, fund_id, contribution_id, status,
    base_amount, total_amount, currency, snapshot_json
  )
  VALUES (
    1, 1, 999999, 'DRAFT',
    10000.00, 12000.00, 'USD', '{"test": true}'::jsonb
  )
  ON CONFLICT (contribution_id) DO UPDATE
  SET
    base_amount = EXCLUDED.base_amount,
    total_amount = EXCLUDED.total_amount,
    updated_at = now()
  RETURNING id INTO first_charge_id;

  RAISE NOTICE 'First insert: charge_id = %', first_charge_id;

  -- Second insert (should update existing row, not create new one)
  INSERT INTO charges (
    investor_id, fund_id, contribution_id, status,
    base_amount, total_amount, currency, snapshot_json
  )
  VALUES (
    1, 1, 999999, 'DRAFT',
    15000.00, 18000.00, 'USD', '{"test": true}'::jsonb
  )
  ON CONFLICT (contribution_id) DO UPDATE
  SET
    base_amount = EXCLUDED.base_amount,
    total_amount = EXCLUDED.total_amount,
    updated_at = now()
  RETURNING id INTO second_charge_id;

  RAISE NOTICE 'Second insert (upsert): charge_id = %', second_charge_id;

  -- Verify IDs match (same row updated)
  IF first_charge_id = second_charge_id THEN
    RAISE NOTICE '✅ Idempotent upsert works correctly - same charge ID';
  ELSE
    RAISE EXCEPTION '❌ Different charge IDs - duplicate created!';
  END IF;

  -- Verify only one charge exists for contribution_id = 999999
  IF (SELECT COUNT(*) FROM charges WHERE contribution_id = 999999) = 1 THEN
    RAISE NOTICE '✅ Exactly one charge exists for contribution_id = 999999';
  ELSE
    RAISE EXCEPTION '❌ Multiple charges created for contribution_id = 999999';
  END IF;

  -- Verify updated amount
  SELECT base_amount INTO test_charge_id FROM charges WHERE contribution_id = 999999;
  IF test_charge_id::numeric = 15000.00 THEN
    RAISE NOTICE '✅ Charge amount updated correctly (15000.00)';
  ELSE
    RAISE EXCEPTION '❌ Charge amount not updated: %', test_charge_id;
  END IF;

  -- Cleanup
  DELETE FROM charges WHERE contribution_id = 999999;
  RAISE NOTICE '✅ Test data cleaned up';
END $$;
```

**Expected Output:**
```
NOTICE:  First insert: charge_id = <UUID>
NOTICE:  Second insert (upsert): charge_id = <UUID> (same as first)
NOTICE:  ✅ Idempotent upsert works correctly - same charge ID
NOTICE:  ✅ Exactly one charge exists for contribution_id = 999999
NOTICE:  ✅ Charge amount updated correctly (15000.00)
NOTICE:  ✅ Test data cleaned up
```

### 1.3 Test Duplicate Insert (Should Fail Without ON CONFLICT)

```sql
-- This should fail with unique constraint violation
BEGIN;
  INSERT INTO charges (investor_id, fund_id, contribution_id, status, base_amount, total_amount, currency, snapshot_json)
  VALUES (1, 1, 777777, 'DRAFT', 1000.00, 1200.00, 'USD', '{}'::jsonb);

  INSERT INTO charges (investor_id, fund_id, contribution_id, status, base_amount, total_amount, currency, snapshot_json)
  VALUES (1, 1, 777777, 'DRAFT', 2000.00, 2400.00, 'USD', '{}'::jsonb);
ROLLBACK;
```

**Expected Output:**
```
ERROR:  duplicate key value violates unique constraint "idx_charges_contribution_unique"
DETAIL:  Key (contribution_id)=(777777) already exists.
```

---

## DB-02: FK Constraint Verification

### 2.1 Check FK Constraint Exists

```sql
SELECT
  c.conname AS constraint_name,
  t.relname AS table_name,
  ft.relname AS foreign_table_name,
  a.attname AS column_name,
  fa.attname AS foreign_column_name,
  c.confdeltype AS on_delete_action
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_class ft ON c.confrelid = ft.oid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
JOIN pg_attribute fa ON fa.attrelid = ft.oid AND fa.attnum = ANY(c.confkey)
WHERE t.relname = 'credit_applications'
AND a.attname = 'credit_id';
```

**Expected Output:**
```
constraint_name                        | table_name           | foreign_table_name | column_name | foreign_column_name | on_delete_action
---------------------------------------+----------------------+--------------------+-------------+---------------------+------------------
credit_applications_credit_id_fkey     | credit_applications  | credits_ledger     | credit_id   | id                  | r (RESTRICT)
```

### 2.2 Check Data Type Match

```sql
SELECT
  t.table_name,
  c.column_name,
  c.data_type,
  c.udt_name
FROM information_schema.columns c
JOIN information_schema.tables t ON c.table_name = t.table_name
WHERE (t.table_name = 'credit_applications' AND c.column_name = 'credit_id')
   OR (t.table_name = 'credits_ledger' AND c.column_name = 'id')
ORDER BY t.table_name, c.column_name;
```

**Expected Output:**
```
table_name           | column_name | data_type | udt_name
---------------------+-------------+-----------+----------
credit_applications  | credit_id   | bigint    | int8
credits_ledger       | id          | bigint    | int8
```

### 2.3 Test FK Constraint Violation

```sql
-- This should fail with FK violation
BEGIN;
  INSERT INTO credit_applications (credit_id, charge_id, amount_applied)
  VALUES (999999, NULL, 100.00);
ROLLBACK;
```

**Expected Output:**
```
ERROR:  insert or update on table "credit_applications" violates foreign key constraint "credit_applications_credit_id_fkey"
DETAIL:  Key (credit_id)=(999999) is not present in table "credits_ledger".
```

### 2.4 Test Successful Credit Application Insert

```sql
DO $$
DECLARE
  test_credit_id BIGINT;
  test_charge_id BIGINT;
  test_application_id BIGINT;
BEGIN
  -- Create a test credit
  INSERT INTO credits_ledger (investor_id, fund_id, reason, original_amount, currency)
  VALUES (1, 1, 'MANUAL', 1000.00, 'USD')
  RETURNING id INTO test_credit_id;

  RAISE NOTICE 'Created test credit: id = %', test_credit_id;

  -- Create a test charge
  INSERT INTO charges (investor_id, fund_id, contribution_id, status, base_amount, total_amount, currency, snapshot_json)
  VALUES (1, 1, 888888, 'APPROVED', 500.00, 500.00, 'USD', '{}'::jsonb)
  RETURNING numeric_id INTO test_charge_id;

  RAISE NOTICE 'Created test charge: numeric_id = %', test_charge_id;

  -- Apply credit to charge (should succeed)
  INSERT INTO credit_applications (credit_id, charge_id, amount_applied)
  VALUES (test_credit_id, test_charge_id, 250.00)
  RETURNING id INTO test_application_id;

  RAISE NOTICE '✅ Credit application inserted successfully: id = %', test_application_id;

  -- Verify FK relationship
  IF EXISTS (
    SELECT 1 FROM credit_applications ca
    JOIN credits_ledger cl ON ca.credit_id = cl.id
    WHERE ca.id = test_application_id
  ) THEN
    RAISE NOTICE '✅ FK relationship verified - credit_applications.credit_id → credits_ledger.id';
  ELSE
    RAISE EXCEPTION '❌ FK relationship broken';
  END IF;

  -- Cleanup
  DELETE FROM credit_applications WHERE id = test_application_id;
  DELETE FROM charges WHERE contribution_id = 888888;
  DELETE FROM credits_ledger WHERE id = test_credit_id;

  RAISE NOTICE '✅ Test data cleaned up';
END $$;
```

**Expected Output:**
```
NOTICE:  Created test credit: id = <BIGINT>
NOTICE:  Created test charge: numeric_id = <BIGINT>
NOTICE:  ✅ Credit application inserted successfully: id = <BIGINT>
NOTICE:  ✅ FK relationship verified - credit_applications.credit_id → credits_ledger.id
NOTICE:  ✅ Test data cleaned up
```

---

## DB-03: RLS Policies Verification

### 3.1 List All RLS Policies on Charges

```sql
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual IS NOT NULL AS has_using,
  with_check IS NOT NULL AS has_with_check
FROM pg_policies
WHERE tablename = 'charges'
ORDER BY cmd, policyname;
```

**Expected Output:**
```
schemaname | tablename | policyname                     | permissive | roles          | cmd    | has_using | has_with_check
-----------+-----------+--------------------------------+------------+----------------+--------+-----------+----------------
public     | charges   | charges_delete_admin           | PERMISSIVE | {authenticated}| DELETE | true      | false
public     | charges   | charges_insert_finance_admin   | PERMISSIVE | {authenticated}| INSERT | false     | true
public     | charges   | Finance+ can read all charges  | PERMISSIVE | {authenticated}| SELECT | true      | false
public     | charges   | charges_update_admin           | PERMISSIVE | {authenticated}| UPDATE | true      | true
```

### 3.2 Check RLS is Enabled

```sql
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'charges';
```

**Expected Output:**
```
schemaname | tablename | rowsecurity
-----------+-----------+-------------
public     | charges   | true
```

### 3.3 Test RLS Policies (Manual Testing Required)

**Setup: Create Test Users with Roles**

```sql
-- This requires admin access to create test users
-- Alternatively, test with existing users who have the appropriate roles

-- Verify test user roles
SELECT
  u.email,
  r.key AS role_key,
  r.name AS role_name
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
JOIN roles r ON ur.role_key = r.key
WHERE u.email IN ('finance@test.com', 'admin@test.com', 'viewer@test.com')
ORDER BY u.email, r.key;
```

**Test 1: Finance User Permissions**

```sql
-- Set context to finance user (replace with actual finance user UUID)
SET LOCAL jwt.claims.sub = '<finance-user-uuid>';

-- Finance should be able to SELECT
SELECT COUNT(*) FROM charges;  -- Should succeed

-- Finance should be able to INSERT
INSERT INTO charges (investor_id, fund_id, contribution_id, status, base_amount, total_amount, currency, snapshot_json)
VALUES (1, 1, 666666, 'DRAFT', 1000.00, 1200.00, 'USD', '{}'::jsonb);  -- Should succeed

-- Finance should NOT be able to UPDATE
UPDATE charges SET status = 'APPROVED' WHERE contribution_id = 666666;  -- Should return 0 rows (policy blocks)

-- Finance should NOT be able to DELETE
DELETE FROM charges WHERE contribution_id = 666666;  -- Should return 0 rows (policy blocks)

-- Cleanup (as admin)
RESET jwt.claims.sub;
DELETE FROM charges WHERE contribution_id = 666666;
```

**Test 2: Admin User Permissions**

```sql
-- Set context to admin user (replace with actual admin user UUID)
SET LOCAL jwt.claims.sub = '<admin-user-uuid>';

-- Admin should be able to SELECT
SELECT COUNT(*) FROM charges;  -- Should succeed

-- Admin should be able to INSERT
INSERT INTO charges (investor_id, fund_id, contribution_id, status, base_amount, total_amount, currency, snapshot_json)
VALUES (1, 1, 555555, 'DRAFT', 1000.00, 1200.00, 'USD', '{}'::jsonb);  -- Should succeed

-- Admin should be able to UPDATE
UPDATE charges SET status = 'APPROVED' WHERE contribution_id = 555555;  -- Should succeed

-- Admin should be able to DELETE
DELETE FROM charges WHERE contribution_id = 555555;  -- Should succeed

RESET jwt.claims.sub;
```

**Test 3: Viewer User Permissions (Should Fail)**

```sql
-- Set context to viewer user (replace with actual viewer user UUID)
SET LOCAL jwt.claims.sub = '<viewer-user-uuid>';

-- Viewer should NOT be able to SELECT
SELECT COUNT(*) FROM charges;  -- Should return 0 rows (policy blocks)

RESET jwt.claims.sub;
```

### 3.4 Verify user_has_role() Function is Used

```sql
-- Check that policies use user_has_role() SECURITY DEFINER function
SELECT
  policyname,
  pg_get_expr(qual, 'charges'::regclass) AS using_clause,
  pg_get_expr(with_check, 'charges'::regclass) AS with_check_clause
FROM pg_policy
WHERE polrelid = 'charges'::regclass
AND policyname IN ('charges_insert_finance_admin', 'charges_update_admin', 'charges_delete_admin');
```

**Expected Output:**
Should show `user_has_role(auth.uid(), 'finance')` or `user_has_role(auth.uid(), 'admin')` in the clauses.

---

## DB-04: Service Role Verification

### 4.1 Document Service Role Behavior

**Service role key automatically bypasses ALL RLS policies in Supabase.**

**No SQL verification needed** - this is a Supabase platform feature.

### 4.2 Test Service Role Bypass (Application Code)

**In your Edge Function or API code:**

```typescript
// Using service role key
import { createClient } from '@supabase/supabase-js'

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!  // Service role key
)

// This will bypass RLS and return all charges
const { data: allCharges, error } = await supabaseAdmin
  .from('charges')
  .select('*')
  .eq('status', 'DRAFT')

console.log('Service role query returned:', allCharges?.length, 'charges')
// Should return ALL charges with status = DRAFT, regardless of RLS policies

// Using user JWT (anon key with auth)
const supabaseClient = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!  // Anon key
)

// Set user auth context
await supabaseClient.auth.setSession({ access_token, refresh_token })

// This will enforce RLS policies based on user role
const { data: userCharges, error: userError } = await supabaseClient
  .from('charges')
  .select('*')
  .eq('status', 'DRAFT')

console.log('User query returned:', userCharges?.length, 'charges')
// Will only return charges allowed by RLS policies for this user's role
```

### 4.3 Verify Table Comments

```sql
SELECT
  obj_description('charges'::regclass, 'pg_class') AS table_comment;
```

**Expected Output:**
```
table_comment
----------------------------------------------------------------------------------
Calculated referral fees on paid-in contributions. RLS: Finance+ can read, Finance/Admin can insert, Admin can update/delete. Service role bypasses RLS for batch operations.
```

---

## Complete Integration Test

### End-to-End Workflow Test

```sql
DO $$
DECLARE
  test_investor_id BIGINT := 1;
  test_fund_id BIGINT := 1;
  test_contribution_id BIGINT := 123456;
  test_charge_id UUID;
  test_charge_numeric_id BIGINT;
  test_credit_id BIGINT;
  test_application_id BIGINT;
BEGIN
  RAISE NOTICE '====================================';
  RAISE NOTICE 'v1.8.0 Integration Test';
  RAISE NOTICE '====================================';
  RAISE NOTICE '';

  -- Step 1: Create a charge (idempotent upsert)
  RAISE NOTICE 'Step 1: Creating charge via idempotent upsert...';
  INSERT INTO charges (
    investor_id, fund_id, contribution_id, status,
    base_amount, discount_amount, vat_amount, total_amount, currency, snapshot_json
  )
  VALUES (
    test_investor_id, test_fund_id, test_contribution_id, 'DRAFT',
    10000.00, 0, 2000.00, 12000.00, 'USD', '{"test": true}'::jsonb
  )
  ON CONFLICT (contribution_id) DO UPDATE
  SET
    base_amount = EXCLUDED.base_amount,
    total_amount = EXCLUDED.total_amount,
    updated_at = now()
  RETURNING id, numeric_id INTO test_charge_id, test_charge_numeric_id;

  RAISE NOTICE '✅ Charge created: id = %, numeric_id = %', test_charge_id, test_charge_numeric_id;

  -- Step 2: Create a credit for the investor
  RAISE NOTICE '';
  RAISE NOTICE 'Step 2: Creating credit for investor...';
  INSERT INTO credits_ledger (
    investor_id, fund_id, reason, original_amount, currency
  )
  VALUES (
    test_investor_id, test_fund_id, 'MANUAL', 5000.00, 'USD'
  )
  RETURNING id INTO test_credit_id;

  RAISE NOTICE '✅ Credit created: id = %, available_amount = 5000.00', test_credit_id;

  -- Step 3: Apply credit to charge
  RAISE NOTICE '';
  RAISE NOTICE 'Step 3: Applying credit to charge...';
  INSERT INTO credit_applications (
    credit_id, charge_id, amount_applied
  )
  VALUES (
    test_credit_id, test_charge_numeric_id, 5000.00
  )
  RETURNING id INTO test_application_id;

  RAISE NOTICE '✅ Credit applied: application_id = %, amount = 5000.00', test_application_id;

  -- Step 4: Update credits_ledger.applied_amount
  UPDATE credits_ledger
  SET applied_amount = applied_amount + 5000.00
  WHERE id = test_credit_id;

  RAISE NOTICE '✅ Credits ledger updated: applied_amount = 5000.00';

  -- Step 5: Verify data integrity
  RAISE NOTICE '';
  RAISE NOTICE 'Step 4: Verifying data integrity...';

  -- Check charge exists
  IF EXISTS (SELECT 1 FROM charges WHERE id = test_charge_id) THEN
    RAISE NOTICE '✅ Charge exists in database';
  ELSE
    RAISE EXCEPTION '❌ Charge not found';
  END IF;

  -- Check credit exists and has correct available_amount
  IF EXISTS (
    SELECT 1 FROM credits_ledger
    WHERE id = test_credit_id
    AND available_amount = 0
    AND status = 'FULLY_APPLIED'
  ) THEN
    RAISE NOTICE '✅ Credit fully applied (available_amount = 0, status = FULLY_APPLIED)';
  ELSE
    RAISE WARNING '⚠️  Credit not fully applied or status not updated';
  END IF;

  -- Check credit application exists
  IF EXISTS (
    SELECT 1 FROM credit_applications ca
    JOIN credits_ledger cl ON ca.credit_id = cl.id
    WHERE ca.id = test_application_id
    AND ca.charge_id = test_charge_numeric_id
  ) THEN
    RAISE NOTICE '✅ Credit application exists with correct FK relationships';
  ELSE
    RAISE EXCEPTION '❌ Credit application not found or FK broken';
  END IF;

  -- Step 6: Test idempotency - insert same charge again
  RAISE NOTICE '';
  RAISE NOTICE 'Step 5: Testing idempotency - inserting same charge again...';
  DECLARE
    second_charge_id UUID;
  BEGIN
    INSERT INTO charges (
      investor_id, fund_id, contribution_id, status,
      base_amount, discount_amount, vat_amount, total_amount, currency, snapshot_json
    )
    VALUES (
      test_investor_id, test_fund_id, test_contribution_id, 'DRAFT',
      15000.00, 0, 3000.00, 18000.00, 'USD', '{"test": true}'::jsonb
    )
    ON CONFLICT (contribution_id) DO UPDATE
    SET
      base_amount = EXCLUDED.base_amount,
      total_amount = EXCLUDED.total_amount,
      updated_at = now()
    RETURNING id INTO second_charge_id;

    IF test_charge_id = second_charge_id THEN
      RAISE NOTICE '✅ Idempotency verified - same charge ID returned';
    ELSE
      RAISE EXCEPTION '❌ Different charge ID - duplicate created!';
    END IF;

    -- Verify charge was updated
    IF EXISTS (
      SELECT 1 FROM charges
      WHERE id = test_charge_id
      AND base_amount = 15000.00
      AND total_amount = 18000.00
    ) THEN
      RAISE NOTICE '✅ Charge amounts updated via idempotent upsert';
    ELSE
      RAISE EXCEPTION '❌ Charge not updated';
    END IF;
  END;

  -- Cleanup
  RAISE NOTICE '';
  RAISE NOTICE 'Step 6: Cleaning up test data...';
  DELETE FROM credit_applications WHERE id = test_application_id;
  DELETE FROM charges WHERE id = test_charge_id;
  DELETE FROM credits_ledger WHERE id = test_credit_id;

  RAISE NOTICE '✅ Test data cleaned up';
  RAISE NOTICE '';
  RAISE NOTICE '====================================';
  RAISE NOTICE '✅ All tests passed!';
  RAISE NOTICE '====================================';

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Test failed: %', SQLERRM;
    -- Rollback handled by transaction
END $$;
```

**Expected Output:**
```
NOTICE:  ====================================
NOTICE:  v1.8.0 Integration Test
NOTICE:  ====================================
NOTICE:
NOTICE:  Step 1: Creating charge via idempotent upsert...
NOTICE:  ✅ Charge created: id = <UUID>, numeric_id = <BIGINT>
NOTICE:
NOTICE:  Step 2: Creating credit for investor...
NOTICE:  ✅ Credit created: id = <BIGINT>, available_amount = 5000.00
NOTICE:
NOTICE:  Step 3: Applying credit to charge...
NOTICE:  ✅ Credit applied: application_id = <BIGINT>, amount = 5000.00
NOTICE:  ✅ Credits ledger updated: applied_amount = 5000.00
NOTICE:
NOTICE:  Step 4: Verifying data integrity...
NOTICE:  ✅ Charge exists in database
NOTICE:  ✅ Credit fully applied (available_amount = 0, status = FULLY_APPLIED)
NOTICE:  ✅ Credit application exists with correct FK relationships
NOTICE:
NOTICE:  Step 5: Testing idempotency - inserting same charge again...
NOTICE:  ✅ Idempotency verified - same charge ID returned
NOTICE:  ✅ Charge amounts updated via idempotent upsert
NOTICE:
NOTICE:  Step 6: Cleaning up test data...
NOTICE:  ✅ Test data cleaned up
NOTICE:
NOTICE:  ====================================
NOTICE:  ✅ All tests passed!
NOTICE:  ====================================
```

---

## Performance Testing

### Test FIFO Credit Query Performance

```sql
EXPLAIN ANALYZE
SELECT
  id,
  investor_id,
  fund_id,
  available_amount,
  original_amount,
  applied_amount,
  currency,
  created_at
FROM credits_ledger
WHERE investor_id = 1
  AND fund_id = 1
  AND available_amount > 0
  AND status = 'AVAILABLE'
ORDER BY created_at ASC
LIMIT 10;
```

**Expected Plan:**
```
Index Scan using idx_credits_ledger_investor_fund_fifo on credits_ledger
  (cost=0.xx..x.xx rows=x width=xx)
  (actual time=0.xxx..0.xxx rows=x loops=1)
  Index Cond: ((investor_id = 1) AND (fund_id = 1))
  Filter: ((available_amount > '0'::numeric) AND (status = 'AVAILABLE'::text))
Planning Time: x.xxx ms
Execution Time: x.xxx ms
```

Should show **Index Scan** using `idx_credits_ledger_investor_fund_fifo` (not Seq Scan).

### Test Charge Idempotent Upsert Performance

```sql
EXPLAIN ANALYZE
INSERT INTO charges (
  investor_id, fund_id, contribution_id, status,
  base_amount, total_amount, currency, snapshot_json
)
VALUES (
  1, 1, 999999, 'DRAFT',
  10000.00, 12000.00, 'USD', '{"test": true}'::jsonb
)
ON CONFLICT (contribution_id) DO UPDATE
SET
  base_amount = EXCLUDED.base_amount,
  total_amount = EXCLUDED.total_amount,
  updated_at = now();
```

**Expected Plan:**
```
Insert on charges  (cost=x.xx..x.xx rows=x width=xxx)
  Conflict Resolution: UPDATE
  Conflict Arbiter Indexes: idx_charges_contribution_unique
Planning Time: x.xxx ms
Execution Time: x.xxx ms
```

Should show conflict resolution using `idx_charges_contribution_unique`.

---

## Acceptance Criteria Checklist

### DB-01: Unique Index on charges.contribution_id

- [ ] Unique index `idx_charges_contribution_unique` exists on `charges(contribution_id)`
- [ ] Attempting to insert duplicate `contribution_id` fails with unique constraint violation
- [ ] Migration is idempotent (can be run multiple times safely)
- [ ] Idempotent upsert pattern works: `INSERT ... ON CONFLICT (contribution_id) DO UPDATE`
- [ ] Same charge ID returned on repeated upsert (no duplicates created)

### DB-02: FK Constraint from credit_applications to credits_ledger

- [ ] FK constraint `credit_applications_credit_id_fkey` points to `credits_ledger.id`
- [ ] Data types match (`credit_applications.credit_id` and `credits_ledger.id` are both BIGINT)
- [ ] Test insert: Create credit in `credits_ledger`, then create `credit_application` (succeeds)
- [ ] Test violation: Insert `credit_application` with non-existent `credit_id` (fails with FK violation)
- [ ] ON DELETE RESTRICT behavior verified

### DB-03: RLS Policies for Charges

- [ ] RLS enabled on `charges` table
- [ ] All 4 policies exist: SELECT, INSERT, UPDATE, DELETE
- [ ] Finance user: can SELECT, can INSERT, cannot UPDATE, cannot DELETE
- [ ] Admin user: can SELECT, INSERT, UPDATE, DELETE
- [ ] Viewer user: cannot SELECT, INSERT, UPDATE, DELETE
- [ ] Policies use existing `user_has_role()` security definer function
- [ ] No infinite recursion in RLS policies

### DB-04: Service Role Operations

- [ ] Service role operations (using `SUPABASE_SERVICE_ROLE_KEY`) bypass RLS
- [ ] Test: Use service role key to query `charges` table (returns all rows regardless of RLS)
- [ ] Documented: Service role key auth bypasses RLS, user JWT auth enforces RLS
- [ ] Table comment includes service role documentation

---

## Rollback Procedures

If you need to rollback the migration:

```sql
-- Remove RLS policies (keep table and data)
DROP POLICY IF EXISTS "charges_insert_finance_admin" ON charges;
DROP POLICY IF EXISTS "charges_update_admin" ON charges;
DROP POLICY IF EXISTS "charges_delete_admin" ON charges;

-- Recreate old "Admin can manage all charges" policy (if needed)
CREATE POLICY "Admin can manage all charges"
  ON charges
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role_key = 'admin'
    )
  );

-- Note: Do NOT drop idx_charges_contribution_unique or FK constraint
-- These are critical for data integrity and were created in v1.7.0
```

---

## Summary

This verification guide covers all acceptance criteria for v1.8.0 schema changes:

1. **DB-01**: Unique index for idempotent charge compute
2. **DB-02**: FK constraint from credit_applications to credits_ledger
3. **DB-03**: Granular RLS policies for charges table
4. **DB-04**: Service role behavior documentation

Run all verification queries in sequence to ensure the migration was successful.

**Next Steps:**
1. Run verification queries on staging environment
2. Test with actual user roles (finance, admin, viewer)
3. Test Edge Functions using service role key
4. Deploy to production after verification passes
