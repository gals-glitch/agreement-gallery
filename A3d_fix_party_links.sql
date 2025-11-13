-- Fix investor→party links where names don't match exactly

BEGIN;

-- Fix "Kuperman Capital" → "Kuperman"
UPDATE investors
SET introduced_by_party_id = (SELECT id FROM parties WHERE name = 'Kuperman' LIMIT 1)
WHERE notes LIKE '%Introduced by: Kuperman Capital%'
  AND introduced_by_party_id IS NULL;

-- Fix "Shai Sheffer" → "Shai Sheffer (DGTA)"
UPDATE investors
SET introduced_by_party_id = (SELECT id FROM parties WHERE name LIKE 'Shai Sheffer%' LIMIT 1)
WHERE notes LIKE '%Introduced by: Shai Sheffer%'
  AND introduced_by_party_id IS NULL;

-- Fix "Michael Mann" → "Wiser Finance- Michael Mann..."
UPDATE investors
SET introduced_by_party_id = (SELECT id FROM parties WHERE name LIKE '%Michael Mann%' LIMIT 1)
WHERE notes LIKE '%Introduced by: Michael Mann%'
  AND introduced_by_party_id IS NULL;

-- Fix "Yoram Dvash" → "Yoram Dvash -Fresh Properties"
UPDATE investors
SET introduced_by_party_id = (SELECT id FROM parties WHERE name LIKE 'Yoram Dvash%' LIMIT 1)
WHERE notes LIKE '%Introduced by: Yoram Dvash%'
  AND introduced_by_party_id IS NULL;

-- Fix "Lior Cohen" → "Lior Cohen" or "Lior Cohen (ThinkWise Consulting)"
UPDATE investors
SET introduced_by_party_id = (SELECT id FROM parties WHERE name LIKE 'Lior Cohen%' LIMIT 1)
WHERE notes LIKE '%Introduced by: Lior Cohen%'
  AND introduced_by_party_id IS NULL;

-- Note: "Inspire Finance" and "Guy Moses" don't have exact matches
-- These will remain NULL unless we add those parties to the parties table

COMMIT;

-- Verification
SELECT
  COUNT(*) as total_investors,
  COUNT(introduced_by_party_id) as with_party_link,
  COUNT(*) - COUNT(introduced_by_party_id) as without_party_link
FROM investors;

-- Show remaining unlinked investors
SELECT
  name,
  SUBSTRING(notes FROM 'Introduced by: ([^;]+)') as party_ref
FROM investors
WHERE notes LIKE '%Introduced by:%'
  AND introduced_by_party_id IS NULL
LIMIT 10;
