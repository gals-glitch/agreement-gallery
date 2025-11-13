-- Create v2 enum with all future rule types (clean, future-proof set)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rule_type_v2') THEN
    CREATE TYPE rule_type_v2 AS ENUM (
      'percentage',
      'fixed_amount',
      'tiered',
      'hybrid',
      'conditional',
      'management_fee',
      'promote_share',
      'credit_netting',
      'discount',
      'sub_agent_split'
    );
  END IF;
END$$;

-- Convert advanced_commission_rules.rule_type to v2 enum
-- Step 1: Drop any default that depends on old enum
ALTER TABLE public.advanced_commission_rules
  ALTER COLUMN rule_type DROP DEFAULT;

-- Step 2: Convert column to new enum via text cast (lossless)
ALTER TABLE public.advanced_commission_rules
  ALTER COLUMN rule_type TYPE rule_type_v2
  USING rule_type::text::rule_type_v2;

-- Step 3: Restore default with new enum
ALTER TABLE public.advanced_commission_rules
  ALTER COLUMN rule_type SET DEFAULT 'percentage'::rule_type_v2;

-- Optional: Swap type names so app code sees 'rule_type' again
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rule_type') AND
     EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rule_type_v2') THEN
    ALTER TYPE rule_type RENAME TO rule_type_old;
    ALTER TYPE rule_type_v2 RENAME TO rule_type;
  END IF;
END$$;

-- Clean up: Drop old enum type when safe
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM   pg_type t
    WHERE  t.typname = 'rule_type_old'
       AND NOT EXISTS (
         SELECT 1
         FROM pg_attribute a
         JOIN pg_type tt ON a.atttypid = tt.oid
         WHERE tt.typname = 'rule_type_old'
       )
  ) THEN
    DROP TYPE rule_type_old;
  END IF;
END$$;