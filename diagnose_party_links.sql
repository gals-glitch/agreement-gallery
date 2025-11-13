-- Find investors with DISTRIBUTOR source but no party link
SELECT 
  name,
  source_kind,
  introduced_by_party_id,
  notes
FROM investors
WHERE source_kind = 'DISTRIBUTOR' 
  AND introduced_by_party_id IS NULL
ORDER BY name
LIMIT 10;

-- Check what party names are referenced in notes
SELECT 
  SUBSTRING(notes FROM 'Introduced by: (.*)') as party_name_in_notes,
  COUNT(*) as count
FROM investors
WHERE source_kind = 'DISTRIBUTOR' 
  AND introduced_by_party_id IS NULL
  AND notes LIKE 'Introduced by:%'
GROUP BY party_name_in_notes
ORDER BY count DESC;

-- Check actual party names in database
SELECT name FROM parties WHERE active = true ORDER BY name LIMIT 20;
