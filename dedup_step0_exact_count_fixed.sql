-- STEP 0: Exact counts & visibility
-- Shows total investors, by source, and duplicate pairs by name
-- Safe to run - read-only query

-- First, let's check what columns actually exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'investors'
ORDER BY ordinal_position;

-- Now the actual counts
WITH base AS (
  SELECT id, name, lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS norm_name,
         source_kind, tax_id, external_id
  FROM public.investors
),
pairs_name AS (
  SELECT d.id AS distributor_id, v.id AS vantage_id, d.name
  FROM base d
  JOIN base v ON v.source_kind='vantage' AND d.source_kind='DISTRIBUTOR'
             AND v.norm_name = d.norm_name
),
pairs_tax AS (
  SELECT d.id AS distributor_id, v.id AS vantage_id, d.tax_id
  FROM base d
  JOIN base v ON v.source_kind='vantage' AND d.source_kind='DISTRIBUTOR'
             AND d.tax_id IS NOT NULL AND v.tax_id IS NOT NULL
             AND d.tax_id = v.tax_id
)
SELECT 'total' AS metric, COUNT(*)::text AS value FROM public.investors
UNION ALL
SELECT 'vantage', COUNT(*)::text FROM public.investors WHERE source_kind='vantage'
UNION ALL
SELECT 'distributor', COUNT(*)::text FROM public.investors WHERE source_kind='DISTRIBUTOR'
UNION ALL
SELECT 'dup_name_pairs', COUNT(*)::text FROM pairs_name
UNION ALL
SELECT 'dup_taxid_pairs', COUNT(*)::text FROM pairs_tax
ORDER BY 1;

-- Optional: See the actual name-pair list
WITH base AS (
  SELECT id, name, lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS norm_name,
         source_kind, tax_id, external_id
  FROM public.investors
)
SELECT d.id AS distributor_id, d.name AS distributor_name,
       v.id AS vantage_id, v.name AS vantage_name,
       d.tax_id AS dist_tax_id, v.tax_id AS vant_tax_id
FROM base d
JOIN base v ON v.source_kind='vantage' AND d.source_kind='DISTRIBUTOR'
           AND v.norm_name = d.norm_name
ORDER BY d.name
LIMIT 50;
