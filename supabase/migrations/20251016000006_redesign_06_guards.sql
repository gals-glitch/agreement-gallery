-- Migration: 06_guards.sql
-- Purpose: Immutability triggers and snapshot automation
-- Date: 2025-10-16

-- ============================================
-- TRIGGER 1: Prevent updates to APPROVED agreements
-- ============================================
CREATE OR REPLACE FUNCTION prevent_update_on_approved()
RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'APPROVED' AND (NEW.* IS DISTINCT FROM OLD.*) THEN
    RAISE EXCEPTION 'Approved agreements are immutable. Use Amendment flow to create a new version.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='agreements_lock_after_approval') THEN
    CREATE TRIGGER agreements_lock_after_approval
    BEFORE UPDATE ON agreements
    FOR EACH ROW
    WHEN (OLD.status = 'APPROVED')
    EXECUTE PROCEDURE prevent_update_on_approved();
  END IF;
END $$;

COMMENT ON FUNCTION prevent_update_on_approved IS 'Trigger function: Blocks any updates to APPROVED agreements';

-- ============================================
-- TRIGGER 2: Auto-create rate snapshot on approval
-- ============================================
CREATE OR REPLACE FUNCTION snapshot_rates_on_approval()
RETURNS trigger AS $$
DECLARE
  up_bps INT;
  def_bps INT;
  seed_ver INT;
  target_fund_id BIGINT;
BEGIN
  -- Only run when transitioning TO 'APPROVED'
  IF NEW.status = 'APPROVED' AND OLD.status IS DISTINCT FROM 'APPROVED' THEN

    -- Determine target fund_id for track lookup
    IF NEW.scope = 'FUND' THEN
      target_fund_id := NEW.fund_id;
    ELSIF NEW.scope = 'DEAL' THEN
      SELECT fund_id INTO target_fund_id FROM deals WHERE id = NEW.deal_id;
    END IF;

    -- Resolve rates based on pricing_mode
    IF NEW.pricing_mode = 'TRACK' THEN
      -- Look up track rates from fund_tracks
      SELECT ft.upfront_bps, ft.deferred_bps, ft.seed_version
        INTO up_bps, def_bps, seed_ver
      FROM fund_tracks ft
      WHERE ft.fund_id = target_fund_id
        AND ft.track_code = NEW.selected_track
        AND ft.valid_from <= NEW.effective_from
        AND (ft.valid_to IS NULL OR ft.valid_to >= NEW.effective_from)
      ORDER BY ft.valid_from DESC
      LIMIT 1;

      IF up_bps IS NULL OR def_bps IS NULL THEN
        RAISE EXCEPTION 'Cannot approve agreement %: Track % rates not found for fund %',
          NEW.id, NEW.selected_track, target_fund_id;
      END IF;

    ELSIF NEW.pricing_mode = 'CUSTOM' THEN
      -- Look up custom rates
      SELECT act.upfront_bps, act.deferred_bps
        INTO up_bps, def_bps
      FROM agreement_custom_terms act
      WHERE act.agreement_id = NEW.id;

      IF up_bps IS NULL OR def_bps IS NULL THEN
        RAISE EXCEPTION 'Cannot approve agreement %: Custom terms not defined', NEW.id;
      END IF;

      seed_ver := NULL;  -- No seed_version for custom rates
    END IF;

    -- Insert snapshot (idempotent via ON CONFLICT)
    INSERT INTO agreement_rate_snapshots(
      agreement_id, scope, pricing_mode, track_code,
      resolved_upfront_bps, resolved_deferred_bps, vat_included,
      effective_from, effective_to, seed_version, approved_at
    )
    VALUES (
      NEW.id, NEW.scope, NEW.pricing_mode, NEW.selected_track,
      up_bps, def_bps, NEW.vat_included,
      NEW.effective_from, NEW.effective_to, seed_ver, now()
    )
    ON CONFLICT (agreement_id) DO NOTHING;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='agreements_snapshot_on_approve') THEN
    CREATE TRIGGER agreements_snapshot_on_approve
    AFTER UPDATE ON agreements
    FOR EACH ROW
    EXECUTE PROCEDURE snapshot_rates_on_approval();
  END IF;
END $$;

COMMENT ON FUNCTION snapshot_rates_on_approval IS 'Trigger function: Auto-creates immutable rate snapshot when agreement moves to APPROVED status';

-- ============================================
-- EXAMPLE: Amendment Flow
-- ============================================
-- To amend an APPROVED agreement:
--
-- 1. Clone existing agreement to new Draft:
--    INSERT INTO agreements (party_id, scope, fund_id, deal_id, pricing_mode, selected_track, ...)
--    SELECT party_id, scope, fund_id, deal_id, pricing_mode, selected_track, ...
--    FROM agreements WHERE id = [old_agreement_id];
--
-- 2. Update old agreement status to SUPERSEDED:
--    UPDATE agreements SET status = 'SUPERSEDED', effective_to = [new_effective_date] WHERE id = [old_agreement_id];
--
-- 3. Edit new Draft as needed
--
-- 4. Approve new Draft → triggers snapshot creation
