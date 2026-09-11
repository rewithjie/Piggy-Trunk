-- Create trigger to notify admin on new hog reports/activities
create or replace function public.notify_admin_on_hog_report()
returns trigger as $$
declare
  raiser_name text;
begin
  -- Fetch the raiser's name
  select name into raiser_name 
  from public.hog_raisers 
  where hog_raiser_id = new.hog_raiser_id;

  -- Insert a real-time notification for the admin
  insert into public.admin_notifications (title, message, type, metadata)
  values (
    'Hog Health Alert',
    coalesce(raiser_name, 'A hog raiser') || ' has reported: ' || new.report_type || '.',
    'hog_report',
    jsonb_build_object(
      'report_id', new.report_id,
      'hog_id', new.hog_id,
      'hog_raiser_id', new.hog_raiser_id,
      'raiser_name', raiser_name,
      'report_type', new.report_type,
      'description', new.description
    )
  );
  return new;
end;
$$ language plpgsql;

-- Apply the trigger to hog_reports table
drop trigger if exists trigger_on_hog_report_insert on public.hog_reports;
create trigger trigger_on_hog_report_insert
after insert on public.hog_reports
for each row execute function public.notify_admin_on_hog_report();
