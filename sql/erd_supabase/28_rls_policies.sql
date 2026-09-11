-- 28_rls_policies.sql
-- Row Level Security (RLS) policies for all 20 active Piggy Trunk tables.

begin;

-- 1. Grant general schema usage to authenticated and anon roles
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;

-- 2. Enable RLS on all 20 active application tables
alter table public.app_users enable row level security;
alter table public.cashiers enable row level security;
alter table public.partner_investors enable row level security;
alter table public.batches enable row level security;
alter table public.hog_types enable row level security;
alter table public.hog_raisers enable row level security;
alter table public.assignments enable row level security;
alter table public.hogs enable row level security;
alter table public.stock_requests enable row level security;
alter table public.products enable row level security;
alter table public.inventory_products enable row level security;
alter table public.inventory_logs enable row level security;
alter table public.sales enable row level security;
alter table public.pos_sales enable row level security;
alter table public.investments enable row level security;
alter table public.investment_records enable row level security;
alter table public.hog_reports enable row level security;
alter table public.admin_notifications enable row level security;
alter table public.raiser_notifications enable row level security;
alter table public.partner_notifications enable row level security;

-- 3. Create permissive policies for authenticated and public access as needed
do $$
declare
  t text;
  p_auth text;
  p_anon text;
begin
  foreach t in array array[
    'app_users',
    'cashiers',
    'partner_investors',
    'batches',
    'hog_types',
    'hog_raisers',
    'assignments',
    'hogs',
    'stock_requests',
    'products',
    'inventory_products',
    'inventory_logs',
    'sales',
    'pos_sales',
    'investments',
    'investment_records',
    'hog_reports',
    'admin_notifications',
    'raiser_notifications',
    'partner_notifications'
  ]
  loop
    p_auth := t || '_auth_all';
    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = t
        and policyname = p_auth
    ) then
      execute format(
        'create policy %I on public.%I for all to authenticated using (true) with check (true)',
        p_auth,
        t
      );
    end if;

    p_anon := t || '_anon_select';
    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = t
        and policyname = p_anon
    ) then
      execute format(
        'create policy %I on public.%I for select to anon using (true)',
        p_anon,
        t
      );
    end if;
  end loop;
end $$;

-- 4. Enable Supabase Realtime for notification tables
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.admin_notifications;
    alter publication supabase_realtime add table public.raiser_notifications;
    alter publication supabase_realtime add table public.partner_notifications;
    alter publication supabase_realtime add table public.stock_requests;
    alter publication supabase_realtime add table public.inventory_products;
  end if;
exception
  when others then null;
end $$;

commit;

notify pgrst, 'reload schema';
