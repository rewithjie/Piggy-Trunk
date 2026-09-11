-- 45_partner_investment_approval_and_activity_notifications.sql
-- Complete workflow triggers for:
-- 1. Partner Investment Submission (Pending Admin Approval)
-- 2. Admin Approval & Rejection of Partner Investment
-- 3. Hog Raiser Activity/Report Notification to Partner Investor
-- 4. Hogs Sold / Harvest Notification to Partner Investor

begin;

-- ==============================================================================
-- 1. TRIGGER: On investments INSERT (Pending Admin Approval & Partner Notification)
-- ==============================================================================
create or replace function public.notify_on_partner_investment_submission()
returns trigger as $$
declare
  p_name text;
  b_name text;
  formatted_amount text;
begin
  -- Resolve Partner Investor Name
  select coalesce(u.name, 'Partner Investor') into p_name
  from public.partner_investors pi
  left join public.app_users u on u.user_id = pi.user_id
  where pi.partner_investor_id = new.partner_investor_id;

  -- Resolve Batch Name
  select coalesce(batch_name, 'Batch #' || new.batch_id) into b_name
  from public.batches
  where batch_id = new.batch_id;

  formatted_amount := '₱' || to_char(new.amount, 'FM999,999,990.00');

  -- A. If inserted as 'pending', notify Admin to review and approve
  if lower(coalesce(new.status, 'pending')) = 'pending' then
    -- Admin Notification
    insert into public.admin_notifications (title, message, type, metadata)
    values (
      'New Investment Approval Request',
      coalesce(p_name, 'A Partner Investor') || ' submitted an investment of ' || formatted_amount || ' for ' || b_name || '. Pending your review and approval.',
      'investment_approval',
      jsonb_build_object(
        'investment_id', new.investment_id,
        'batch_id', new.batch_id,
        'batch_name', b_name,
        'amount', new.amount,
        'partner_investor_id', new.partner_investor_id,
        'partner_name', p_name,
        'status', 'pending'
      )
    );

    -- Partner Confirmation Notification
    insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
    values (
      new.partner_investor_id,
      'Investment Submitted ⏳',
      'Your investment of ' || formatted_amount || ' for ' || b_name || ' has been submitted and is currently pending Admin verification.',
      'investment_pending',
      jsonb_build_object(
        'investment_id', new.investment_id,
        'batch_id', new.batch_id,
        'batch_name', b_name,
        'amount', new.amount,
        'status', 'pending'
      )
    );
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_notify_on_partner_investment_submission on public.investments;
create trigger trigger_notify_on_partner_investment_submission
  after insert on public.investments
  for each row execute function public.notify_on_partner_investment_submission();


-- ==============================================================================
-- 2. TRIGGER: On investments UPDATE (Admin Approves or Rejects Investment)
-- ==============================================================================
create or replace function public.notify_on_partner_investment_status_change()
returns trigger as $$
declare
  p_name text;
  b_name text;
  r_id bigint;
  r_name text;
  formatted_amount text;
begin
  if old.status is distinct from new.status then
    -- Resolve Partner Name
    select coalesce(u.name, 'Partner Investor') into p_name
    from public.partner_investors pi
    left join public.app_users u on u.user_id = pi.user_id
    where pi.partner_investor_id = new.partner_investor_id;

    -- Resolve Batch Name
    select coalesce(batch_name, 'Batch #' || new.batch_id) into b_name
    from public.batches
    where batch_id = new.batch_id;

    formatted_amount := '₱' || to_char(new.amount, 'FM999,999,990.00');

    -- CASE A: APPROVED / ACTIVE
    if lower(new.status) in ('active', 'approved') then
      -- 1. Notify Partner Investor (English)
      insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
      values (
        new.partner_investor_id,
        'Investment Approved! 🎉',
        'Great news! Your investment of ' || formatted_amount || ' for ' || b_name || ' has been approved by the Admin and is now officially active.',
        'investment_approved',
        jsonb_build_object(
          'investment_id', new.investment_id,
          'batch_id', new.batch_id,
          'batch_name', b_name,
          'amount', new.amount,
          'status', 'active'
        )
      );

      -- 2. Resolve Assigned Hog Raiser and notify in Tagalog
      select a.hog_raiser_id, coalesce(hr.name, u.name, 'Assigned Raiser') into r_id, r_name
      from public.assignments a
      left join public.hog_raisers hr on hr.hog_raiser_id = a.hog_raiser_id
      left join public.app_users u on u.user_id = hr.user_id
      where a.batch_id = new.batch_id
      order by a.assigned_date desc
      limit 1;

      if r_id is not null then
        insert into public.raiser_notifications (hog_raiser_id, title, message, type, metadata)
        values (
          r_id,
          'May Bagong Pondo ang Iyong Batch! 🐖',
          'Magandang balita! Ang iyong batch na ' || b_name || ' ay inaprubahan at nakatanggap ng pondong ' || formatted_amount || ' mula kay ' || p_name || '. Pagbutihin ang pag-aalaga!',
          'investment',
          jsonb_build_object(
            'investment_id', new.investment_id,
            'batch_id', new.batch_id,
            'batch_name', b_name,
            'amount', new.amount,
            'partner_name', p_name
          )
        );
      end if;

    -- CASE B: REJECTED / DECLINED
    elsif lower(new.status) in ('rejected', 'declined') then
      insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
      values (
        new.partner_investor_id,
        'Investment Request Update ⚠️',
        'Your investment submission of ' || formatted_amount || ' for ' || b_name || ' could not be approved at this time. Please contact support or review details.',
        'investment_rejected',
        jsonb_build_object(
          'investment_id', new.investment_id,
          'batch_id', new.batch_id,
          'batch_name', b_name,
          'amount', new.amount,
          'status', 'rejected'
        )
      );
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_notify_on_partner_investment_status_change on public.investments;
create trigger trigger_notify_on_partner_investment_status_change
  after update of status on public.investments
  for each row execute function public.notify_on_partner_investment_status_change();


