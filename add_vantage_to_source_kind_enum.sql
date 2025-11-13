-- Add 'vantage' to investor_source_kind enum
-- Run in Supabase SQL Editor

-- Check if the enum type exists and what values it has
DO $$
BEGIN
    -- Add 'vantage' if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'vantage'
        AND enumtypid = 'investor_source_kind'::regtype
    ) THEN
        ALTER TYPE investor_source_kind ADD VALUE 'vantage';
        RAISE NOTICE 'Added vantage to investor_source_kind enum';
    ELSE
        RAISE NOTICE 'vantage already exists in investor_source_kind enum';
    END IF;
END $$;

-- Verify the enum values
SELECT enumlabel
FROM pg_enum
WHERE enumtypid = 'investor_source_kind'::regtype
ORDER BY enumsortorder;
