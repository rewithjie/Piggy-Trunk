-- 27_pos_seed_function.sql
-- Seed realistic historical sales over the past N days for testing Demand Forecasting & Inventory Reorder Planning.
-- Call via: select public.seed_historical_pos_sales(45);

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
