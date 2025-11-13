-- Step 1: See what contributions exist
SELECT
  id as contribution_id,
  investor_id,
  amount,
  currency,
  paid_in_date,
  fund_id,
  deal_id
FROM contributions
ORDER BY id
LIMIT 10;

-- Step 2: See what investors exist
SELECT
  id as investor_id,
  name
FROM investors
ORDER BY id
LIMIT 10;

-- Step 3: See what deals exist
SELECT
  id as deal_id,
  name,
  fund_id
FROM deals
ORDER BY id
LIMIT 5;

-- Step 4: Cross-reference - which investor is party_id 1?
SELECT
  id as party_id,
  name as party_name
FROM investors
WHERE id = 1;

-- Step 5: Summary - show mismatches
SELECT
  'Contributions exist for investor_id' as info,
  COALESCE(STRING_AGG(DISTINCT investor_id::text, ', '), 'NONE') as investor_ids
FROM contributions
UNION ALL
SELECT
  'Agreements exist for party_id' as info,
  COALESCE(STRING_AGG(DISTINCT party_id::text, ', '), 'NONE') as party_ids
FROM agreements;
