-- Grant admin role to the current user (Gal Samionov)
INSERT INTO public.user_roles (user_id, role)
VALUES ('382eba4e-9c2c-4ed5-bd1f-485e16c2b547', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;