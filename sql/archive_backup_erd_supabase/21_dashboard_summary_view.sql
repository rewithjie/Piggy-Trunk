-- 21_dashboard_summary_view.sql
-- Creates a PostgreSQL view used by the Flutter Dashboard screen to fetch
-- all KPI metrics (active raisers, batches, total capital, mortality, allocation)
-- in a single query.
-- Updated to check account_status = 'active' instead of status = 'active' for active raisers.

create or replace view public.dashboard_summary as
select
  -- KPI 1: Active Hog Raisers (based on approved account_status)
  (
    select count(*)::bigint
    from public.hog_raisers
    where lower(account_status) = 'active'
  ) as active_raisers,

  -- KPI 2: Number of Hog Batches
  (
    select count(*)::bigint
    from public.batches
  ) as batch_count,

  -- KPI 3: Total Current Investment (from investment_records)
  (
    select coalesce(sum(initial_capital), 0)
    from public.investment_records
  ) as total_capital,

  -- KPI 4: Number of Mortality (hogs with status = 'dead')
  (
    select count(*)::bigint
    from public.hogs
    where lower(status) = 'dead'
  ) as mortality_count,

  -- Allocation: Fattening capital
  (
    select coalesce(sum(initial_capital), 0)
    from public.investment_records
    where lower(hog_type) = 'fattening'
  ) as fattening_capital,

  -- Allocation: Sow capital
  (
    select coalesce(sum(initial_capital), 0)
    from public.investment_records
    where lower(hog_type) = 'sow'
  ) as sow_capital,

  -- Earliest investment date (used for "Start of Investment" KPI display)
  (
    select min(investment_date)
    from public.investment_records
  ) as start_of_investment;

-- Grant read access to authenticated users
grant select on public.dashboard_summary to authenticated;
