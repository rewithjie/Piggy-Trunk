-- 35_fix_auth_signup_trigger.sql
-- Syncs existing auth.users entries into public.app_users and ensures handle_new_user trigger is active.

begin;

-- 1. Sync any existing auth.users into app_users if missing
insert into public.app_users (name, email, role, status, supabase_user_id)
select 
  coalesce(u.raw_user_meta_data->>'name', coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1))),
  u.email,
  coalesce(u.raw_user_meta_data->>'role', 'partner'),
  'Pending',
  u.id
from auth.users u
left join public.app_users a on a.email = u.email
where a.user_id is null;

-- 2. Create partner_investors for any partner role app_users missing in partner_investors
insert into public.partner_investors (user_id)
select a.user_id 
from public.app_users a
left join public.partner_investors p on p.user_id = a.user_id
where a.role = 'partner' and p.partner_investor_id is null;

-- 3. Create hog_raisers for any hog_raiser role app_users missing in hog_raisers
insert into public.hog_raisers (user_id, name, status, account_status, lifecycle_stage)
select a.user_id, a.name, 'Active', 'Pending', 'Fattening'
from public.app_users a
left join public.hog_raisers h on h.user_id = a.user_id
where a.role = 'hog_raiser' and h.hog_raiser_id is null;

-- 4. Re-create handle_new_user trigger on auth.users with ON CONFLICT resolution
create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_app_user_id bigint;
  user_role text;
  user_name text;
begin
  user_role := coalesce(new.raw_user_meta_data->>'role', 'partner');
  user_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    split_part(new.email, '@', 1)
  );

  insert into public.app_users (name, email, role, status, supabase_user_id)
  values (
    user_name,
    new.email,
    user_role,
    case when user_role = 'admin' then 'active' else 'Pending' end,
    new.id
  )
  on conflict (email) do update set
    supabase_user_id = excluded.supabase_user_id,
    role = excluded.role
  returning user_id into new_app_user_id;

  if user_role = 'partner' then
    insert into public.partner_investors (user_id)
    values (new_app_user_id)
    on conflict do nothing;
  elsif user_role = 'hog_raiser' then
    insert into public.hog_raisers (name, email, status, account_status, lifecycle_stage, user_id)
    values (user_name, new.email, 'Active', 'pending', 'Fattening', new_app_user_id)
    on conflict do nothing;
  elsif user_role = 'cashier' then
    insert into public.cashiers (user_id)
    values (new_app_user_id)
    on conflict do nothing;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

commit;

notify pgrst, 'reload schema';
