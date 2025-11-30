-- Migration to create cleanup function for inactive drivers
-- This function automatically sets drivers to 'inactive' if they haven't updated their location
-- in the last 10 minutes, and closes their open sessions.

-- Function to cleanup inactive drivers
create or replace function cleanup_inactive_drivers()
returns void as $$
declare
  v_inactive_threshold interval := interval '10 minutes';
  v_affected_count integer;
begin
  -- Update drivers who are 'active' but haven't updated in the threshold period
  -- Also close their open sessions
  with inactive_drivers as (
    update drivers
    set status = 'inactive'
    where status = 'active'
      and updated_at < (now() - v_inactive_threshold)
    returning id
  ),
  closed_sessions as (
    update driver_online_sessions
    set session_end = now()
    where driver_id in (select id from inactive_drivers)
      and session_end is null
    returning id
  )
  select count(*) into v_affected_count from inactive_drivers;

  -- Log the cleanup action
  raise notice 'Cleaned up % inactive drivers', v_affected_count;
end;
$$ language plpgsql;

-- Example: To schedule this function to run every 5 minutes using pg_cron:
-- (Uncomment and run the following lines if you have pg_cron extension enabled)
--
-- SELECT cron.schedule(
--   'cleanup-inactive-drivers',
--   '*/5 * * * *',  -- Every 5 minutes
--   $$SELECT cleanup_inactive_drivers()$$
-- );
--
-- To unschedule:
-- SELECT cron.unschedule('cleanup-inactive-drivers');
--
-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- Manual execution (for testing):
-- SELECT cleanup_inactive_drivers();
