-- 99_ensure_admin_user.sql
-- Run this manually in your Supabase SQL editor or psql after replacing placeholders.
-- Purpose: Ensure there's a matching admin row in `app_users` that corresponds to an Auth user.
-- IMPORTANT: Replace <ADMIN_EMAIL> and <AUTH_USER_UUID> with the real values from your Supabase project.

-- 1) Verify if an admin exists for the given email
-- SELECT user_id, email, role, supabase_user_id FROM public.app_users WHERE email = '<ADMIN_EMAIL>' LIMIT 1;

-- 2) Get auth user info (run in Supabase SQL editor on the auth schema):
-- SELECT id, email FROM auth.users WHERE email = '<ADMIN_EMAIL>' LIMIT 1;

-- 3) If an app_users row does not exist, insert one. If it exists but role is not admin, update it.

BEGIN;

-- Replace placeholders below and then run.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.app_users WHERE lower(email) = lower('admin@piggytrunk')) THEN
    INSERT INTO public.app_users (name, email, role, status, supabase_user_id, created_at)
    VALUES (
      'Admin User',
      'admin@piggytrunk',
      'admin',
      'active',
      '5f1bda6b-87b4-4a23-af0d-d848a03f672c',
      now()
    );
  ELSE
    UPDATE public.app_users
    SET role = 'admin', supabase_user_id = COALESCE(supabase_user_id, '5f1bda6b-87b4-4a23-af0d-d848a03f672c')
    WHERE lower(email) = lower('admin@piggytrunk');
  END IF;
END$$;

COMMIT;

-- After running, verify:
-- SELECT user_id, email, role, supabase_user_id FROM public.app_users WHERE email = '<ADMIN_EMAIL>' LIMIT 1;
