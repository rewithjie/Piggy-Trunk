-- 23_hog_raisers_foreign_key.sql
-- Adds the missing foreign key constraint between public.hog_raisers and public.app_users
-- so PostgREST can resolve the app_users(email) nested query.

begin;

-- 1. Ensure the user_id column exists on public.hog_raisers (just in case)
alter table public.hog_raisers
  add column if not exists user_id bigint;

-- 2. Add the foreign key constraint
alter table public.hog_raisers
  drop constraint if exists fk_hog_raisers_app_users,
  add constraint fk_hog_raisers_app_users
  foreign key (user_id) references public.app_users(user_id)
  on delete set null;

commit;

-- 3. Force PostgREST to reload the schema cache so the changes take effect immediately
notify pgrst, 'reload schema';
