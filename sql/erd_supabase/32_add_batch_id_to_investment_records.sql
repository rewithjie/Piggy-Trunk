-- 32_add_batch_id_to_investment_records.sql
-- Adds batch_id and batch_name columns to investment_records table for direct batch-to-investment association.

alter table public.investment_records 
  add column if not exists batch_id text,
  add column if not exists batch_name text;

create index if not exists idx_investment_records_batch_id 
  on public.investment_records(batch_id);