-- ==============================================================================
-- 3. TRIGGER: On hog_reports INSERT (Notify Partner Investor of Raiser Activities)
-- ==============================================================================
create or replace function public.notify_partners_on_hog_report()
returns trigger as $$
declare
  r_name text;
  p_rec record;
begin
  -- Resolve Raiser Name
  select coalesce(hr.name, u.name, 'Hog Raiser') into r_name
  from public.hog_raisers hr
  left join public.app_users u on u.user_id = hr.user_id
  where hr.hog_raiser_id = new.hog_raiser_id;

  -- Find all partner investors who have an active investment in batches assigned to this raiser
  for p_rec in (
    select distinct i.partner_investor_id, coalesce(b.batch_name, 'Batch #' || b.batch_id) as batch_name
    from public.assignments a
    join public.batches b on b.batch_id = a.batch_id
    join public.investments i on i.batch_id = a.batch_id and lower(i.status) in ('active', 'approved')
    where a.hog_raiser_id = new.hog_raiser_id
  ) loop
    insert into public.partner_notifications (
      partner_investor_id,
      title,
      message,
      type,
      metadata
    )
    values (
      p_rec.partner_investor_id,
      'Hog Raiser Activity Update 📋',
      coalesce(r_name, 'Your assigned raiser') || ' submitted a new ' || coalesce(new.report_type, 'Routine') || ' log: ' || coalesce(new.description, 'Health & care update logged') || '.',
      'raiser_activity',
      jsonb_build_object(
        'report_id', new.report_id,
        'report_type', new.report_type,
        'raiser_name', r_name,
        'batch_name', p_rec.batch_name
      )
    );
  end loop;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_notify_partners_on_hog_report on public.hog_reports;
create trigger trigger_notify_partners_on_hog_report
  after insert on public.hog_reports
  for each row execute function public.notify_partners_on_hog_report();


-- ==============================================================================
-- 4. TRIGGER: On hogs UPDATE (Notify Partner Investor when Hogs are Sold / Harvested)
-- ==============================================================================
create or replace function public.notify_partners_on_hogs_sold()
returns trigger as $$
declare
  p_rec record;
begin
  if (old.health_status is distinct from new.health_status and lower(new.health_status) = 'sold')
     or (old.status is distinct from new.status and lower(new.status) = 'sold') then

    for p_rec in (
      select distinct i.partner_investor_id, coalesce(b.batch_name, 'Batch #' || b.batch_id) as batch_name
      from public.assignments a
      join public.batches b on b.batch_id = a.batch_id
      join public.investments i on i.batch_id = a.batch_id and lower(i.status) in ('active', 'approved')
      where a.assignment_id = new.assignment_id
    ) loop
      insert into public.partner_notifications (
        partner_investor_id,
        title,
        message,
        type,
        metadata
      )
      values (
        p_rec.partner_investor_id,
        'Hogs Sold & Harvest Complete! 💰',
        'Great news! Hogs from your invested project (' || p_rec.batch_name || ') have been successfully sold. Check your project overview for harvest returns.',
        'hogs_sold',
        jsonb_build_object(
          'hog_id', new.hog_id,
          'assignment_id', new.assignment_id,
          'batch_name', p_rec.batch_name
        )
      );
    end loop;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_notify_partners_on_hogs_sold on public.hogs;
create trigger trigger_notify_partners_on_hogs_sold
  after update of health_status, status on public.hogs
  for each row execute function public.notify_partners_on_hogs_sold();

commit;

-- Reload postgrest schema
notify pgrst, 'reload schema';
