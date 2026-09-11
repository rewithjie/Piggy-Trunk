-- 25_hog_triggers.sql
-- Triggers for Automatic Batch/Assignment Creation and Hog Health Reporting Alerts.

begin;

-- 1. Auto-create Batch, Assignment, and Hogs when an investment_record is created
create or replace function public.fn_auto_create_batch_and_assignment()
returns trigger as $$
declare
  v_hog_type_id bigint;
  v_batch_id bigint;
  v_assignment_id bigint;
  i integer;
begin
  -- 1. Get or create hog_type
  select hog_type_id into v_hog_type_id
  from public.hog_types
  where lower(type_name) = lower(new.hog_type)
  limit 1;
  
  if v_hog_type_id is null then
    insert into public.hog_types (type_name, description)
    values (new.hog_type, 'Auto-generated from investment')
    returning hog_type_id into v_hog_type_id;
  end if;

  -- 2. Create a unique batch name linked to the investment
  insert into public.batches (batch_name, date_created)
  values (new.raiser_name || ' - ' || to_char(new.investment_date, 'Mon DD, YYYY') || ' - ' || new.hog_type || ' (' || new.id::text || ')', new.investment_date)
  returning batch_id into v_batch_id;

  -- 3. Create the assignment linking raiser, batch, and type
  insert into public.assignments (assigned_date, status, hog_type_id, batch_id, hog_raiser_id)
  values (new.investment_date, 'active', v_hog_type_id, v_batch_id, (new.hog_raiser_id)::bigint)
  returning assignment_id into v_assignment_id;

  -- 4. Automatically insert the hogs for this batch (15.0kg initial weight)
  for i in 1..new.total_hog loop
    insert into public.hogs (status, health_status, weight, assignment_id)
    values ('active', 'Healthy', 15.0, v_assignment_id);
  end loop;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_auto_create_batch_and_assignment on public.investment_records;
create trigger trg_auto_create_batch_and_assignment
  after insert on public.investment_records
  for each row execute function public.fn_auto_create_batch_and_assignment();


-- 2. Notify Admin on Hog Report / Health Alert (Rich Details & Incident Modal Support)
create or replace function public.notify_admin_on_hog_report()
returns trigger as $$
declare
  v_raiser_name text;
  v_batch_name text;
  v_batch_id bigint;
  v_message text;
  v_hog_label text;
begin
  -- Fetch raiser name
  select name into v_raiser_name 
  from public.hog_raisers 
  where hog_raiser_id = new.hog_raiser_id;

  -- Resolve batch_id and batch_name
  v_batch_id := new.batch_id;
  if v_batch_id is null then
    select a.batch_id, b.batch_name into v_batch_id, v_batch_name
    from public.assignments a
    left join public.batches b on b.batch_id = a.batch_id
    where a.hog_raiser_id = new.hog_raiser_id
    order by a.assigned_date desc
    limit 1;
  else
    select batch_name into v_batch_name from public.batches where batch_id = v_batch_id;
  end if;

  -- Resolve hog label
  if new.hog_id is not null then
    v_hog_label := 'Hog #' || new.hog_id;
  else
    v_hog_label := 'Assigned Hog';
  end if;

  -- Construct informative notification message
  v_message := coalesce(v_raiser_name, 'Hog raiser') || ' reported: ' || coalesce(new.report_type, 'Health Alert') || ' for ' || v_hog_label;
  if v_batch_name is not null then
    v_message := v_message || ' (' || v_batch_name || ')';
  end if;
  if new.description is not null and trim(new.description) <> '' then
    v_message := v_message || ' - "' || trim(new.description) || '"';
  else
    v_message := v_message || '.';
  end if;

  -- Insert rich notification
  insert into public.admin_notifications (title, message, type, metadata)
  values (
    'Hog Health Alert',
    v_message,
    'hog_report',
    jsonb_build_object(
      'report_id', new.report_id,
      'hog_id', new.hog_id,
      'hog_label', v_hog_label,
      'hog_raiser_id', new.hog_raiser_id,
      'raiser_name', v_raiser_name,
      'batch_id', v_batch_id,
      'batch_name', v_batch_name,
      'report_type', new.report_type,
      'description', new.description,
      'date_reported', coalesce(new.created_at, now())
    )
  );

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_on_hog_report_admin on public.hog_reports;
create trigger trigger_on_hog_report_admin
  after insert on public.hog_reports
  for each row execute function public.notify_admin_on_hog_report();


-- 3. Notify Partner Investors on Hog Report / Farm Activity
create or replace function public.notify_partners_on_hog_report()
returns trigger as $$
declare
  r_name text;
  b_id bigint;
  b_name text;
  partner_rec record;
  partner_count int := 0;
begin
  select name into r_name 
  from public.hog_raisers 
  where hog_raiser_id = new.hog_raiser_id;

  select a.batch_id, b.batch_name into b_id, b_name
  from public.assignments a
  left join public.batches b on b.batch_id = a.batch_id
  where a.hog_raiser_id = new.hog_raiser_id
  order by a.assigned_date desc
  limit 1;

  if b_id is not null then
    for partner_rec in (
      select distinct partner_investor_id 
      from public.investments 
      where batch_id = b_id
    ) loop
      partner_count := partner_count + 1;
      insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
      values (
        partner_rec.partner_investor_id,
        'Hog Raiser Update: ' || coalesce(new.report_type, 'Activity'),
        coalesce(r_name, 'Your hog raiser') || ' logged an update for ' || coalesce(b_name, 'Batch #' || b_id) || ': ' || coalesce(new.description, new.report_type) || '.',
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

  if partner_count = 0 then
    for partner_rec in (
      select partner_investor_id 
      from public.partner_investors
    ) loop
      insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
      values (
        partner_rec.partner_investor_id,
        'Farm Update: ' || coalesce(new.report_type, 'Activity'),
        coalesce(r_name, 'Hog raiser') || ' posted a new log: ' || coalesce(new.description, new.report_type) || '.',
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

drop trigger if exists trigger_on_hog_report_partner on public.hog_reports;
create trigger trigger_on_hog_report_partner
  after insert on public.hog_reports
  for each row execute function public.notify_partners_on_hog_report();

commit;
