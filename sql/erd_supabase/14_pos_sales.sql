create table if not exists public.pos_sales (
  id uuid default gen_random_uuid() primary key,
  order_id text not null,
  product_id uuid references public.inventory_products(id) on delete set null,
  product_name text not null,
  category text not null default 'Feeds',
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null default 0 check (unit_price >= 0),
  total_amount numeric(12,2) not null default 0 check (total_amount >= 0),
  sale_date timestamptz not null default now(),
  customer_name text default 'Walk-in Customer',
  customer_type text default 'Walk-in',
  payment_method text default 'Cash',
  cashier_name text,
  created_at timestamptz not null default now()
);

create index if not exists idx_pos_sales_product_date on public.pos_sales(product_id, sale_date desc);
create index if not exists idx_pos_sales_sale_date on public.pos_sales(sale_date desc);
create index if not exists idx_pos_sales_order_id on public.pos_sales(order_id);
create index if not exists idx_pos_sales_category on public.pos_sales(category);
