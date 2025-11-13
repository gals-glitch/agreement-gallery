-- STEP 0: Minimal counts check
-- Only uses columns we know exist: id, name, source_kind, external_id

-- Total counts by source
SELECT
  COALESCE(source_kind::text, 'NULL') AS source_kind,
  COUNT(*) AS count
FROM public.investors
GROUP BY source_kind
ORDER BY count DESC;

-- Find duplicate names between DISTRIBUTOR and vantage
WITH base AS (
  SELECT
    id,
    name,
    lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS norm_name,
    source_kind,
    external_id
  FROM public.investors
)
SELECT
  d.id AS distributor_id,
  d.name AS distributor_name,
  v.id AS vantage_id,
  v.name AS vantage_name,
  v.external_id AS vantage_external_id
FROM base d
JOIN base v
  ON v.source_kind = 'vantage'
  AND d.source_kind = 'DISTRIBUTOR'
  AND v.norm_name = d.norm_name
ORDER BY d.name;
