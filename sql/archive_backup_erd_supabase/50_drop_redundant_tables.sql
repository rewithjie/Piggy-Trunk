-- ==============================================================================
-- 50_drop_redundant_tables.sql
-- Safely drops the 5 unused/redundant prototype tables in public schema
-- ==============================================================================

begin;

-- 1. Drop unused logs table (superseded by inventory_logs and hog_reports)
drop table if exists public.logs cascade;

-- 2. Drop unused supply table (superseded by inventory_products)
drop table if exists public.supply cascade;

-- 3. Drop unused capital_infusions table (superseded by investments and investment_records)
drop table if exists public.capital_infusions cascade;

-- 4. Drop unused hog_stage_logs table (superseded by hog_reports)
drop table if exists public.hog_stage_logs cascade;

-- 5. Drop unused hog_stages table (lifecycle_stage is handled directly in hogs table)
drop table if exists public.hog_stages cascade;

commit;

notify pgrst, 'reload schema';
