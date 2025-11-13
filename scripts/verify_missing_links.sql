-- ============================================
-- Verification: Investors without party links
-- ============================================
-- Shows investors who still need introduced_by_party_id set
-- These investors cannot have commissions computed

-- Summary count
SELECT COUNT(*) AS investors_without_party
FROM investors
WHERE introduced_by_party_id IS NULL;

-- Detailed list with notes preview
SELECT
  id,
  name,
  LEFT(notes, 100) AS notes_preview,
  created_at
FROM investors
WHERE introduced_by_party_id IS NULL
ORDER BY name;

-- Show potential backfill candidates
-- (investors with "Introduced by" in notes but no party link)
SELECT
  i.name AS investor_name,
  trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')) AS extracted_party_name,
  CASE
    WHEN EXISTS (SELECT 1 FROM parties p WHERE p.name = trim(regexp_replace(i.notes, '.*Introduced by:\s*([^;]+).*', '\1')))
    THEN 'Party exists - can backfill'
    ELSE 'Party not found - needs manual mapping'
  END AS backfill_status
FROM investors i
WHERE i.introduced_by_party_id IS NULL
  AND i.notes ~ 'Introduced by:\s*'
ORDER BY backfill_status, i.name;
