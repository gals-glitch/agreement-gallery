-- ========================================
-- Move 1.4: Grant Admin and Finance Roles
-- ========================================
-- Run this in Supabase SQL Editor
-- Date: 2025-10-21

-- IMPORTANT: Replace the UUIDs below with actual user IDs from auth.users

-- Step 1: Find your user IDs
SELECT id, email, raw_user_meta_data->>'full_name' as name
FROM auth.users
ORDER BY email;

-- Step 2: Grant roles (REPLACE THE UUIDs!)

-- Grant admin role
INSERT INTO user_roles(user_id, role_key, granted_by)
VALUES
  ('YOUR_ADMIN_USER_UUID_HERE', 'admin', 'YOUR_ADMIN_USER_UUID_HERE')
ON CONFLICT (user_id, role_key) DO NOTHING;

-- Grant finance role (if you have a separate finance user)
INSERT INTO user_roles(user_id, role_key, granted_by)
VALUES
  ('YOUR_FINANCE_USER_UUID_HERE', 'finance', 'YOUR_ADMIN_USER_UUID_HERE')
ON CONFLICT (user_id, role_key) DO NOTHING;

-- Step 3: Verify role assignments
SELECT
  u.email,
  r.key as role,
  r.name as role_name,
  ur.granted_at
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
JOIN roles r ON ur.role_key = r.key
ORDER BY u.email, r.key;

-- Expected output:
-- user@example.com | admin   | Administrator | 2025-10-21 ...
-- user@example.com | finance | Finance       | 2025-10-21 ...
