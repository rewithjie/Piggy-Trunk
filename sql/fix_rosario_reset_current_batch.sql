-- ==============================================================================
-- OPTION B: RESET CURRENT BATCH TO FATTENING & BOOSTER (SINGLE ACTIVE BATCH)
-- ==============================================================================

-- 1. Update assignment to Fattening and active status
UPDATE public.assignments
SET hog_type_id = (SELECT hog_type_id FROM public.hog_types WHERE type_name ILIKE '%fatten%' LIMIT 1),
    status = 'active'
WHERE hog_raiser_id = 45;

-- 2. Reset the 2 hogs to Booster stage (stage_id = 1)
UPDATE public.hogs
SET stage_id = 1,
    status = 'active',
    health_status = 'healthy',
    last_updated = now()
WHERE assignment_id IN (
  SELECT assignment_id FROM public.assignments WHERE hog_raiser_id = 45
);

-- 3. Update investment record to ₱5,000 Fattening
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
  '45',
  'Rosario, Mark Rejie J.',
  5000.00,
  'Fattening',
  2,
  current_date,
  'active',
  (SELECT batch_id::text FROM public.assignments WHERE hog_raiser_id = 45 LIMIT 1),
  'Batch Test Rejiee'
);

-- 4. Update Rosario's profile to Fattening & Booster
UPDATE public.hog_raisers
SET pig_type = 'Fattening',
    lifecycle_stage = 'Booster',
    status = 'Active',
    account_status = 'active'
WHERE hog_raiser_id = 45;
