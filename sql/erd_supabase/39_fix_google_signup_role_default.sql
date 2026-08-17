-- 39_fix_google_signup_role_default.sql
-- Fixes trigger default role from 'partner' to 'hog_raiser' and updates admin_notifications appropriately

create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_app_user_id bigint;
  user_role text;
  user_name text;
begin
  user_role := coalesce(new.raw_user_meta_data->>'role', 'hog_raiser');
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
    role = case when app_users.role is null or app_users.role = '' then excluded.role else app_users.role end
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

-- Recreate trigger on app_users to update notification if role changes
create or replace function public.notify_and_initialize_new_user()
returns trigger as $$
declare
  role_display text;
begin
  if new.role is null or new.role != 'admin' then
    if new.status is null then
      new.status := 'Pending';
    end if;
  end if;

  if new.role = 'hog_raiser' or new.role = 'raiser' then
    role_display := 'Hog Raiser';
  elsif new.role = 'partner' or new.role = 'investor' then
    role_display := 'Partner Investor';
  elsif new.role = 'cashier' then
    role_display := 'Cashier';
  else
    role_display := coalesce(new.role, 'User');
  end if;

  -- Delete any previous duplicate registration notification for this email to avoid stale role display
  delete from public.admin_notifications 
  where metadata->>'email' = new.email and type = 'user_registration';

  -- Insert accurate Admin Notification
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
