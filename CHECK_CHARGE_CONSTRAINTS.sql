-- Check constraints on credit_applications table that might be failing
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'credit_applications'::regclass;

-- Check if applied_by column exists and its definition
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'credit_applications'
  AND column_name IN ('applied_by', 'reversed_by', 'charge_id', 'credit_id');

-- Check recent errors in audit_log if any
SELECT
    created_at,
    event_type,
    actor_id,
    entity_type,
    payload
FROM audit_log
ORDER BY created_at DESC
LIMIT 10;
