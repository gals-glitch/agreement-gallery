-- Fix security warnings by adding proper search paths

-- Fix prevent_delete_used_rules function
CREATE OR REPLACE FUNCTION prevent_delete_used_rules()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM calc_runs_rules crr
    WHERE crr.rule_id = OLD.id AND crr.rule_version = OLD.rule_version
  ) THEN
    RAISE EXCEPTION 'Cannot delete rule that is referenced by calculation runs';
  END IF;
  RETURN OLD;
END;
$$;

-- Fix generate_rule_checksum function
CREATE OR REPLACE FUNCTION generate_rule_checksum(rule_data jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT encode(sha256(rule_data::text::bytea), 'hex');
$$;