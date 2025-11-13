-- Check the current status of the charge being tested
SELECT
    id,
    numeric_id,
    contribution_id,
    status,
    base_amount,
    vat_amount,
    total_amount,
    credits_applied_amount,
    net_amount,
    submitted_at,
    approved_at,
    rejected_at,
    paid_at,
    created_at,
    updated_at
FROM charges
WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd';

-- Also check if there are any credit applications for this charge
SELECT
    ca.id,
    ca.credit_id,
    ca.charge_id,
    ca.amount_applied,
    ca.applied_by,
    ca.applied_at,
    ca.reversed_at,
    ca.reversed_by
FROM credit_applications ca
WHERE ca.charge_id = (
    SELECT numeric_id FROM charges WHERE id = 'a0fb4b54-5e29-437b-beaf-99e4f2bcc4bd'
);
