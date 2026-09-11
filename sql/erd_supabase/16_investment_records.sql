create table if not exists public.investment_records (
  id uuid default gen_random_uuid() primary key,
  hog_raiser_id text not null,
  raiser_name text not null,
  initial_capital numeric(14,2) not null default 0 check (initial_capital >= 0),
  hog_type text not null default 'Fattening',
  total_hog integer not null default 0 check (total_hog >= 0),
  investment_date date not null default current_date,
  stage text not null default 'pending'
);

create index if not exists idx_investment_records_raiser on public.investment_records(hog_raiser_id);
create index if not exists idx_investment_records_date on public.investment_records(investment_date desc);
create index if not exists idx_investment_records_stage on public.investment_records(stage);
