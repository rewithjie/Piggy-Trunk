-- ==============================================================================
-- 47_direct_partner_investment_confirmation.sql
-- Removes Admin approval requirement for Partner Investments (Direct Confirmation).
-- When a Partner invests, it is directly active, and notifies Admin, Partner, and Raiser.
-- ==============================================================================

begin;

-- 1. Automatically activate any existing pending partner investments
update public.investments
set status = 'active'
where status = 'pending';

-- 2. Drop pending approval triggers
drop trigger if exists trigger_notify_on_partner_investment_submission on public.investments;
drop trigger if exists trigger_notify_on_partner_investment_status_change on public.investments;
drop trigger if exists trigger_notify_all_on_partner_investment on public.investments;
drop trigger if exists trigger_on_partner_investment on public.investments;

drop function if exists public.notify_on_partner_investment_submission();
drop function if exists public.notify_on_partner_investment_status_change();
drop function if exists public.notify_all_on_partner_investment();

-- 3. Create direct investment notification trigger
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

  -- A. Admin Notification (Informative, no approval needed)
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
      'partner_name', p_name,
      'status', 'active'
    )
  );

  -- B. Partner Confirmation Notification (Instant Confirmation 🎉)
  insert into public.partner_notifications (partner_investor_id, title, message, type, metadata)
  values (
    new.partner_investor_id,
    'Investment Confirmed 🎉',
    'Your investment of ' || formatted_amount || ' for ' || b_name || ' has been successfully confirmed and is now active.',
    'investment_confirmed',
    jsonb_build_object(
      'investment_id', new.investment_id,
      'batch_id', new.batch_id,
      'batch_name', b_name,
      'amount', new.amount,
      'status', 'active'
    )
  );

  -- C. Hog Raiser Notification (Tagalog: May Bagong Pondo ang Iyong Batch!)
  if r_id is not null then
    insert into public.raiser_notifications (hog_raiser_id, title, message, type, metadata)
    values (
      r_id,
      'May Bagong Pondo ang Iyong Batch! 🐖',
      'Si ' || coalesce(p_name, 'isang Partner Investor') || ' ay nag-invest ng ' || formatted_amount || ' para sa iyong ' || b_name || '.',
      'investment_received',
      jsonb_build_object(
        'investment_id', new.investment_id,
        'batch_id', new.batch_id,
        'batch_name', b_name,
        'amount', new.amount,
        'partner_name', p_name
      )
    );
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- 4. Attach trigger on INSERT
create trigger trigger_notify_on_direct_partner_investment
  after insert on public.investments
  for each row execute function public.notify_on_direct_partner_investment();

commit;
