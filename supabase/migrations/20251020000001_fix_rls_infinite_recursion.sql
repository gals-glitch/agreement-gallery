-- ============================================
-- Fix: Infinite Recursion in user_roles RLS Policies
-- Date: 2025-10-20
-- Issue: RLS policies on user_roles table were querying user_roles
--        within their USING clauses, causing infinite recursion
-- ============================================
--
-- PROBLEM:
-- The "Admins can manage user_roles" policy uses FOR ALL which includes SELECT.
-- Its USING clause queries user_roles to check if user is admin, creating infinite recursion:
--   Query user_roles → Policy checks user_roles → Policy checks user_roles → ...
--
-- SOLUTION:
-- 1. Create a security definer function that bypasses RLS
-- 2. Drop the problematic policies
-- 3. Recreate policies using the security definer function
--
-- ============================================

-- ============================================
-- STEP 1: Create security definer function to check user roles
-- ============================================

CREATE OR REPLACE FUNCTION public.user_has_role(user_id UUID, role_key TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with function owner's privileges, bypassing RLS
SET search_path = public
AS $$
BEGIN
  -- Check if user has the specified role
  -- This function bypasses RLS because of SECURITY DEFINER
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_roles.user_id = user_has_role.user_id
    AND user_roles.role_key = user_has_role.role_key
  );
END;
$$;

COMMENT ON FUNCTION public.user_has_role IS 'Check if user has a specific role (bypasses RLS to avoid infinite recursion)';

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.user_has_role(UUID, TEXT) TO authenticated;

-- ============================================
-- STEP 2: Drop all problematic RLS policies
-- ============================================

-- Drop all policies that query user_roles in their USING/WITH CHECK clauses
DROP POLICY IF EXISTS "Admins can manage roles" ON roles;
DROP POLICY IF EXISTS "Admins can manage user_roles" ON user_roles;
DROP POLICY IF EXISTS "Admins can insert audit_log" ON audit_log;
DROP POLICY IF EXISTS "Admins can update org_settings" ON org_settings;
DROP POLICY IF EXISTS "Finance/Ops/Manager/Admin can read credits" ON credits_ledger;
DROP POLICY IF EXISTS "Finance/Admin can manage credits" ON credits_ledger;
DROP POLICY IF EXISTS "Finance/Ops/Manager/Admin can read credit_applications" ON credit_applications;
DROP POLICY IF EXISTS "Finance/Admin can manage credit_applications" ON credit_applications;
DROP POLICY IF EXISTS "Finance/Admin can manage tracks" ON fund_vi_tracks;

-- ============================================
-- STEP 3: Recreate policies using security definer function
-- ============================================

-- Policy for roles table (admin management)
CREATE POLICY "Admins can manage roles"
  ON roles
  FOR ALL
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'))
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));

-- Policy for user_roles table (admin management)
-- Keep FOR SELECT as is (USING true), but change FOR ALL to INSERT/UPDATE/DELETE only
CREATE POLICY "Admins can insert user_roles"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update user_roles"
  ON user_roles
  FOR UPDATE
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'))
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete user_roles"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'));

-- Policy for audit_log table (admin insert)
CREATE POLICY "Admins can insert audit_log"
  ON audit_log
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));

-- Policy for org_settings table (admin update)
CREATE POLICY "Admins can update org_settings"
  ON org_settings
  FOR UPDATE
  TO authenticated
  USING (public.user_has_role(auth.uid(), 'admin'))
  WITH CHECK (public.user_has_role(auth.uid(), 'admin'));

-- Policies for credits_ledger table
CREATE POLICY "Finance/Ops/Manager/Admin can read credits"
  ON credits_ledger
  FOR SELECT
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance') OR
    public.user_has_role(auth.uid(), 'ops') OR
    public.user_has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Finance/Admin can insert credits"
  ON credits_ledger
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can update credits"
  ON credits_ledger
  FOR UPDATE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  )
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can delete credits"
  ON credits_ledger
  FOR DELETE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

-- Policies for credit_applications table
CREATE POLICY "Finance/Ops/Manager/Admin can read credit_applications"
  ON credit_applications
  FOR SELECT
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance') OR
    public.user_has_role(auth.uid(), 'ops') OR
    public.user_has_role(auth.uid(), 'manager')
  );

CREATE POLICY "Finance/Admin can insert credit_applications"
  ON credit_applications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can update credit_applications"
  ON credit_applications
  FOR UPDATE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  )
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can delete credit_applications"
  ON credit_applications
  FOR DELETE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

-- Policies for fund_vi_tracks table
CREATE POLICY "Finance/Admin can insert tracks"
  ON fund_vi_tracks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can update tracks"
  ON fund_vi_tracks
  FOR UPDATE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  )
  WITH CHECK (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

CREATE POLICY "Finance/Admin can delete tracks"
  ON fund_vi_tracks
  FOR DELETE
  TO authenticated
  USING (
    public.user_has_role(auth.uid(), 'admin') OR
    public.user_has_role(auth.uid(), 'finance')
  );

-- ============================================
-- VERIFICATION
-- ============================================

-- Test that the function works
-- SELECT public.user_has_role(auth.uid(), 'admin');

-- Test that you can now query user_roles without infinite recursion
-- SELECT * FROM user_roles WHERE user_id = auth.uid();

-- ============================================
-- END MIGRATION
-- ============================================
