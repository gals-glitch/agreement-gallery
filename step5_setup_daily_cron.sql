-- Step 5: Schedule daily incremental Vantage sync
-- Runs at 00:00 UTC daily (≈ 02:00 Asia/Jerusalem)

-- Enable required extensions (no-op if already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create secrets table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.secrets (
    k TEXT PRIMARY KEY,
    v TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Store service role key (REPLACE XXX with actual key)
-- WARNING: Keep this secure! Consider using Supabase Vault instead
INSERT INTO public.secrets (k, v)
VALUES ('service_role', 'YOUR_SERVICE_ROLE_KEY_HERE')
ON CONFLICT (k) DO UPDATE SET v = EXCLUDED.v, updated_at = NOW();

-- Helper function to trigger the Edge Function
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

    -- Call the Edge Function via HTTP POST
    SELECT INTO response_id net.http_post(
        url     := 'https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/vantage-sync',
        headers := jsonb_build_object(
            'Authorization', 'Bearer ' || svc_key,
            'Content-Type', 'application/json'
        ),
        body    := jsonb_build_object(
            'mode', 'incremental',
            'resources', jsonb_build_array('accounts', 'funds')
        )
    );

    -- Log the trigger (optional)
    RAISE NOTICE 'Vantage incremental sync triggered at %', NOW();
END;
$$;

-- Schedule the job to run daily at 00:00 UTC
-- This is approximately 02:00 Asia/Jerusalem time (varies with DST)
SELECT cron.schedule(
    'vantage-daily-sync',           -- Job name
    '0 0 * * *',                    -- Cron expression: daily at midnight UTC
    $$SELECT public.run_vantage_incremental();$$
);

-- Verify the scheduled job
SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'vantage-daily-sync';

-- To manually test the function:
-- SELECT public.run_vantage_incremental();

-- To unschedule (if needed):
-- SELECT cron.unschedule('vantage-daily-sync');

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.run_vantage_incremental() TO postgres;

COMMENT ON FUNCTION public.run_vantage_incremental() IS
'Triggers daily incremental Vantage IR sync via Edge Function. Scheduled to run at 00:00 UTC.';
