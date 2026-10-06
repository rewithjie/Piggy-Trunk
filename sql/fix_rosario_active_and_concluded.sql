-- ==============================================================================
-- 1. FIX THE TRIGGER FUNCTION auto_activate_on_investment
-- Resolves "operator does not exist: bigint = text" by safely casting batch_id
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.auto_activate_on_investment()
RETURNS trigger AS $$
BEGIN
  IF new.batch_id IS NOT NULL AND trim(new.batch_id::text) != '' THEN
    BEGIN
      UPDATE public.batches 
      SET status = 'Active' 
      WHERE batch_id = (new.batch_id)::bigint;
    EXCEPTION WHEN others THEN
      NULL;
    END;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 2. FIX ROSARIO BATCH STATE: ARCHIVED CONCLUDED CYCLE + ACTIVE FATTENING CYCLE
-- ==============================================================================
DO $$
DECLARE
  v_raiser_id bigint;
  v_batch_id bigint;
  v_fatten_type_id bigint;
  v_assignment_id bigint;
BEGIN
  -- 1. Resolve Rosario's ID
  SELECT hog_raiser_id INTO v_raiser_id
  FROM public.hog_raisers
  WHERE name ILIKE '%Rosario%'
  LIMIT 1;

  IF v_raiser_id IS NULL THEN
    v_raiser_id := 45;
  END IF;

  -- 2. Mark previous Sow assignments and hogs as COMPLETED
  UPDATE public.assignments
  SET status = 'completed'
  WHERE hog_raiser_id = v_raiser_id;

  UPDATE public.hogs
  SET status = 'completed',
      stage_id = 6
  WHERE assignment_id IN (
    SELECT assignment_id FROM public.assignments WHERE hog_raiser_id = v_raiser_id
  );

  -- 3. Get Fattening hog_type_id
  SELECT hog_type_id INTO v_fatten_type_id
  FROM public.hog_types
  WHERE type_name ILIKE '%fatten%'
  LIMIT 1;

  IF v_fatten_type_id IS NULL THEN
    v_fatten_type_id := 1;
  END IF;

  -- 4. Create or reuse fresh batch (date_created, NOT created_at)
  SELECT batch_id INTO v_batch_id
  FROM public.batches
  WHERE batch_name = 'Batch 2 - Rosario (Fattening)'
  LIMIT 1;

  IF v_batch_id IS NULL THEN
    INSERT INTO public.batches (batch_name, status)
    VALUES ('Batch 2 - Rosario (Fattening)', 'Active')
    RETURNING batch_id INTO v_batch_id;
  ELSE
    UPDATE public.batches
    SET status = 'Active'
    WHERE batch_id = v_batch_id;
  END IF;

  -- 5. Link Rosario to new batch in assignments table
  SELECT assignment_id INTO v_assignment_id
  FROM public.assignments
  WHERE batch_id = v_batch_id AND hog_raiser_id = v_raiser_id
  LIMIT 1;

  IF v_assignment_id IS NULL THEN
    INSERT INTO public.assignments (batch_id, hog_raiser_id, status, hog_type_id, assigned_date)
    VALUES (v_batch_id, v_raiser_id, 'active', v_fatten_type_id, current_date)
    RETURNING assignment_id INTO v_assignment_id;
  ELSE
    UPDATE public.assignments
    SET status = 'active', hog_type_id = v_fatten_type_id
    WHERE assignment_id = v_assignment_id;
  END IF;

  -- 6. Insert 2 fresh active hogs in Booster stage (stage_id = 1)
  DELETE FROM public.hogs WHERE assignment_id = v_assignment_id;

  INSERT INTO public.hogs (assignment_id, status, health_status, stage_id, last_updated)
  VALUES 
    (v_assignment_id, 'active', 'healthy', 1, now()),
    (v_assignment_id, 'active', 'healthy', 1, now());

  -- 7. Add investment record (₱5,000 for 2 Fattening hogs)
  DELETE FROM public.investment_records
  WHERE hog_raiser_id = v_raiser_id::text
    AND batch_name ILIKE '%Batch 2 - Rosario%';

  INSERT INTO public.investment_records (
    hog_raiser_id,
    raiser_name,
    initial_capital,
    hog_type,
    total_hog,
    investment_date,
    stage,
    batch_id,
    batch_name
  ) VALUES (
    v_raiser_id::text,
    'Rosario, Mark Rejie J.',
    5000.00,
    'Fattening',
    2,
    current_date,
    'active',
    v_batch_id::text,
    'Batch 2 - Rosario (Fattening)'
  );

  -- 8. Update Rosario's profile to Active, Fattening, Booster
  UPDATE public.hog_raisers
  SET pig_type = 'Fattening',
      lifecycle_stage = 'Booster',
      status = 'Active',
      account_status = 'active'
  WHERE hog_raiser_id = v_raiser_id;

END $$;
