-- Check what selected_track values exist in agreements
SELECT
  id,
  party_id,
  pricing_mode,
  selected_track,
  status
FROM agreements
WHERE id IN (1, 6)
ORDER BY id;

-- Check the enum definition for selected_track
SELECT
  t.typname AS enum_type,
  e.enumlabel AS enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname LIKE '%track%'
ORDER BY t.typname, e.enumsortorder;
