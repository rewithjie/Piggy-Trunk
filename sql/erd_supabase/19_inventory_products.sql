-- 19_inventory_products.sql
-- Creates the `inventory_products` table used by the Flutter Inventory and POS screens.

begin;

create table if not exists public.inventory_products (
  id          uuid            default gen_random_uuid() primary key,
  name        text            not null,
  category_id text,
  category    text            not null default 'Feeds',
  description text            not null default '',
  price       numeric(12,2)   not null default 0 check (price >= 0),
  units       integer         not null default 0 check (units >= 0),
  sold        integer         not null default 0 check (sold >= 0),
  image       text,
  is_archived boolean         not null default false,
  created_at  timestamptz     not null default now()
);

create index if not exists idx_inventory_products_category   on public.inventory_products(category);
create index if not exists idx_inventory_products_archived   on public.inventory_products(is_archived);
create index if not exists idx_inventory_products_created_at on public.inventory_products(created_at desc);

alter table public.inventory_products enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'inventory_products'
      and policyname = 'inventory_products_auth_all'
  ) then
    create policy inventory_products_auth_all
      on public.inventory_products
      for all to authenticated
      using (true) with check (true);
  end if;
end $$;

commit;
