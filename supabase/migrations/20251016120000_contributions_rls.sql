-- Migration: contributions_rls.sql
-- Purpose: Add RLS policies for contributions table
-- Date: 2025-10-16

-- Enable RLS
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all contributions
CREATE POLICY "Allow authenticated read access to contributions"
  ON contributions
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow authenticated users to insert contributions
CREATE POLICY "Allow authenticated insert access to contributions"
  ON contributions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Allow authenticated users to update contributions
CREATE POLICY "Allow authenticated update access to contributions"
  ON contributions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow authenticated users to delete contributions
CREATE POLICY "Allow authenticated delete access to contributions"
  ON contributions
  FOR DELETE
  TO authenticated
  USING (true);

COMMENT ON TABLE contributions IS 'Contributions table with RLS enabled - all authenticated users have full access';
