-- 43_notify_admin_on_low_stock.sql
-- Automatic Real-Time Notification Trigger for Admin Web when an Inventory Product reaches Low Stock (units <= 10).

begin;

-- 1. Trigger function for inventory_products (Flutter Web & Mobile POS)
create or replace function public.notify_admin_on_low_stock()
returns trigger as $$
begin
  -- Check if product is not archived, and current units is <= 10, and stock was decreased or newly added as low stock
  if (new.is_archived = false or new.is_archived is null)
     and new.units <= 10 
     and (old.units is null or old.units > new.units or (old.units <= 10 and new.units != old.units)) then

    -- Prevent duplicate spam: Only insert if no unread low_stock alert exists for this product in the last 2 hours
    if not exists (
      select 1 from public.admin_notifications
      where type = 'low_stock'
        and (metadata->>'product_id')::text = new.id::text
        and is_read = false
        and created_at > now() - interval '2 hours'
    ) then
      insert into public.admin_notifications (
        title,
        message,
        type,
        metadata
      )
      values (
        case when new.units <= 3 then 'Critical Low Stock Alert' else 'Low Stock Alert' end,
        coalesce(new.name, 'Product') || ' is running low on stock (' || new.units || ' ' || (case when new.units = 1 then 'unit' else 'units' end) || ' remaining). Please restock soon.',
        'low_stock',
        jsonb_build_object(
          'product_id', new.id,
          'product_name', new.name,
          'remaining_units', new.units,
          'category', coalesce(new.category, 'Inventory')
        )
      );
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if exists
drop trigger if exists trigger_on_inventory_product_low_stock on public.inventory_products;

-- Create trigger on inventory_products table when units are updated or inserted
create trigger trigger_on_inventory_product_low_stock
  after insert or update of units, is_archived on public.inventory_products
  for each row execute function public.notify_admin_on_low_stock();

-- 2. Trigger function for legacy products table (if used)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'products') then
    create or replace function public.notify_admin_on_products_low_stock()
    returns trigger as $p$
    begin
      if new.current_stock <= 10 and (old.current_stock is null or old.current_stock > new.current_stock) then
        if not exists (
          select 1 from public.admin_notifications
          where type = 'low_stock'
            and (metadata->>'product_id')::text = new.product_id::text
            and is_read = false
            and created_at > now() - interval '2 hours'
        ) then
          insert into public.admin_notifications (
            title,
            message,
            type,
            metadata
          )
          values (
            case when new.current_stock <= 3 then 'Critical Low Stock Alert' else 'Low Stock Alert' end,
            coalesce(new.product_name, 'Product') || ' is running low on stock (' || new.current_stock || ' units remaining). Please restock soon.',
            'low_stock',
            jsonb_build_object(
              'product_id', new.product_id,
              'product_name', new.product_name,
              'remaining_units', new.current_stock,
              'category', coalesce(new.category, 'Inventory')
            )
          );
        end if;
      end if;
      return new;
    end;
    $p$ language plpgsql security definer;

    drop trigger if exists trigger_on_products_low_stock on public.products;
    create trigger trigger_on_products_low_stock
      after insert or update of current_stock on public.products
      for each row execute function public.notify_admin_on_products_low_stock();
  end if;
end $$;

commit;

-- Reload postgrest schema
notify pgrst, 'reload schema';
