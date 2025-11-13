-- Check credits_ledger table schema to see if available_amount is generated
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_generated,
    generation_expression
FROM information_schema.columns
WHERE table_name = 'credits_ledger'
ORDER BY ordinal_position;
