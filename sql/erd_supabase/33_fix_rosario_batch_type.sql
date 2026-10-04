-- 33_fix_rosario_batch_type.sql
-- Repairs "Batch Test Rejiee" after a Sow/Breeding investment re-labeled Rosario's Fattening batch.
-- Run step 1 first and check the rows before running step 2.

-- STEP 1: Preview
select a.assignment_id, b.batch_name, ht.type_name, a.status
from public.assignments a
join public.batches b on b.batch_id = a.batch_id
left join public.hog_types ht on ht.hog_type_id = a.hog_type_id
where b.batch_name ilike '%Batch Test Rejiee%';

select id, raiser_name, hog_type, total_hog, initial_capital, investment_date
from public.investment_records
where raiser_name ilike '%Rosario%'
order by investment_date desc;

-- STEP 2: Fix
begin;

-- Restore the batch back to Fattening
update public.assignments a
set hog_type_id = (select hog_type_id from public.hog_types where type_name ilike '%fatten%' limit 1)
from public.batches b
where b.batch_id = a.batch_id
  and b.batch_name ilike '%Batch Test Rejiee%';

update public.hogs h
set pig_type = 'Fattening'
from public.assignments a
join public.batches b on b.batch_id = a.batch_id
where h.assignment_id = a.assignment_id
  and b.batch_name ilike '%Batch Test Rejiee%';

-- Restore Rosario's raiser type
update public.hog_raisers
set pig_type = 'Fattening'
where name ilike '%Rosario, Mark Rejie%';

-- Remove the wrong Sow investment (only the newest Sow record for Rosario)
delete from public.investment_records
where id = (
  select id from public.investment_records
  where raiser_name ilike '%Rosario%' and hog_type ilike '%sow%'
  order by investment_date desc
  limit 1
);

commit;
