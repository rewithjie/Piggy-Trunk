-- 34_feed_restock_notifications_trigger.sql
-- Automatic Real-Time Notification Trigger when Admin restocks Feeds in Inventory (when units increase from 0 to > 0).

begin;

-- Trigger Function: Notify all Hog Raisers & Cashiers when Feed Inventory is restocked from 0
create or replace function public.notify_on_feed_restock()
returns trigger as $$
declare
  r_rec record;
begin
  -- Trigger when stock unit was 0 (or null) and is now restocked (> 0)
  if (old.units = 0 or old.units is null) and new.units > 0 then
    
    -- 1. Send Notification to ALL Hog Raisers mobile app
    for r_rec in select hog_raiser_id from public.hog_raisers loop
      insert into public.raiser_notifications (
        hog_raiser_id,
        title,
        message,
        type,
        metadata
      )
      values (
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

    -- 2. Send Notification to Admin & Cashiers (POS Inventory Alert)
    insert into public.admin_notifications (
      title,
      message,
      type,
      metadata
    )
    values (
      'Inventory Restocked: ' || coalesce(new.name, 'Feeds'),
      coalesce(new.name, 'Feeds') || ' restocked from 0 to ' || new.units || ' units. POS inventory updated.',
      'inventory_restock',
      jsonb_build_object(
        'product_id', new.id,
        'product_name', new.name,
        'new_units', new.units
      )
    );

  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Drop old trigger if exists
drop trigger if exists trigger_on_feed_restock on public.inventory_products;

-- Create trigger on inventory_products table when units column is updated
create trigger trigger_on_feed_restock
  after update of units on public.inventory_products
  for each row execute function public.notify_on_feed_restock();

commit;

-- Enable Supabase Realtime safely without duplicate publication error
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'raiser_notifications'
  ) then
    alter publication supabase_realtime add table public.raiser_notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'admin_notifications'
  ) then
    alter publication supabase_realtime add table public.admin_notifications;
  end if;
end $$;

notify pgrst, 'reload schema';
