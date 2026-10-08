-- ==============================================================================
-- 35_fix_investments_and_notifications_rls.sql
-- Fix investment creation and notifications across Admin, Raiser, and Partner:
-- 1. Grants permissive public RLS policies on investments, partner_notifications,
--    and raiser_notifications so that investments can be saved and dispatched.
-- 2. Ensures investments and admin_notifications are in supabase_realtime publication
--    so the Admin Web notifications drawer receives live updates immediately.
-- ==============================================================================

begin;

-- 1. Grant table and sequence privileges to anon and authenticated
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;

-- 2. Investments table RLS
alter table if exists public.investments enable row level security;
drop policy if exists investments_auth_all on public.investments;
drop policy if exists investments_anon_select on public.investments;
drop policy if exists investments_public_all on public.investments;
create policy investments_public_all on public.investments for all to public using (true) with check (true);

-- 3. Partner Notifications table RLS
alter table if exists public.partner_notifications enable row level security;
drop policy if exists partner_notifications_auth_all on public.partner_notifications;
drop policy if exists partner_notifications_anon_select on public.partner_notifications;
drop policy if exists partner_notifications_public_all on public.partner_notifications;
create policy partner_notifications_public_all on public.partner_notifications for all to public using (true) with check (true);

-- 4. Raiser Notifications table RLS
alter table if exists public.raiser_notifications enable row level security;
drop policy if exists raiser_notifications_auth_all on public.raiser_notifications;
drop policy if exists raiser_notifications_anon_select on public.raiser_notifications;
drop policy if exists raiser_notifications_public_all on public.raiser_notifications;
create policy raiser_notifications_public_all on public.raiser_notifications for all to public using (true) with check (true);

-- 5. Batches table RLS
alter table if exists public.batches enable row level security;
drop policy if exists batches_auth_all on public.batches;
drop policy if exists batches_anon_select on public.batches;
drop policy if exists batches_public_all on public.batches;
create policy batches_public_all on public.batches for all to public using (true) with check (true);

-- 6. Drop redundant/conflicting database triggers on investments
-- (Prevents duplicate double notifications since notifications are dispatched with rich metadata from the client)
drop trigger if exists trigger_on_direct_partner_investment on public.investments;

-- 7. Ensure real-time publication for live Admin Web and Mobile App notifications
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'investments'
  ) then
    alter publication supabase_realtime add table public.investments;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'admin_notifications'
  ) then
    alter publication supabase_realtime add table public.admin_notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'raiser_notifications'
  ) then
    alter publication supabase_realtime add table public.raiser_notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'partner_notifications'
  ) then
    alter publication supabase_realtime add table public.partner_notifications;
  end if;
end $$;

-- 8. Clean up any historical duplicate notification rows in the database
delete from public.admin_notifications a
using public.admin_notifications b
where a.title = b.title
  and a.message = b.message
  and a.notification_id > b.notification_id;

delete from public.raiser_notifications a
using public.raiser_notifications b
where a.hog_raiser_id = b.hog_raiser_id
  and a.title = b.title
  and a.message = b.message
  and a.notification_id > b.notification_id;

delete from public.partner_notifications a
using public.partner_notifications b
where a.partner_investor_id = b.partner_investor_id
  and a.title = b.title
  and a.message = b.message
  and a.notification_id > b.notification_id;

commit;

notify pgrst, 'reload schema';
