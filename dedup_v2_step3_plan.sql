-- STEP 3: Build merge plan (the 22 name-matches)
-- Creates a temp table with DISTRIBUTOR → Vantage pairs
-- Safe to run - creates temp table that auto-drops on commit

CREATE TEMP TABLE investor_merge_plan (
  src_id BIGINT,   -- DISTRIBUTOR source (will be merged INTO dst_id)
  dst_id BIGINT,   -- vantage source (canonical record)
  reason TEXT
);

-- Fill with exact normalized name matches
WITH base AS (
  SELECT
    id,
    name,
    lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS norm_name,
    source_kind,
    external_id
  FROM public.investors
)
INSERT INTO investor_merge_plan (src_id, dst_id, reason)
SELECT d.id, v.id, 'name_match'
FROM base d
JOIN base v
  ON v.source_kind = 'vantage'
  AND d.source_kind = 'DISTRIBUTOR'
  AND v.norm_name = d.norm_name;

-- Review the merge plan before executing
-- Shows DISTRIBUTOR record → Vantage record pairs
SELECT
  p.src_id AS distributor_id,
  d.name AS distributor_name,
  p.dst_id AS vantage_id,
  v.name AS vantage_name,
  v.external_id AS vant_external_id,
  p.reason
FROM investor_merge_plan p
JOIN public.investors d ON d.id = p.src_id
JOIN public.investors v ON v.id = p.dst_id
ORDER BY d.name;

-- Summary statistics
SELECT
  COUNT(*) AS total_pairs_to_merge,
  COUNT(DISTINCT p.src_id) AS unique_distributor_records,
  COUNT(DISTINCT p.dst_id) AS unique_vantage_records
FROM investor_merge_plan p;
