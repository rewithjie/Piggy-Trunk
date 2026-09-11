-- 24_investment_triggers.sql
-- Real-time notification triggers for Partner Investments & Admin Investment Assignments.

begin;

-- 1. Trigger Function: Direct Partner Investment Confirmation
create or replace function public.notify_on_direct_partner_investment()
returns trigger as $$
declare
  p_name text;
  b_name text;
  r_id bigint;
  r_name text;
  formatted_amount text;
begin
  -- Resolve Partner Investor Name
  select coalesce(u.name, 'Partner Investor') into p_name
  from public.partner_investors pi
  left join public.app_users u on u.user_id = pi.user_id
  where pi.partner_investor_id = new.partner_investor_id;

  -- Resolve Batch Name & Assigned Hog Raiser
  select
    coalesce(b.batch_name, 'Batch #' || new.batch_id),
    b.hog_raiser_id,
    coalesce(u.name, hr.name, 'Hog Raiser')
  into b_name, r_id, r_name
  from public.batches b
  left join public.hog_raisers hr on hr.hog_raiser_id = b.hog_raiser_id
  left join public.app_users u on u.user_id = hr.user_id
  where b.batch_id = new.batch_id;

  formatted_amount := '₱' || to_char(new.amount, 'FM999,999,990.00');

  -- A. Admin Notification
  insert into public.admin_notifications (title, message, type, metadata)
  values (
    'New Partner Investment',
    coalesce(p_name, 'A Partner Investor') || ' invested ' || formatted_amount || ' in ' || b_name || '.',
    'investment',
    jsonb_build_object(
      'investment_id', new.investment_id,
      'batch_id', new.batch_id,
      'batch_name', b_name,
      'amount', new.amount,
      'partner_investor_id', new.partner_investor_id,
      'partner_name', p_name
    )
  );

  -- B. Partner Immediate Confirmation Notification
  insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
  values (
    new.partner_investor_id,
    'Investment Confirmed! 🎉',
    'Your investment of ' || formatted_amount || ' for ' || b_name || ' is active. Thank you for partnering with us!',
    'investment_confirmed',
    jsonb_build_object(
      'investment_id', new.investment_id,
      'batch_id', new.batch_id,
      'batch_name', b_name,
      'amount', new.amount
    )
  );

  -- C. Hog Raiser Notification (if raiser is linked to the batch)
  if r_id is not null then
    insert into public.raiser_notifications (hog_raiser_id, title, message, type, metadata)
    values (
      r_id,
      'May Bagong Pondo ang Iyong Batch! 💰',
      coalesce(p_name, 'Isang Partner Investor') || ' ang naglaan ng ' || formatted_amount || ' na pondo para sa ' || b_name || '.',
      'investment_received',
      jsonb_build_object(
        'investment_id', new.investment_id,
        'batch_id', new.batch_id,
        'batch_name', b_name,
        'amount', new.amount
      )
    );
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_on_direct_partner_investment on public.investments;
create trigger trigger_on_direct_partner_investment
  after insert on public.investments
  for each row execute function public.notify_on_direct_partner_investment();


-- 2. Trigger Function: Admin Investment Record Assignment to Raiser
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
      ) values (
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

drop trigger if exists trigger_on_admin_investment_record_assignment on public.investment_records;
create trigger trigger_on_admin_investment_record_assignment
  after insert or update of hog_raiser_id on public.investment_records
  for each row execute function public.notify_raiser_on_admin_investment_record();


-- 3. Trigger Function: Batch Assignment Notification for Raiser
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
    ) values (
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

drop trigger if exists trigger_on_batch_assignment on public.assignments;
create trigger trigger_on_batch_assignment
  after insert or update of hog_raiser_id on public.assignments
  for each row execute function public.notify_raiser_on_batch_assignment();

commit;
