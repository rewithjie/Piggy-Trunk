-- 36_fix_app_users_rls.sql
-- Grant full RLS permissions on app_users, partner_investors, cashiers, hog_raisers, admin_notifications

begin;

-- Grant table privileges
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;

-- Public RLS Policies
drop policy if exists app_users_auth_all on public.app_users;
create policy app_users_public_all on public.app_users for all to public using (true) with check (true);

drop policy if exists partner_investors_auth_all on public.partner_investors;
create policy partner_investors_public_all on public.partner_investors for all to public using (true) with check (true);

drop policy if exists cashiers_auth_all on public.cashiers;
create policy cashiers_public_all on public.cashiers for all to public using (true) with check (true);

drop policy if exists hog_raisers_auth_all on public.hog_raisers;
create policy hog_raisers_public_all on public.hog_raisers for all to public using (true) with check (true);

drop policy if exists admin_notifications_auth_all on public.admin_notifications;
create policy admin_notifications_public_all on public.admin_notifications for all to public using (true) with check (true);

commit;

notify pgrst, 'reload schema';
