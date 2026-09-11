-- 23_hog_raisers_foreign_key.sql
-- Removes duplicate constraint to prevent PostgREST PGRST201 embedding error.

begin;

alter table public.hog_raisers
  drop constraint if exists fk_hog_raisers_app_users;

commit;

-- Force PostgREST to reload the schema cache
notify pgrst, 'reload schema';
