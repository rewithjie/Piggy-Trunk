-- 48_fix_email_signup_and_admin_sync.sql
-- Complete and robust handle_new_user() trigger for Email & Google registrations
-- Automatically syncs auth.users -> public.app_users, role tables, and creates admin_notifications.

begin;

-- 1. Ensure table columns exist
alter table public.app_users add column if not exists supabase_user_id uuid;
alter table public.app_users add column if not exists status text default 'Pending';
alter table public.app_users add column if not exists role text default 'hog_raiser';

-- 2. Grant privileges to anon and authenticated roles
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;

-- 3. Robust RLS Policies
alter table public.app_users enable row level security;
drop policy if exists app_users_public_all on public.app_users;
drop policy if exists app_users_auth_all on public.app_users;
create policy app_users_public_all on public.app_users for all to public using (true) with check (true);

alter table public.partner_investors enable row level security;
drop policy if exists partner_investors_public_all on public.partner_investors;
drop policy if exists partner_investors_auth_all on public.partner_investors;
create policy partner_investors_public_all on public.partner_investors for all to public using (true) with check (true);

alter table public.hog_raisers enable row level security;
drop policy if exists hog_raisers_public_all on public.hog_raisers;
drop policy if exists hog_raisers_auth_all on public.hog_raisers;
create policy hog_raisers_public_all on public.hog_raisers for all to public using (true) with check (true);

alter table public.cashiers enable row level security;
drop policy if exists cashiers_public_all on public.cashiers;
drop policy if exists cashiers_auth_all on public.cashiers;
create policy cashiers_public_all on public.cashiers for all to public using (true) with check (true);

alter table public.admin_notifications enable row level security;
drop policy if exists admin_notifications_public_all on public.admin_notifications;
drop policy if exists admin_notifications_auth_all on public.admin_notifications;
create policy admin_notifications_public_all on public.admin_notifications for all to public using (true) with check (true);

-- 4. Recreate handle_new_user() with SECURITY DEFINER
create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_app_user_id bigint;
  user_role text;
  user_name text;
  role_display text;
begin
  user_role := lower(coalesce(new.raw_user_meta_data->>'role', 'hog_raiser'));
  if user_role = 'investor' then
    user_role := 'partner';
  elsif user_role = 'raiser' then
    user_role := 'hog_raiser';
  end if;

  user_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    split_part(new.email, '@', 1)
  );

  -- Insert or update app_users
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
    name = coalesce(excluded.name, app_users.name),
    role = case when app_users.role is null or app_users.role = '' then excluded.role else app_users.role end
  returning user_id into new_app_user_id;

  -- Fallback if user_id was not returned (e.g. on conflict without change)
  if new_app_user_id is null then
    select user_id into new_app_user_id from public.app_users where email = new.email limit 1;
  end if;

  -- Insert into respective role tables if not already present
  if new_app_user_id is not null then
    if user_role = 'partner' then
      insert into public.partner_investors (user_id)
      values (new_app_user_id)
      on conflict do nothing;
    elsif user_role = 'hog_raiser' then
      insert into public.hog_raisers (name, email, status, account_status, lifecycle_stage, user_id, phone, address, pig_type)
      values (user_name, new.email, 'Inactive', 'Pending', 'Fattening', new_app_user_id, 'N/A', 'N/A', 'Fattening')
      on conflict do nothing;
    elsif user_role = 'cashier' then
      insert into public.cashiers (user_id, status)
      values (new_app_user_id, 'Pending')
      on conflict do nothing;
    end if;
  end if;

  -- Format display role for notification
  if user_role = 'hog_raiser' then
    role_display := 'Hog Raiser';
  elsif user_role = 'partner' then
    role_display := 'Partner Investor';
  elsif user_role = 'cashier' then
    role_display := 'Cashier';
  else
    role_display := coalesce(user_role, 'User');
  end if;

  -- Clean old notifications for this email and insert new admin notification
  delete from public.admin_notifications 
  where (metadata->>'email' = new.email or message ilike '%' || new.email || '%')
    and (type = 'user_registration' or type = 'new_user_registration');

  insert into public.admin_notifications (
    title,
    message,
    type,
    is_read,
    metadata
  ) values (
    'New User Registration',
    coalesce(user_name, 'A new user') || ' (' || coalesce(new.email, '') || ') registered as ' || role_display || ' and is pending approval.',
    'new_user_registration',
    false,
    jsonb_build_object(
      'user_id', new_app_user_id,
      'name', user_name,
      'email', new.email,
      'role', user_role
    )
  );

  return new;
exception
  when others then
    -- Never block auth user creation if supplementary tables encounter an issue
    raise warning 'handle_new_user error: %', SQLERRM;
    return new;
end;
$$ language plpgsql security definer;

-- 5. Attach trigger to auth.users
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

commit;

notify pgrst, 'reload schema';
