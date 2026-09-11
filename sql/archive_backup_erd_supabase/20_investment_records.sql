-- 20_investment_records.sql
-- Creates a denormalized `investment_records` table for the admin Investments screen.

begin;

create table if not exists public.investment_records (
  id              uuid            default gen_random_uuid() primary key,
  hog_raiser_id   text            not null,
  raiser_name     text            not null,
  initial_capital numeric(14,2)   not null default 0 check (initial_capital >= 0),
  hog_type        text            not null default 'Fattening',
  total_hog       integer         not null default 0 check (total_hog >= 0),
  investment_date date            not null default current_date,
  stage           text            not null default 'pending'
);

create index if not exists idx_investment_records_raiser on public.investment_records(hog_raiser_id);
create index if not exists idx_investment_records_date   on public.investment_records(investment_date desc);
create index if not exists idx_investment_records_stage  on public.investment_records(stage);

alter table public.investment_records enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'investment_records'
      and policyname = 'investment_records_auth_all'
  ) then
    create policy investment_records_auth_all
      on public.investment_records
      for all to authenticated
      using (true) with check (true);
  end if;
end $$;

commit;
