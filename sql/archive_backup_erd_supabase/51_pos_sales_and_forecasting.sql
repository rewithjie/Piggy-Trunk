-- ==============================================================================
-- 51_pos_sales_and_forecasting.sql
-- Creates the `pos_sales` historical sales database for demand forecasting
-- and inventory reorder planning in POS & Inventory modules.
-- ==============================================================================

begin;

-- 1. Create pos_sales table
create table if not exists public.pos_sales (
  id             uuid            default gen_random_uuid() primary key,
  order_id       text            not null,
  product_id     uuid            references public.inventory_products(id) on delete set null,
  product_name   text            not null,
  category       text            not null default 'Feeds',
  quantity       integer         not null check (quantity > 0),
  unit_price     numeric(12,2)   not null default 0 check (unit_price >= 0),
  total_amount   numeric(12,2)   not null default 0 check (total_amount >= 0),
  sale_date      timestamptz     not null default now(),
  customer_name  text            default 'Walk-in Customer',
  customer_type  text            default 'Walk-in',
  payment_method text            default 'Cash',
  cashier_name   text,
  created_at     timestamptz     not null default now()
);

-- 2. Indexes for fast aggregation in time-series queries
create index if not exists idx_pos_sales_product_date on public.pos_sales(product_id, sale_date desc);
create index if not exists idx_pos_sales_sale_date    on public.pos_sales(sale_date desc);
create index if not exists idx_pos_sales_order_id     on public.pos_sales(order_id);
create index if not exists idx_pos_sales_category     on public.pos_sales(category);

-- 3. Add inventory planning columns to inventory_products if not already present
alter table public.inventory_products
  add column if not exists lead_time_days integer not null default 3,
  add column if not exists safety_stock   integer not null default 5,
  add column if not exists reorder_point  integer;

-- 4. Enable Row Level Security (RLS)
alter table public.pos_sales enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'pos_sales'
      and policyname = 'pos_sales_auth_all'
  ) then
    create policy pos_sales_auth_all
      on public.pos_sales
      for all to authenticated
      using (true) with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'pos_sales'
      and policyname = 'pos_sales_anon_select'
  ) then
    create policy pos_sales_anon_select
      on public.pos_sales
      for select to anon
      using (true);
  end if;
end $$;

-- 5. Helper Function: Seed realistic historical sales over the past 45 days
-- Can be called via `select public.seed_historical_pos_sales(45);`
create or replace function public.seed_historical_pos_sales(days_back integer default 45)
returns integer
language plpgsql
security definer
as $$
declare
  prod record;
  day_offset integer;
  daily_orders integer;
  order_idx integer;
  sale_qty integer;
  gen_sale_date timestamptz;
  cur_order_id text;
  inserted_count integer := 0;
begin
  for prod in
    select id, name, category, price
    from public.inventory_products
    where is_archived = false
  loop
    for day_offset in reverse 1..days_back loop
      -- 1 to 4 transactions per product per day
      daily_orders := floor(random() * 4 + 1)::integer;

      for order_idx in 1..daily_orders loop
        sale_qty := floor(random() * 5 + 1)::integer;
        -- Random time during daytime business hours (8 AM - 6 PM)
        gen_sale_date := (current_date - (day_offset || ' days')::interval)
                         + (8 || ' hours')::interval
                         + ((floor(random() * 600)) || ' minutes')::interval;
        cur_order_id := 'ORD-DEMO-' || lpad(floor(random() * 90000 + 10000)::text, 5, '0');

        insert into public.pos_sales (
          order_id,
          product_id,
          product_name,
          category,
          quantity,
          unit_price,
          total_amount,
          sale_date,
          customer_name,
          customer_type,
          payment_method,
          cashier_name,
          created_at
        ) values (
          cur_order_id,
          prod.id,
          prod.name,
          prod.category,
          sale_qty,
          prod.price,
          (sale_qty * prod.price),
          gen_sale_date,
          case when random() > 0.4 then 'Walk-in Customer' else 'Local Hog Raiser' end,
          case when random() > 0.4 then 'Walk-in' else 'Hog Raiser' end,
          case when random() > 0.25 then 'Cash' else 'GCash' end,
          'POS System',
          gen_sale_date
        );

        inserted_count := inserted_count + 1;
      end loop;
    end loop;
  end loop;

  return inserted_count;
end;
$$;

commit;

notify pgrst, 'reload schema';
