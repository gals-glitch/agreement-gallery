-- STEP 2: Create merge_investors() function
-- Dynamically finds all FK references and updates them
-- Soft-deactivates source record and logs everything
-- Safe to run multiple times (CREATE OR REPLACE)

CREATE OR REPLACE FUNCTION public.merge_investors(src_id BIGINT, dst_id BIGINT, reason TEXT DEFAULT 'dedup')
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  r RECORD;
  updated_rows BIGINT;
  moved JSONB := '{}'::jsonb;
BEGIN
  -- Validation
  IF src_id = dst_id THEN
    RAISE EXCEPTION 'src_id and dst_id must differ';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.investors WHERE id = src_id) THEN
    RAISE EXCEPTION 'Source investor % not found', src_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.investors WHERE id = dst_id) THEN
    RAISE EXCEPTION 'Destination investor % not found', dst_id;
  END IF;

  -- Update all FK references dynamically
  FOR r IN
    SELECT
      tc.table_schema,
      tc.table_name,
      kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON kcu.constraint_name = tc.constraint_name
     AND kcu.constraint_schema = tc.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_schema = 'public'
      AND ccu.table_name   = 'investors'
      AND ccu.column_name  = 'id'
  LOOP
    EXECUTE format(
      'UPDATE %I.%I SET %I = $1 WHERE %I = $2',
      r.table_schema, r.table_name, r.column_name, r.column_name
    )
    USING dst_id, src_id;

    GET DIAGNOSTICS updated_rows = ROW_COUNT;

    IF updated_rows > 0 THEN
      moved := moved || jsonb_build_object(
        (r.table_schema||'.'||r.table_name||'.'||r.column_name), updated_rows
      );
    END IF;
  END LOOP;

  -- Soft-close source investor
  UPDATE public.investors
  SET merged_into_id = dst_id,
      is_active = FALSE,
      updated_at = now(),
      notes = concat_ws(E'\n',
               notes,
               format('[%s] merged into investor %s (reason: %s)', now()::timestamptz, dst_id, reason)
             )
  WHERE id = src_id;

  -- Log the merge
  INSERT INTO public.investor_merge_log (src_id, dst_id, reason, moved_fk)
  VALUES (src_id, dst_id, reason, moved);

  RETURN jsonb_build_object(
    'src_id', src_id,
    'dst_id', dst_id,
    'moved_fk', moved
  );
END $$;

-- Test the function is created
SELECT 'merge_investors function created' AS status,
       proname AS function_name
FROM pg_proc
WHERE proname = 'merge_investors'
  AND pronamespace = 'public'::regnamespace;
