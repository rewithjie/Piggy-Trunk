-- 22_auth_signup_trigger.sql
-- Automatically syncs auth.users registrations to public tables with a 'Pending' status.
-- Simplified and made robust by removing ON CONFLICT clauses to prevent key/constraint index mismatch errors.
-- Updated to explicitly insert the email column in public.hog_raisers to satisfy NOT NULL constraints.
-- Updated status of hog_raisers to 'Active' to satisfy check constraints (account_status remains 'pending' for admin approval).
-- Updated to retrieve phone and address dynamically from user metadata.

create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_app_user_id bigint;
  user_role text;
  user_name text;
  user_phone text;
  user_address text;
begin
  -- Default role to 'hog_raiser' if not specified in metadata
  user_role := coalesce(new.raw_user_meta_data->>'role', 'hog_raiser');
  
  -- Extract name, phone, and address from raw user metadata
  user_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    split_part(new.email, '@', 1)
  );
  user_phone := coalesce(new.raw_user_meta_data->>'phone', '');
  user_address := coalesce(new.raw_user_meta_data->>'address', '');

  -- Insert into public.app_users (Pending status unless admin)
  insert into public.app_users (name, email, role, status, supabase_user_id)
  values (
    user_name,
    new.email,
    user_role,
    case when user_role = 'admin' then 'active' else 'Pending' end,
    new.id
  )
  returning user_id into new_app_user_id;

  -- Insert into public.hog_raisers (using dynamic phone and address)
  if user_role = 'hog_raiser' then
    insert into public.hog_raisers (
      name, 
      email,
      phone, 
      pig_type, 
      status, 
      lifecycle_stage, 
      user_id, 
      account_status,
      address
    )
    values (
      user_name,
      new.email,
      user_phone, -- dynamic phone from metadata
      'Fattening', -- default
      'Active', -- allowed status value to pass check constraints
      'Booster', -- default stage
      new_app_user_id,
      'pending', -- admin approval status
      user_address -- dynamic address from metadata
    );
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- Setup the trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
