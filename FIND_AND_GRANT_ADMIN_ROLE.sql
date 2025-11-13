-- ========================================
-- Step 1: Find Your User ID
-- ========================================
-- Run this first to see all users in the system

SELECT
    id,
    email,
    raw_user_meta_data->>'full_name' as name,
    created_at
FROM auth.users
ORDER BY email;

-- Copy your user ID from the results above

-- ========================================
-- Step 2: Check Current Role Assignments
-- ========================================
-- See what roles are already assigned

SELECT
    u.email,
    r.key as role,
    r.name as role_name,
    ur.granted_at,
    ur.granted_by
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
JOIN roles r ON ur.role_key = r.key
ORDER BY u.email, r.key;

-- ========================================
-- Step 3: Grant Admin Role
-- ========================================
-- REPLACE 'YOUR_USER_ID_HERE' with your actual UUID from Step 1

-- Example:
-- INSERT INTO user_roles(user_id, role_key, granted_by)
-- VALUES
--   ('fabb1e21-691e-4005-8a9d-66fc381011a2', 'admin', 'fabb1e21-691e-4005-8a9d-66fc381011a2')
-- ON CONFLICT (user_id, role_key) DO NOTHING;

-- Uncomment and run the above after replacing the UUID

-- ========================================
-- Step 4: Verify Role Granted
-- ========================================
-- Run Step 2 query again to confirm the role was added
