-- 41_notify_on_partner_investment.sql
-- Automatic multi-role notification trigger when a Partner Investor funds a batch.
-- Notifies:
--   1. Admin (admin_notifications)
--   2. Assigned Hog Raiser (raiser_notifications in Tagalog)
--   3. Partner Investor (partner_notifications)

begin;

create or replace function public.notify_all_on_partner_investment()
returns trigger as $$
declare
  p_name text;
  b_name text;
  r_id bigint;
  r_name text;
  formatted_amount text;
begin
  -- 1. Resolve Partner Investor Name
  select coalesce(u.name, 'Isang Partner Investor') into p_name
  from public.partner_investors pi
  left join public.app_users u on u.user_id = pi.user_id
  where pi.partner_investor_id = new.partner_investor_id;

  -- 2. Resolve Batch Name
  select coalesce(batch_name, 'Batch #' || new.batch_id) into b_name
  from public.batches
  where batch_id = new.batch_id;

  -- 3. Resolve Assigned Hog Raiser
  select a.hog_raiser_id, coalesce(hr.name, u.name, 'Assigned Raiser') into r_id, r_name
  from public.assignments a
  left join public.hog_raisers hr on hr.hog_raiser_id = a.hog_raiser_id
  left join public.app_users u on u.user_id = hr.user_id
  where a.batch_id = new.batch_id
  order by a.assigned_date desc
  limit 1;

  formatted_amount := '₱' || to_char(new.amount, 'FM999,999,990.00');

  -- 4. Notify Admin (English / Standard)
  insert into public.admin_notifications (title, message, type, metadata)
  values (
    'New Partner Investment',
    coalesce(p_name, 'A Partner Investor') || ' invested ' || formatted_amount || ' in ' || b_name || (case when r_name is not null then ' (Raiser: ' || r_name || ')' else '' end) || '.',
    'investment',
    jsonb_build_object(
      'investment_id', new.investment_id,
      'batch_id', new.batch_id,
      'batch_name', b_name,
      'amount', new.amount,
      'partner_investor_id', new.partner_investor_id,
      'partner_name', p_name,
      'hog_raiser_id', r_id,
      'raiser_name', r_name
    )
  );

  -- 5. Notify Assigned Hog Raiser (in friendly, encouraging Tagalog)
  if r_id is not null then
    insert into public.raiser_notifications (hog_raiser_id, title, message, type, metadata)
    values (
      r_id,
      'May Bagong Pondo ang Iyong Batch!',
      'Magandang balita! Ang iyong batch na ' || b_name || ' ay nakatanggap ng pondong ' || formatted_amount || ' mula kay ' || p_name || '. Pagbutihin ang pag-aalaga!',
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

  return new;
end;
$$ language plpgsql security definer;

-- Drop existing trigger if any and recreate
drop trigger if exists trigger_notify_all_on_partner_investment on public.investments;
create trigger trigger_notify_all_on_partner_investment
after insert on public.investments
for each row execute function public.notify_all_on_partner_investment();

commit;

notify pgrst, 'reload schema';
