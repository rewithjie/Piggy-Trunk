-- 26_force_delete_user_function.sql
-- Administrative RPC function to force-delete an account by email,
-- safely cascading across all Piggy Trunk child records and auth.users.

create or replace function public.force_delete_user_by_email(target_email text)
returns text as $$
declare
  u_id bigint;
  h_id bigint;
  p_id bigint;
  c_id bigint;
begin
  -- 1. Find user_id from app_users
  select user_id into u_id 
  from public.app_users 
  where lower(email) = lower(target_email);

  if u_id is not null then
    -- Find child table IDs
    select hog_raiser_id into h_id from public.hog_raisers where user_id = u_id;
    select partner_investor_id into p_id from public.partner_investors where user_id = u_id;
    select cashier_id into c_id from public.cashiers where user_id = u_id;

    -- Delete hog_raisers child records
    if h_id is not null then
      delete from public.assignments where hog_raiser_id = h_id;
      delete from public.stock_requests where hog_raiser_id = h_id;
      delete from public.hog_reports where hog_raiser_id = h_id;
      delete from public.raiser_notifications where hog_raiser_id = h_id;
      delete from public.sales where hog_raiser_id = h_id;
      delete from public.hog_raisers where hog_raiser_id = h_id;
    end if;

    -- Delete partner_investors child records
    if p_id is not null then
      delete from public.investments where partner_investor_id = p_id;
      delete from public.partner_investors where partner_investor_id = p_id;
    end if;

    -- Delete cashiers
    if c_id is not null then
      delete from public.cashiers where cashier_id = c_id;
    end if;

    -- Clean up user self-references and sales
    delete from public.sales where performed_by = u_id;
    update public.app_users set created_by = null where created_by = u_id;

    -- Delete main app_user row
    delete from public.app_users where user_id = u_id;
  end if;

  -- 2. Delete from Supabase Auth table
  delete from auth.users where lower(email) = lower(target_email);

  return 'Successfully force deleted account: ' || target_email;
end;
$$ language plpgsql security definer;
