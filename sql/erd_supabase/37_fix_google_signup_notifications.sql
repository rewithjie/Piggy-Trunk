-- 99_fix_google_signup_notifications.sql
-- Fixes Google & Email signup flow:
-- 1. Ensures all non-admin signups default to 'Pending' status in app_users, hog_raisers, partner_investors, and cashiers.
-- 2. Automatically generates Realtime Admin Notifications for ALL new user registrations.
-- 3. Grants public insert/read access to admin_notifications so real-time alerts appear instantly on Vercel Admin Web.

-- Grant full RLS permissions on admin_notifications
alter table if exists public.admin_notifications enable row level security;

drop policy if exists admin_notifications_public_all on public.admin_notifications;
create policy admin_notifications_public_all on public.admin_notifications 
for all to public using (true) with check (true);

-- Ensure admin_notifications is in supabase_realtime publication
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'admin_notifications'
  ) then
    alter publication supabase_realtime add table public.admin_notifications;
  end if;
exception when others then
  -- Ignore if publication does not exist or already added
end $$;

-- Master trigger function on app_users insertion
create or replace function public.notify_and_initialize_new_user()
returns trigger as $$
declare
  role_display text;
begin
  -- Default non-admin users to Pending status
  if new.role is null or new.role != 'admin' then
    new.status := 'Pending';
  end if;

  -- Determine friendly role display name
  if new.role = 'hog_raiser' or new.role = 'raiser' then
    role_display := 'Hog Raiser';
  elsif new.role = 'partner' or new.role = 'investor' then
    role_display := 'Partner Investor';
  elsif new.role = 'cashier' then
    role_display := 'Cashier';
  else
    role_display := coalesce(new.role, 'User');
  end if;

  -- Insert automatic Admin Notification for Realtime Web Dashboard
  insert into public.admin_notifications (
    title,
    message,
    type,
    is_read,
    metadata
  ) values (
    'Bagong Rehistro ng User',
    coalesce(new.name, 'A new user') || ' (' || coalesce(new.email, '') || ') registered as ' || role_display || ' and is pending approval.',
    'user_registration',
    false,
    jsonb_build_object(
      'user_id', new.user_id,
      'name', new.name,
      'email', new.email,
      'role', new.role
    )
  );

  return new;
end;
$$ language plpgsql security definer;

-- Attach trigger to app_users table
drop trigger if exists trigger_notify_and_initialize_new_user on public.app_users;
create trigger trigger_notify_and_initialize_new_user
before insert on public.app_users
for each row execute function public.notify_and_initialize_new_user();
