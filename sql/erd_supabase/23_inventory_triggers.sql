-- 23_inventory_triggers.sql
-- Real-time notification triggers for Inventory, Restocking, and Stock Requests.

begin;

-- 1. Trigger Function: Notify Raisers & Admin when Feed/Supply is restocked
create or replace function public.notify_on_feed_restock()
returns trigger as $$
declare
  r_rec record;
begin
  if (old.units = 0 or old.units is null) and new.units > 0 then
    -- Send Notification to ALL Hog Raisers
    for r_rec in select hog_raiser_id from public.hog_raisers loop
      insert into public.raiser_notifications (
        hog_raiser_id,
        title,
        message,
        type,
        metadata
      ) values (
        r_rec.hog_raiser_id,
        'Feeds Restocked! 🌾',
        coalesce(new.name, 'Feeds') || ' is now restocked and available (' || new.units || ' units added).',
        'feed_restock',
        jsonb_build_object(
          'product_id', new.id,
          'product_name', new.name,
          'units', new.units
        )
      );
    end loop;

    -- Send Notification to Admin
    insert into public.admin_notifications (
      title,
      message,
      type,
      metadata
    ) values (
      'Inventory Restocked: ' || coalesce(new.name, 'Product'),
      'Product ' || coalesce(new.name, 'item') || ' has been restocked with ' || new.units || ' units.',
      'stock_restock',
      jsonb_build_object(
        'product_id', new.id,
        'product_name', new.name,
        'units', new.units
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_on_feed_restock on public.inventory_products;
create trigger trigger_on_feed_restock
  after update of units on public.inventory_products
  for each row execute function public.notify_on_feed_restock();


-- 2. Trigger Function: Low Stock Alert for Admin (when units <= 10)
create or replace function public.notify_admin_on_low_stock()
returns trigger as $$
begin
  if (new.is_archived = false or new.is_archived is null)
     and new.units <= 10 
     and (old.units is null or old.units > new.units or (old.units <= 10 and new.units != old.units)) then

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
      ) values (
        case when new.units <= 3 then 'Critical Low Stock Alert' else 'Low Stock Alert' end,
        coalesce(new.name, 'Product') || ' is running low on stock (' || new.units || ' remaining). Please restock soon.',
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

drop trigger if exists trigger_on_inventory_product_low_stock on public.inventory_products;
create trigger trigger_on_inventory_product_low_stock
  after insert or update of units, is_archived on public.inventory_products
  for each row execute function public.notify_admin_on_low_stock();


-- 3. Stock Request Notification:
-- Dropped generic database triggers to prevent duplicate notifications.
-- Rich detailed notification (with item count, category, and notes) is created directly upon request submission.
drop trigger if exists trigger_on_stock_request on public.stock_requests;
drop trigger if exists trigger_on_stock_request_insert on public.stock_requests;
drop function if exists public.notify_admin_on_stock_request();


-- 4. Trigger Function: Notify Raiser when Stock Request status changes (Approved/Rejected)
create or replace function public.notify_raiser_on_request_update()
returns trigger as $$
begin
  if (old.status is distinct from new.status) then
    insert into public.raiser_notifications (hog_raiser_id, title, message, type, metadata)
    values (
      new.hog_raiser_id,
      'Stock Request Update',
      'Your request for ' || new.quantity || ' ' || coalesce(new.category, 'supplies') || ' has been ' || lower(new.status) || '.',
      'request_status',
      jsonb_build_object(
        'request_id', new.request_id,
        'status', new.status,
        'category', new.category,
        'quantity', new.quantity
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_on_stock_request_update on public.stock_requests;
create trigger trigger_on_stock_request_update
  after update of status on public.stock_requests
  for each row execute function public.notify_raiser_on_request_update();

commit;
