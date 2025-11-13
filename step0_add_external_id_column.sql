-- Step 0: Add external_id column to deals table if it doesn't exist
-- This must be run BEFORE step 1

-- Add external_id column to deals (funds) table
ALTER TABLE public.deals
ADD COLUMN IF NOT EXISTS external_id TEXT;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_deals_external_id ON public.deals(external_id);

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'deals' AND column_name = 'external_id';

-- Show current deals structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'deals'
ORDER BY ordinal_position;
