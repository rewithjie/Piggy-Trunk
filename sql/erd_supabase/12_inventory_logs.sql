create table if not exists public.inventory_logs (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references public.inventory_products(id) on delete set null,
  product_name text not null,
  action text not null,
  performed_by text not null,
  price numeric(12,2) not null,
  units integer not null,
  details text,
  created_at timestamptz not null default now()
);

create index if not exists idx_inventory_logs_product_id on public.inventory_logs(product_id);
create index if not exists idx_inventory_logs_created_at on public.inventory_logs(created_at desc);
