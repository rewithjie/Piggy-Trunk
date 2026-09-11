alter table public.app_users
  add column if not exists supabase_user_id uuid unique;

alter table public.app_users
  add column if not exists must_change_password boolean not null default true;

alter table public.app_users
  add column if not exists password_reset_token text;

alter table public.app_users
  add column if not exists password_reset_sent_at timestamptz;

alter table public.app_users
  add column if not exists email_verified boolean not null default false;

comment on column public.app_users.supabase_user_id is 'Link to auth.users.id for Supabase Auth accounts';
comment on column public.app_users.must_change_password is 'Flag to require first-login password change for custom flows';
comment on column public.app_users.password_reset_token is 'Optional token for password reset flows';
comment on column public.app_users.password_reset_sent_at is 'Timestamp when reset token was issued';
comment on column public.app_users.email_verified is 'Tracks whether the email was verified via Supabase Auth.';

-- Add email column to hog_raisers (kung wala pa)
alter table public.hog_raisers 
  add column if not exists email text;
