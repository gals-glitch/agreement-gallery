-- Get full details for contributions of investors 201 and 1338
SELECT
  c.id as contribution_id,
  c.investor_id,
  i.name as investor_name,
  c.amount,
  c.currency,
  c.paid_in_date,
  c.fund_id,
  f.name as fund_name,
  c.deal_id,
  d.name as deal_name
FROM contributions c
JOIN investors i ON c.investor_id = i.id
LEFT JOIN funds f ON c.fund_id = f.id
LEFT JOIN deals d ON c.deal_id = d.id
WHERE c.investor_id IN (201, 1338)
ORDER BY c.id;
