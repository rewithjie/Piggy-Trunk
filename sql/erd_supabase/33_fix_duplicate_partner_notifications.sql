-- ==============================================================================
-- 34_fix_duplicate_partner_notifications.sql
-- Fix redundant/duplicate partner notifications on hog health reports:
-- 1. Drops all previous conflicting/duplicate trigger names on public.hog_reports
-- 2. Creates a single unified trigger to notify partners on hog health reports
-- 3. Cleans up existing historical duplicate rows in partner_notifications
-- ==============================================================================

-- 1. Drop ALL conflicting trigger variants on public.hog_reports
drop trigger if exists trigger_notify_partners_on_hog_report on public.hog_reports;
drop trigger if exists trigger_on_hog_report_partner on public.hog_reports;
drop trigger if exists trigger_partner_hog_report on public.hog_reports;
drop trigger if exists trigger_notify_partner_on_hog_report on public.hog_reports;

-- 2. Ensure clean notification function that notifies partners exactly once
create or replace function public.notify_partners_on_hog_report()
returns trigger as $$
declare
  r_name text;
  b_id bigint;
  b_name text;
  partner_rec record;
  partner_count int := 0;
begin
  -- Resolve the raiser's full name
  select coalesce(name, 'Hog Raiser') into r_name 
  from public.hog_raisers 
  where hog_raiser_id = new.hog_raiser_id;

  -- Determine batch ID: check direct report batch_id first
  b_id := new.batch_id;
  if b_id is not null then
    select batch_name into b_name from public.batches where batch_id = b_id;
  end if;

  -- If null, look up latest active assignment for this raiser
  if b_id is null then
    select a.batch_id, b.batch_name into b_id, b_name
    from public.assignments a
    left join public.batches b on b.batch_id = a.batch_id
    where a.hog_raiser_id = new.hog_raiser_id
    order by a.assigned_date desc
    limit 1;
  end if;

  -- Notify partner investors who funded this specific batch
  if b_id is not null then
    for partner_rec in (
      select distinct partner_investor_id 
      from public.investments 
      where batch_id = b_id
        and lower(coalesce(status, 'active')) in ('active', 'approved')
    ) loop
      partner_count := partner_count + 1;
      insert into public.partner_notifications (
        partner_investor_id,
        title,
        message,
        type,
        metadata
      )
      values (
        partner_rec.partner_investor_id,
        'Farm Health Alert: ' || coalesce(new.report_type, 'Alert'),
        coalesce(r_name, 'Hog raiser') || ' reported: ' || coalesce(new.description, new.report_type) || '.',
        'hog_report',
        jsonb_build_object(
          'report_id', new.report_id,
          'hog_id', new.hog_id,
          'hog_raiser_id', new.hog_raiser_id,
          'raiser_name', r_name,
          'batch_id', b_id,
          'batch_name', b_name,
          'report_type', new.report_type,
          'description', new.description
        )
      );
    end loop;
  end if;

  -- Fallback: If no partner is specifically attached to this batch yet, notify active partners
  if partner_count = 0 then
    for partner_rec in (
      select partner_investor_id 
      from public.partner_investors
    ) loop
      insert into public.partner_notifications (
        partner_investor_id,
        title,
        message,
        type,
        metadata
      )
      values (
        partner_rec.partner_investor_id,
        'Farm Health Alert: ' || coalesce(new.report_type, 'Alert'),
        coalesce(r_name, 'Hog raiser') || ' reported: ' || coalesce(new.description, new.report_type) || '.',
        'hog_report',
        jsonb_build_object(
          'report_id', new.report_id,
          'hog_id', new.hog_id,
          'hog_raiser_id', new.hog_raiser_id,
          'raiser_name', r_name,
          'report_type', new.report_type,
          'description', new.description
        )
      );
    end loop;
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- 3. Re-create single trigger on hog_reports
create trigger trigger_on_hog_report_partner
  after insert on public.hog_reports
  for each row execute function public.notify_partners_on_hog_report();

-- 4. Clean up historical duplicate notifications in partner_notifications table
-- (Keeps the earliest record and removes redundant duplicates with higher notification_id)
delete from public.partner_notifications a
using public.partner_notifications b
where a.partner_investor_id = b.partner_investor_id
  and a.title = b.title
  and a.message = b.message
  and a.notification_id > b.notification_id;
