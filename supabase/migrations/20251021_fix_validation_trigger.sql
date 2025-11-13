-- ========================================
-- Fix: Validation Trigger UUID/BIGINT Mismatch
-- ========================================
-- Date: 2025-10-21
-- Issue: validate_credit_application() was comparing charges.id (UUID) with charge_id (BIGINT)
-- Fix: Use charges.numeric_id instead of charges.id

CREATE OR REPLACE FUNCTION validate_credit_application()
RETURNS TRIGGER AS $$
DECLARE
  credit_available NUMERIC;
  credit_status TEXT;
  credit_currency TEXT;
  charge_currency TEXT;
BEGIN
  -- Get credit details
  SELECT available_amount, status, currency
  INTO credit_available, credit_status, credit_currency
  FROM credits_ledger
  WHERE id = NEW.credit_id;

  -- Check credit exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Credit ID % does not exist', NEW.credit_id;
  END IF;

  -- Check credit has enough available amount
  IF credit_available < NEW.amount_applied THEN
    RAISE EXCEPTION 'Credit ID % has insufficient available amount (available: %, requested: %)',
      NEW.credit_id, credit_available, NEW.amount_applied;
  END IF;

  -- Check credit status is AVAILABLE
  IF credit_status != 'AVAILABLE' THEN
    RAISE EXCEPTION 'Credit ID % is not available (status: %)', NEW.credit_id, credit_status;
  END IF;

  -- Check currency match if charge_id is provided
  IF NEW.charge_id IS NOT NULL THEN
    SELECT currency INTO charge_currency
    FROM charges
    WHERE numeric_id = NEW.charge_id;  -- FIX: Use numeric_id instead of id

    IF FOUND AND charge_currency != credit_currency THEN
      RAISE EXCEPTION 'Currency mismatch: credit currency (%) does not match charge currency (%)',
        credit_currency, charge_currency;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_credit_application IS
  'Trigger function: Validates credit applications before insertion (checks available amount, status, currency) - FIXED: uses numeric_id';
