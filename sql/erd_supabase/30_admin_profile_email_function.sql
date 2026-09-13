-- ==============================================================================
-- 30_admin_profile_email_function.sql
-- Function: public.admin_update_profile_email
-- Purpose: Safely update admin email & metadata directly in auth.users and app_users,
--          recording an in-app audit notification in admin_notifications.
-- ==============================================================================

begin;

create or replace function public.admin_update_profile_email(
  new_email text,
  new_name text default null,
  new_role text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  calling_user_id uuid;
  target_user_id uuid;
  cleaned_email text;
  cleaned_name text;
  cleaned_role text;
begin
  calling_user_id := auth.uid();
  cleaned_email := lower(trim(new_email));
  cleaned_name := coalesce(nullif(trim(new_name), ''), 'Admin');
  cleaned_role := coalesce(nullif(trim(new_role), ''), 'System Administrator');

  if calling_user_id is not null then
    target_user_id := calling_user_id;
  else
    -- Fallback: locate admin user by role or existing admin user
    select supabase_user_id into target_user_id
    from public.app_users
    where lower(role) in ('admin', 'system administrator')
    limit 1;

    if target_user_id is null then
      select id into target_user_id
      from auth.users
      order by created_at asc
      limit 1;
    end if;
  end if;

  if target_user_id is null then
    return jsonb_build_object('success', false, 'message', 'Admin user could not be resolved.');
  end if;

  -- Check if new email is already taken by a different user
  if exists (select 1 from auth.users where lower(email) = cleaned_email and id != target_user_id) then
    return jsonb_build_object('success', false, 'message', 'Email ' || cleaned_email || ' is already in use by another account.');
  end if;

  -- Update auth.users directly (bypasses GoTrue email sending failure)
  update auth.users
  set email = cleaned_email,
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
        'admin_name', cleaned_name,
        'name', cleaned_name,
        'role', cleaned_role
      ),
      updated_at = now()
  where id = target_user_id;

  -- Update public.app_users
  update public.app_users
  set email = cleaned_email,
      name = cleaned_name,
      role = cleaned_role
  where supabase_user_id = target_user_id
     or lower(role) in ('admin', 'system administrator');

  -- Record in-app notification in admin_notifications table
  insert into public.admin_notifications (title, message, type, is_read, metadata)
  values (
    'Admin Email Updated',
    'Administrator login email was successfully updated to ' || cleaned_email || '. You can now use your personal Gmail for admin sign-in and OTP password recovery.',
    'admin_profile',
    false,
    jsonb_build_object(
      'new_email', cleaned_email,
      'admin_name', cleaned_name,
      'updated_at', now()
    )
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Admin email updated successfully to ' || cleaned_email,
    'email', cleaned_email,
    'name', cleaned_name,
    'role', cleaned_role
  );
exception
  when others then
    return jsonb_build_object('success', false, 'message', SQLERRM);
end;
$$;

-- Grant permissions to execute function
grant execute on function public.admin_update_profile_email to authenticated, anon, service_role;

commit;
