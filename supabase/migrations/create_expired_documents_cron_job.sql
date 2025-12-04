-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Function to update expired status for all documents
CREATE OR REPLACE FUNCTION update_expired_documents()
RETURNS void AS $$
BEGIN
  -- Update is_expired for vehicle_documents
  UPDATE vehicle_documents 
  SET is_expired = (expiring_date < CURRENT_DATE)
  WHERE is_expired != (expiring_date < CURRENT_DATE); -- Only update if value changed
  
  RAISE NOTICE 'Updated expired status for vehicle documents';
END;
$$ LANGUAGE plpgsql;

-- Schedule the job to run daily at 1:00 AM
SELECT cron.schedule(
  'update-expired-documents-daily',  -- Job name
  '0 1 * * *',                        -- Cron expression: At 1:00 AM every day
  $$SELECT update_expired_documents()$$
);

-- Add comment
COMMENT ON FUNCTION update_expired_documents() IS 'Updates is_expired field for vehicle_documents based on expiring_date. Runs daily via pg_cron.';

-- To manually run the function (for testing):
-- SELECT update_expired_documents();

-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- To unschedule the job (if needed):
-- SELECT cron.unschedule('update-expired-documents-daily');
