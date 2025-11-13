-- Grant admin role to gals@buligocapital.com
-- Run this AFTER applying the RLS fix migration

-- First, check if the user exists and get their user_id
-- SELECT id, email FROM auth.users WHERE email = 'gals@buligocapital.com';
-- Expected: user_id = fabb1e21-691e-4005-8a9d-66fc381011a2

-- Grant admin role (idempotent - won't error if already exists)
INSERT INTO user_roles (user_id, role_key, granted_by)
VALUES (
  'fabb1e21-691e-4005-8a9d-66fc381011a2',
  'admin',
  'fabb1e21-691e-4005-8a9d-66fc381011a2'  -- Self-granted for bootstrap
)
ON CONFLICT (user_id, role_key) DO NOTHING;

-- Verify the role was granted
SELECT
  u.email,
  ur.role_key,
  r.name as role_name,
  ur.granted_at
FROM auth.users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_key = r.key
WHERE u.email = 'gals@buligocapital.com';
-- Expected output: gals@buligocapital.com | admin | Administrator | <timestamp>
