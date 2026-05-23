-- Enable RLS on all app tables.
alter table public.app_users enable row level security;
alter table public.logs enable row level security;
alter table public.cashiers enable row level security;
alter table public.partner_investors enable row level security;
alter table public.batches enable row level security;
alter table public.hog_types enable row level security;
alter table public.hog_raisers enable row level security;
alter table public.hog_stages enable row level security;
alter table public.assignments enable row level security;
alter table public.hogs enable row level security;
alter table public.hog_stage_logs enable row level security;
alter table public.stock_requests enable row level security;
alter table public.capital_infusions enable row level security;
alter table public.products enable row level security;
alter table public.supply enable row level security;
alter table public.sales enable row level security;
alter table public.investments enable row level security;

-- Simple starter policy: authenticated users can read/write.
-- Tighten this later based on role rules.
do $$
declare
  t text;
  p text;
begin
  foreach t in array array[
    'app_users','logs','cashiers','partner_investors','batches','hog_types','hog_raisers',
    'hog_stages','assignments','hogs','hog_stage_logs','stock_requests','capital_infusions',
    'products','supply','sales','investments'
  ]
  loop
    p := t || '_auth_all';
    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = t
        and policyname = p
    ) then
      execute format(
        'create policy %I on public.%I for all to authenticated using (true) with check (true);',
        p,
        t
      );
    end if;
  end loop;
end $$;
