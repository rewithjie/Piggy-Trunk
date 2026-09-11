create table if not exists public.inventory_products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category_id text,
  category text not null default 'Feeds',
  description text not null default '',
  price numeric(12,2) not null default 0 check (price >= 0),
  units integer not null default 0 check (units >= 0),
  sold integer not null default 0 check (sold >= 0),
  image text,
  lead_time_days integer not null default 3,
  safety_stock integer not null default 5,
  reorder_point integer,
  is_archived boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_inventory_products_category on public.inventory_products(category);
create index if not exists idx_inventory_products_archived on public.inventory_products(is_archived);
create index if not exists idx_inventory_products_created_at on public.inventory_products(created_at desc);
