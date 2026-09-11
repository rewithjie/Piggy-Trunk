-- 31_fix_delete_cascade.sql
-- Fixes foreign key constraints across all tables so deleting users from app_users or auth.users cascades smoothly without "failed to delete row" error.

begin;

-- 1. Fix app_users.created_by self-reference
alter table public.app_users 
  drop constraint if exists app_users_created_by_fkey;

alter table public.app_users 
  add constraint app_users_created_by_fkey 
  foreign key (created_by) 
  references public.app_users(user_id) 
  on delete set null;

-- 2. Fix assignments.hog_raiser_id reference (ON DELETE CASCADE)
alter table public.assignments 
  drop constraint if exists assignments_hog_raiser_id_fkey;

alter table public.assignments 
  add constraint assignments_hog_raiser_id_fkey 
  foreign key (hog_raiser_id) 
  references public.hog_raisers(hog_raiser_id) 
  on delete cascade;

-- 3. Fix stock_requests.hog_raiser_id reference (ON DELETE CASCADE)
alter table public.stock_requests 
  drop constraint if exists stock_requests_hog_raiser_id_fkey;

alter table public.stock_requests 
  add constraint stock_requests_hog_raiser_id_fkey 
  foreign key (hog_raiser_id) 
  references public.hog_raisers(hog_raiser_id) 
  on delete cascade;

-- 4. Fix sales.performed_by reference (ON DELETE CASCADE)
alter table public.sales 
  drop constraint if exists sales_performed_by_fkey;

alter table public.sales 
  add constraint sales_performed_by_fkey 
  foreign key (performed_by) 
  references public.app_users(user_id) 
  on delete cascade;

commit;

notify pgrst, 'reload schema';
