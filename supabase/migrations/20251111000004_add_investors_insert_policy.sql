-- ============================================================================
-- Migration: Add INSERT policy for investors table
-- Date: 2025-11-11
-- Purpose: Allow authenticated users to create new investors
-- ============================================================================

-- Enable RLS if not already enabled
ALTER TABLE investors ENABLE ROW LEVEL SECURITY;

-- Drop existing INSERT policy if it exists
DROP POLICY IF EXISTS "Allow authenticated users to insert investors" ON investors;

-- Create INSERT policy for authenticated users
-- Allow any authenticated user to create investors
CREATE POLICY "Allow authenticated users to insert investors"
ON investors
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Verify SELECT policy exists (users need to be able to read what they create)
-- If no SELECT policy exists, create one
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'investors'
    AND policyname = 'Allow authenticated users to select investors'
    AND cmd = 'SELECT'
  ) THEN
    CREATE POLICY "Allow authenticated users to select investors"
    ON investors
    FOR SELECT
    TO authenticated
    USING (true);
  END IF;
END $$;

-- ============================================================================
-- Verification Query (run after migration to confirm)
-- ============================================================================
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'investors'
-- ORDER BY cmd, policyname;
