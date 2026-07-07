-- 100_link_app_users_to_auth.sql
-- Adds a supabase_user_id UUID column to public.app_users and attempts to populate it
-- by matching app_users.email to auth.users.email. Also ensures the default admin email
-- (admin@piggytrunk) has role='admin'. Run this in Supabase SQL editor.

BEGIN;

-- 1) Add column if missing
ALTER TABLE public.app_users
  ADD COLUMN IF NOT EXISTS supabase_user_id uuid UNIQUE;

-- 2) Populate supabase_user_id by matching emails between app_users and auth.users
UPDATE public.app_users AS a
SET supabase_user_id = u.id
FROM auth.users AS u
WHERE a.supabase_user_id IS NULL
  AND u.email IS NOT NULL
  AND lower(u.email) = lower(a.email);

-- 3) Ensure admin role for the common local dev admin email (only if a row exists)
-- Change the email below if you use a different admin email in your project.
UPDATE public.app_users
SET role = 'admin'
WHERE lower(email) = lower('admin@piggytrunk');

-- 4) Add helpful indexes if not present
CREATE INDEX IF NOT EXISTS idx_app_users_supabase_user_id ON public.app_users(supabase_user_id);
CREATE INDEX IF NOT EXISTS idx_app_users_role ON public.app_users(role);

COMMIT;

-- Verification queries:
-- SELECT user_id, email, role, supabase_user_id FROM public.app_users WHERE email = 'admin@piggytrunk';
-- SELECT id, email FROM auth.users WHERE email = 'admin@piggytrunk';
