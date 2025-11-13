-- Verify the charge created for contribution 3
SELECT
  id as charge_id,
  numeric_id,
  contribution_id,
  investor_id,
  deal_id,
  status,
  base_amount,
  discount_amount,
  vat_amount,
  total_amount,
  credits_applied_amount,
  net_amount,
  currency,
  computed_at,
  created_at
FROM charges
WHERE contribution_id = 3
ORDER BY created_at DESC;
