-- ============================================
-- FIX: Immutability Trigger - Allow SUPERSEDED Transition
-- Date: 2025-10-16
-- Issue: Original trigger blocked ALL updates to APPROVED agreements,
--        preventing amendment flow from marking v1 as SUPERSEDED.
-- ============================================

CREATE OR REPLACE FUNCTION prevent_update_on_approved()
RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'APPROVED' THEN
    -- Allow ONLY: status APPROVED -> SUPERSEDED and effective_to change
    -- All other fields must remain unchanged
    IF NOT (
      NEW.status = 'SUPERSEDED'
      AND (NEW.effective_to IS DISTINCT FROM OLD.effective_to OR NEW.effective_to = OLD.effective_to)
      AND NEW.selected_track IS NOT DISTINCT FROM OLD.selected_track
      AND NEW.pricing_mode  IS NOT DISTINCT FROM OLD.pricing_mode
      AND NEW.party_id      IS NOT DISTINCT FROM OLD.party_id
      AND NEW.scope         IS NOT DISTINCT FROM OLD.scope
      AND NEW.fund_id       IS NOT DISTINCT FROM OLD.fund_id
      AND NEW.deal_id       IS NOT DISTINCT FROM OLD.deal_id
      AND NEW.vat_included  IS NOT DISTINCT FROM OLD.vat_included
      AND NEW.effective_from IS NOT DISTINCT FROM OLD.effective_from
    ) THEN
      RAISE EXCEPTION 'Approved agreements are immutable. Only status->SUPERSEDED and effective_to adjustments allowed via amendment flow.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger already exists, no need to recreate
-- Just replacing the function implementation above

-- ============================================
-- VERIFICATION
-- ============================================
-- Test verification code removed - can be run manually after migration if needed
