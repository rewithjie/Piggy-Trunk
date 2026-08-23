-- 46_clean_duplicate_investment_triggers.sql
-- Removes legacy / conflicting auto-confirm triggers on public.investments table
-- Ensures ONLY the approval workflow triggers (Pending -> Approved) are active.

begin;

-- 1. Drop old duplicate triggers on public.investments
drop trigger if exists trigger_notify_all_on_partner_investment on public.investments;
drop trigger if exists trigger_on_partner_investment on public.investments;
drop function if exists public.notify_all_on_partner_investment();

-- 2. Drop existing triggers from 45 to cleanly re-attach
drop trigger if exists trigger_notify_on_partner_investment_submission on public.investments;
drop trigger if exists trigger_notify_on_partner_investment_status_change on public.investments;

-- 3. Trigger on INSERT: Only fires for pending investment submissions
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

  -- If inserted as 'pending', notify Admin to review and approve (Do NOT send confirmed to partner!)
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

    -- Partner Pending Confirmation Notification
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

create trigger trigger_notify_on_partner_investment_submission
  after insert on public.investments
  for each row execute function public.notify_on_partner_investment_submission();


-- 4. Trigger on UPDATE: Fires ONLY when Admin changes status to 'active' / 'approved' or 'rejected'
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

create trigger trigger_notify_on_partner_investment_status_change
  after update of status on public.investments
  for each row execute function public.notify_on_partner_investment_status_change();

commit;

notify pgrst, 'reload schema';
