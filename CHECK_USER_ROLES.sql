-- ========================================
-- Check User Roles for gals@buligocapital.com
-- ========================================

-- Step 1: Get user info
SELECT
    id as user_id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
WHERE email = 'gals@buligocapital.com';

-- Step 2: Get assigned roles
SELECT
    u.email,
    r.key as role_key,
    r.name as role_name,
    ur.granted_at,
    ur.granted_by
FROM user_roles ur
JOIN auth.users u ON ur.user_id = u.id
JOIN roles r ON ur.role_key = r.key
WHERE u.email = 'gals@buligocapital.com'
ORDER BY r.key;

-- Expected roles: admin, finance, ops, manager, viewer

-- Step 3: Check RLS policy for user_roles
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'user_roles';
