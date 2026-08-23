-- 44_notify_raiser_on_admin_investment_assignment.sql
-- Automatic Real-Time Notification Trigger for Hog Raiser when Admin assigns an Investment or Batch.

begin;

-- 1. Trigger for Admin Investment Records Assignment (investment_records table)
create or replace function public.notify_raiser_on_admin_investment_record()
returns trigger as $$
declare
  r_id bigint;
  cap_text text;
begin
  if new.hog_raiser_id is not null and trim(new.hog_raiser_id::text) != '' and trim(new.hog_raiser_id::text) != 'unassigned' then
    begin
      r_id := (new.hog_raiser_id)::bigint;
    exception when others then
      r_id := null;
    end;

    if r_id is not null and (tg_op = 'INSERT' or old.hog_raiser_id is distinct from new.hog_raiser_id) then
      cap_text := case when new.initial_capital is not null and new.initial_capital > 0 then ' na may pondong ₱' || to_char(new.initial_capital, 'FM999,999,990.00') else '' end;
      
      insert into public.raiser_notifications (
        hog_raiser_id,
        title,
        message,
        type,
        metadata
      )
      values (
        r_id,
        'May Bagong Investment na Na-assign sa Iyo! 🐖',
        'Nag-assign ang Admin ng bagong investment na may ' || coalesce(new.total_hog, 0) || ' ' || coalesce(new.hog_type, 'baboy') || cap_text || ' para sa iyong pangangalaga.',
        'investment_assigned',
        jsonb_build_object(
          'investment_id', new.id,
          'hog_type', new.hog_type,
          'total_hog', new.total_hog,
          'initial_capital', new.initial_capital
        )
      );
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Drop old trigger if exists
drop trigger if exists trigger_on_investment_insert on public.investment_records;
drop trigger if exists trigger_on_admin_investment_record_assignment on public.investment_records;

-- Attach trigger to investment_records
create trigger trigger_on_admin_investment_record_assignment
  after insert or update of hog_raiser_id on public.investment_records
  for each row execute function public.notify_raiser_on_admin_investment_record();


-- 2. Trigger for Batch Assignment (assignments table)
create or replace function public.notify_raiser_on_batch_assignment()
returns trigger as $$
declare
  b_name text;
begin
  if new.hog_raiser_id is not null and (tg_op = 'INSERT' or old.hog_raiser_id is distinct from new.hog_raiser_id) then
    select coalesce(batch_name, 'Batch #' || new.batch_id) into b_name
    from public.batches
    where batch_id = new.batch_id;

    insert into public.raiser_notifications (
      hog_raiser_id,
      title,
      message,
      type,
      metadata
    )
    values (
      new.hog_raiser_id,
      'Bagong Batch na Na-assign sa Iyo! 🐷',
      'Na-assign sa iyo ng Admin ang ' || coalesce(b_name, 'bagong batch') || '. Maaari mo nang simulan ang pagsubaybay at pag-update ng logs.',
      'batch_assigned',
      jsonb_build_object(
        'assignment_id', new.assignment_id,
        'batch_id', new.batch_id,
        'batch_name', b_name
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Drop old trigger if exists
drop trigger if exists trigger_on_batch_assignment on public.assignments;

-- Attach trigger to assignments
create trigger trigger_on_batch_assignment
  after insert or update of hog_raiser_id on public.assignments
  for each row execute function public.notify_raiser_on_batch_assignment();

commit;

-- Reload postgrest schema
notify pgrst, 'reload schema';
