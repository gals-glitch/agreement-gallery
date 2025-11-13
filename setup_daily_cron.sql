-- Setup daily Vantage sync via pg_cron
-- Runs at 00:00 UTC daily (approximately 02:00 Asia/Jerusalem)

-- Step 1: Enable extensions if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Step 2: Create secrets table to store service role key securely
CREATE TABLE IF NOT EXISTS public.secrets (
  k TEXT PRIMARY KEY,
  v TEXT NOT NULL
);

-- Step 3: Store service role key
-- IMPORTANT: Replace 'YOUR_SERVICE_ROLE_KEY' with actual key
INSERT INTO public.secrets (k, v)
VALUES ('service_role', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2ljcmRjb3Fka2V0cWh4YnlzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzIyNjMwNywiZXhwIjoyMDcyODAyMzA3fQ.bPUTKQM-tOm1u_1NlVNXczSbA118443uOpeo2Waa2zo')
ON CONFLICT (k) DO UPDATE SET v = EXCLUDED.v;

-- Step 4: Create helper function to run incremental sync
CREATE OR REPLACE FUNCTION public.run_vantage_incremental()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  svc_key TEXT;
  response_id BIGINT;
BEGIN
  -- Get service role key from secrets
  SELECT v INTO svc_key FROM public.secrets WHERE k = 'service_role';

  IF svc_key IS NULL THEN
    RAISE EXCEPTION 'Service role key not found in secrets table';
  END IF;

  -- Call vantage-sync Edge Function via HTTP
  SELECT net.http_post(
    url     => 'https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync',
    headers => jsonb_build_object(
      'Authorization', 'Bearer ' || svc_key,
      'Content-Type', 'application/json'
    ),
    body    => jsonb_build_object(
      'mode', 'incremental',
      'resources', jsonb_build_array('accounts', 'funds'),
      'dryRun', false
    )
  ) INTO response_id;

  -- Log the request
  RAISE NOTICE 'Vantage incremental sync triggered, request_id: %', response_id;
END $$;

-- Step 5: Schedule daily sync at 00:00 UTC
SELECT cron.schedule(
  'vantage-daily-sync',
  '0 0 * * *',
  $$SELECT public.run_vantage_incremental();$$
);

-- Step 6: Verify cron job was created
SELECT
  jobid,
  schedule,
  command,
  nodename,
  nodeport,
  database,
  username,
  active
FROM cron.job
WHERE jobname = 'vantage-daily-sync';

-- Optional: To manually test the function
-- SELECT public.run_vantage_incremental();

-- Optional: To unschedule the job (if needed)
-- SELECT cron.unschedule('vantage-daily-sync');
