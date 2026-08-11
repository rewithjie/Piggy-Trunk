-- 38_remove_duplicate_notification_triggers.sql
-- Removes all legacy role notification triggers with CASCADE and sets English format for Admin Web.

-- 1. Drop legacy triggers and functions with CASCADE
drop trigger if exists trigger_on_new_raiser on public.hog_raisers cascade;
drop function if exists public.notify_admin_on_new_raiser() cascade;

drop trigger if exists trigger_on_partner_investor_insert on public.partner_investors cascade;
drop function if exists public.notify_admin_on_new_partner() cascade;

drop trigger if exists trigger_on_new_cashier on public.cashiers cascade;
drop trigger if exists trigger_on_cashier_insert on public.cashiers cascade;
drop function if exists public.notify_admin_on_new_cashier() cascade;

-- 2. Drop existing master trigger on app_users
drop trigger if exists trigger_notify_and_initialize_new_user on public.app_users cascade;

-- 3. Clear old duplicate test notifications
truncate table public.admin_notifications;

-- 4. Re-create single master trigger on BEFORE INSERT ONLY on public.app_users in English
create or replace function public.notify_and_initialize_new_user()
returns trigger as $$
declare
  role_display text;
begin
  -- Force non-admin status to Pending
  if new.role is null or new.role != 'admin' then
    new.status := 'Pending';
  end if;

  -- Determine friendly role display
  if new.role = 'hog_raiser' or new.role = 'raiser' then
    role_display := 'Hog Raiser';
  elsif new.role = 'partner' or new.role = 'investor' then
    role_display := 'Partner Investor';
  elsif new.role = 'cashier' then
    role_display := 'Cashier';
  else
    role_display := coalesce(new.role, 'User');
  end if;

  -- Insert EXACTLY 1 Notification in English for Admin Web
  insert into public.admin_notifications (
    title,
    message,
    type,
    is_read,
    metadata
  ) values (
    'New User Registration',
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

create trigger trigger_notify_and_initialize_new_user
before insert on public.app_users
for each row execute function public.notify_and_initialize_new_user();
