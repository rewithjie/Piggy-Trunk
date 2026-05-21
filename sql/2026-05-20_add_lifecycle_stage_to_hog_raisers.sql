-- Adds persistent lifecycle stage for hog raisers.
-- Run this in Supabase SQL Editor.

alter table public.hog_raisers
add column if not exists lifecycle_stage text;

alter table public.hog_raisers
add constraint hog_raisers_lifecycle_stage_check
check (
  lifecycle_stage is null
  or lifecycle_stage in ('Booster', 'Pre-Starter', 'Starter', 'Grower', 'Finisher', 'Selling')
);

comment on column public.hog_raisers.lifecycle_stage
is 'Lifecycle stage for hog growing flow. Null means not yet assigned to any investment.';
