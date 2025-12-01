-- Step 1: Enable pg_cron extension (run this once)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Step 2: Schedule the cleanup function to run every 5 minutes
SELECT cron.schedule(
  'cleanup-inactive-drivers',
  '*/5 * * * *',  -- Every 5 minutes
  $$SELECT cleanup_inactive_drivers()$$
);

-- Step 3: Verify the job was scheduled
SELECT * FROM cron.job;

-- Optional: To unschedule the job
-- SELECT cron.unschedule('cleanup-inactive-drivers');

-- Optional: To view job run history
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
