-- 24_inventory_logs.sql
-- Creates the `inventory_logs` table to track product operations like Add, Edit, Archive, and Restore.

begin;

create table if not exists public.inventory_logs (
  id            uuid            default gen_random_uuid() primary key,
  product_id    uuid            references public.inventory_products(id) on delete set null,
  product_name  text            not null,
  action        text            not null, -- 'ADD', 'UPDATE', 'ARCHIVE', 'RESTORE'
  performed_by  text            not null, -- Admin email or identifier
  price         numeric(12,2)   not null,
  units         integer         not null,
  details       text,                     -- Change descriptions
  created_at    timestamptz     not null default now()
);

create index if not exists idx_inventory_logs_product_id on public.inventory_logs(product_id);
create index if not exists idx_inventory_logs_created_at on public.inventory_logs(created_at desc);

alter table public.inventory_logs enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'inventory_logs'
      and policyname = 'inventory_logs_auth_all'
  ) then
    create policy inventory_logs_auth_all
      on public.inventory_logs
      for all to authenticated
      using (true) with check (true);
  end if;
end $$;

commit;
