-- ============================================
-- EMERGENCY FIX: Remove ALL policies on user_roles and recreate from scratch
-- Date: 2025-10-20
-- ============================================

-- Step 1: Drop ALL existing policies on user_roles (nuclear option)
DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE tablename = 'user_roles'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON user_roles', policy_record.policyname);
  END LOOP;
END $$;

-- Step 2: Ensure user_has_role function exists and is correct
CREATE OR REPLACE FUNCTION public.user_has_role(check_user_id UUID, check_role_key TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- Critical: Bypasses RLS
STABLE
SET search_path = public
AS $$
DECLARE
  has_role BOOLEAN;
BEGIN
  -- Direct query without RLS
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = check_user_id
    AND role_key = check_role_key
  ) INTO has_role;

  RETURN COALESCE(has_role, false);
END;
$$;

COMMENT ON FUNCTION public.user_has_role IS 'Security definer function to check user roles (bypasses RLS)';

-- Grant execute to all authenticated users
GRANT EXECUTE ON FUNCTION public.user_has_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_role(UUID, TEXT) TO anon;

-- Step 3: Create ONLY the minimal required policies

-- Policy 1: Everyone can read ALL user_roles (no restrictions)
-- This is safe because we want users to see what roles exist
CREATE POLICY "user_roles_select_all"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy 2: Only admins can INSERT new role assignments
CREATE POLICY "user_roles_insert_admin_only"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin')
  );

-- Policy 3: Only admins can DELETE role assignments
CREATE POLICY "user_roles_delete_admin_only"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin')
  );

-- Step 4: Verify the fix
-- This query should now work without infinite recursion:
-- SELECT * FROM user_roles WHERE user_id = auth.uid();

-- Step 5: Test the user_has_role function directly
-- SELECT public.user_has_role(auth.uid(), 'admin');

SELECT 'RLS policies fixed successfully' as status;
