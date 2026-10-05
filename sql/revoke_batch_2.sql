-- ==============================================================================
-- REVOKE BATCH 2 - ROSARIO (FATTENING)
-- Deletes the unwanted batch and all its linked records
-- ==============================================================================

DO $$
DECLARE
  v_batch_id bigint;
BEGIN
  -- 1. Find the batch ID
  SELECT batch_id INTO v_batch_id
  FROM public.batches
  WHERE batch_name ILIKE '%Batch 2 - Rosario%'
  LIMIT 1;

  IF v_batch_id IS NOT NULL THEN
    -- Delete hogs linked to Batch 2
    DELETE FROM public.hogs
    WHERE assignment_id IN (
      SELECT assignment_id FROM public.assignments WHERE batch_id = v_batch_id
    );

    -- Delete assignments linked to Batch 2
    DELETE FROM public.assignments
    WHERE batch_id = v_batch_id;

    -- Delete investment record for Batch 2
    DELETE FROM public.investment_records
    WHERE batch_id = v_batch_id::text
       OR batch_name ILIKE '%Batch 2 - Rosario%';

    -- Delete the batch from batches table
    DELETE FROM public.batches
    WHERE batch_id = v_batch_id;
  END IF;
END $$;
