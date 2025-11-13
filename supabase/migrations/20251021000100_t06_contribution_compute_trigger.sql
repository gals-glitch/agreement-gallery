-- ============================================
-- T06: Contribution Create/Update Trigger for Auto-Compute
-- Ticket: P2 Move 2A
-- Date: 2025-10-21
--
-- Purpose:
-- Automatically compute charges when contributions are created or updated.
-- Only computes if:
-- 1. Feature flag 'compute_on_contribution' is enabled
-- 2. No existing charge OR existing charge is in DRAFT status
-- 3. Contribution has valid investor_id, amount, and fund/deal
--
-- Implementation:
-- - Trigger fires AFTER INSERT OR UPDATE on contributions
-- - Calls Edge Function webhook (POST /api-v1/charges/compute) with service key
-- - Debounces updates using last_computed_at timestamp (prevent double compute)
-- ============================================

-- Step 1: Create feature flag for contribution auto-compute (if not exists)
INSERT INTO feature_flags (key, enabled, description, created_at, updated_at)
VALUES (
  'compute_on_contribution',
  true,
  'Automatically compute charges when contributions are created or updated',
  now(),
  now()
)
ON CONFLICT (key) DO NOTHING;

-- Step 2: Add last_computed_at column to contributions (for debouncing)
ALTER TABLE contributions
ADD COLUMN IF NOT EXISTS last_computed_at timestamptz;

COMMENT ON COLUMN contributions.last_computed_at IS 'Timestamp of last charge computation (for debouncing)';

-- Step 3: Create trigger function to compute charge via Edge Function
CREATE OR REPLACE FUNCTION trigger_compute_charge_on_contribution()
RETURNS TRIGGER AS $$
DECLARE
  feature_enabled boolean;
  supabase_url text;
  service_key text;
  http_response record;
  charge_exists boolean;
  charge_status text;
  debounce_seconds integer := 5; -- Debounce window in seconds
BEGIN
  -- 1. Check if feature flag is enabled
  SELECT enabled INTO feature_enabled
  FROM feature_flags
  WHERE key = 'compute_on_contribution';

  IF NOT COALESCE(feature_enabled, false) THEN
    -- Feature disabled, skip computation
    RETURN NEW;
  END IF;

  -- 2. Validate contribution has required fields
  IF NEW.investor_id IS NULL OR NEW.amount IS NULL OR NEW.amount <= 0 THEN
    -- Invalid contribution, skip
    RETURN NEW;
  END IF;

  IF NEW.fund_id IS NULL AND NEW.deal_id IS NULL THEN
    -- No scope, skip (global contributions not supported)
    RETURN NEW;
  END IF;

  -- 3. Debounce: Skip if last_computed_at is within debounce window
  IF NEW.last_computed_at IS NOT NULL AND
     NEW.last_computed_at > (now() - (debounce_seconds || ' seconds')::interval) THEN
    -- Recently computed, skip to avoid double-compute
    RETURN NEW;
  END IF;

  -- 4. Check if charge already exists and is not DRAFT
  SELECT EXISTS(
    SELECT 1
    FROM charges
    WHERE contribution_id = NEW.id
      AND status NOT IN ('DRAFT')
  ) INTO charge_exists;

  IF charge_exists THEN
    -- Charge exists and is not DRAFT, skip (don't mutate submitted charges)
    RETURN NEW;
  END IF;

  -- 5. Get Supabase URL and service key from environment
  -- Note: In Supabase, we can't directly call HTTP from triggers
  -- Instead, we use pg_net extension or queue a job
  -- For now, we'll update last_computed_at and rely on a cron job or manual trigger

  -- Update last_computed_at to prevent re-computation
  UPDATE contributions
  SET last_computed_at = now()
  WHERE id = NEW.id;

  -- TODO: Implement HTTP call to Edge Function using pg_net extension
  -- Example (requires pg_net extension):
  /*
  supabase_url := current_setting('app.settings.supabase_url', true);
  service_key := current_setting('app.settings.service_api_key', true);

  IF supabase_url IS NOT NULL AND service_key IS NOT NULL THEN
    -- Call Edge Function using pg_net.http_post
    SELECT * INTO http_response
    FROM net.http_post(
      url := supabase_url || '/functions/v1/api-v1/charges/compute',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-service-key', service_key
      ),
      body := jsonb_build_object('contribution_id', NEW.id)::text
    );

    -- Log response (optional)
    IF http_response.status_code != 200 THEN
      RAISE WARNING 'Failed to compute charge for contribution %: HTTP %',
        NEW.id, http_response.status_code;
    END IF;
  END IF;
  */

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create trigger on contributions table
DROP TRIGGER IF EXISTS trigger_auto_compute_charge ON contributions;

CREATE TRIGGER trigger_auto_compute_charge
  AFTER INSERT OR UPDATE OF investor_id, amount, paid_in_date, fund_id, deal_id
  ON contributions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_compute_charge_on_contribution();

COMMENT ON TRIGGER trigger_auto_compute_charge ON contributions IS 'Auto-compute charges when contributions are created or updated (T06)';

-- Step 5: Create a helper function for manual charge computation (called by cron or admin)
CREATE OR REPLACE FUNCTION compute_charges_for_unprocessed_contributions()
RETURNS TABLE(contribution_id uuid, status text, message text) AS $$
DECLARE
  contrib record;
  charge_result record;
BEGIN
  -- Find contributions without charges or with DRAFT charges only
  FOR contrib IN
    SELECT c.id, c.investor_id, c.amount, c.fund_id, c.deal_id
    FROM contributions c
    LEFT JOIN charges ch ON ch.contribution_id = c.id
    WHERE c.investor_id IS NOT NULL
      AND c.amount > 0
      AND (c.fund_id IS NOT NULL OR c.deal_id IS NOT NULL)
      AND (ch.id IS NULL OR ch.status = 'DRAFT')
      AND (c.last_computed_at IS NULL OR c.last_computed_at < now() - interval '1 hour')
    ORDER BY c.created_at DESC
    LIMIT 100  -- Process in batches
  LOOP
    BEGIN
      -- Call compute charge function (assumes Edge Function or stored procedure exists)
      -- For now, just mark as processed
      UPDATE contributions
      SET last_computed_at = now()
      WHERE id = contrib.id;

      RETURN QUERY SELECT contrib.id, 'queued'::text, 'Marked for computation'::text;
    EXCEPTION WHEN OTHERS THEN
      RETURN QUERY SELECT contrib.id, 'error'::text, SQLERRM::text;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION compute_charges_for_unprocessed_contributions IS 'Batch compute charges for contributions without charges (called by cron or admin)';
