-- 28_auto_batch_assignment.sql
-- Automatically creates a Batch, Assignment, and Hogs when an investment is created.
-- Automatically cleans them up if the investment is deleted.

begin;

create or replace function public.fn_auto_create_batch_and_assignment()
returns trigger as $$
declare
  v_hog_type_id bigint;
  v_batch_id bigint;
  v_assignment_id bigint;
  v_stage_id bigint;
  i integer;
begin
  -- 1. Get or create hog_type
  select hog_type_id into v_hog_type_id
  from public.hog_types
  where lower(type_name) = lower(new.hog_type)
  limit 1;
  
  if v_hog_type_id is null then
    insert into public.hog_types (type_name, description)
    values (new.hog_type, 'Auto-generated from investment')
    returning hog_type_id into v_hog_type_id;
  end if;

  -- 2. Create a unique batch name linked to the investment UUID
  insert into public.batches (batch_name, date_created)
  values (new.raiser_name || ' - ' || to_char(new.investment_date, 'Mon DD, YYYY') || ' - ' || new.hog_type || ' (' || new.id::text || ')', new.investment_date)
  returning batch_id into v_batch_id;

  -- 3. Create the assignment linking raiser, batch, and type
  insert into public.assignments (assigned_date, status, hog_type_id, batch_id, hog_raiser_id)
  values (new.investment_date, 'active', v_hog_type_id, v_batch_id, (new.hog_raiser_id)::bigint)
  returning assignment_id into v_assignment_id;

  -- 4. Get the initial 'Booster' stage for this hog type if exists
  select stage_id into v_stage_id
  from public.hog_stages
  where hog_type_id = v_hog_type_id
    and lower(stage_name) = 'booster'
  limit 1;

  -- 5. Automatically insert the hogs for this batch
  for i in 1..new.total_hog loop
    insert into public.hogs (status, health_status, assignment_id, stage_id)
    values ('active', 'Healthy', v_assignment_id, v_stage_id);
  end loop;

  return new;
end;
$$ language plpgsql;

create or replace trigger trg_auto_create_batch_and_assignment
after insert on public.investment_records
for each row
execute function public.fn_auto_create_batch_and_assignment();


-- 6. Cleanup trigger on deletion
create or replace function public.fn_auto_delete_batch_and_assignment()
returns trigger as $$
declare
  v_batch_name_pattern text;
  v_batch_id bigint;
begin
  v_batch_name_pattern := '%(' || old.id::text || ')';
  
  -- Find the batch_id
  select batch_id into v_batch_id
  from public.batches
  where batch_name like v_batch_name_pattern
  limit 1;
  
  if v_batch_id is not null then
    -- Delete stage logs associated with hogs of this assignment
    delete from public.hog_stage_logs
    where hog_id in (
      select hog_id from public.hogs 
      where assignment_id in (select assignment_id from public.assignments where batch_id = v_batch_id)
    );

    -- Delete hogs associated with the assignments for this batch
    delete from public.hogs
    where assignment_id in (select assignment_id from public.assignments where batch_id = v_batch_id);
    
    -- Delete assignments for this batch
    delete from public.assignments
    where batch_id = v_batch_id;
    
    -- Delete the batch
    delete from public.batches
    where batch_id = v_batch_id;
  end if;
  
  return old;
end;
$$ language plpgsql;

create or replace trigger trg_auto_delete_batch_and_assignment
after delete on public.investment_records
for each row
execute function public.fn_auto_delete_batch_and_assignment();

commit;
