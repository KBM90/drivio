-- Trigger Function: Create ride_details when ride_request is completed
-- Automatically populates ride_details table with data from completed ride_requests

CREATE OR REPLACE FUNCTION create_ride_details_on_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if the ride status changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Insert a new ride_details record
    INSERT INTO ride_details (
      passenger_id,
      driver_id,
      price,
      distance,
      created_at,
      updated_at
    ) VALUES (
      NEW.passenger_id,
      NEW.driver_id,
      NEW.price,
      NEW.distance,  -- Use 'distance' field from ride_requests
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires when a ride_request status changes to 'completed'
DROP TRIGGER IF EXISTS trigger_create_ride_details_on_completion ON ride_requests;

CREATE TRIGGER trigger_create_ride_details_on_completion
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  WHEN (NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed'))
  EXECUTE FUNCTION create_ride_details_on_completion();

-- Comment on function
COMMENT ON FUNCTION create_ride_details_on_completion() IS 'Automatically creates a ride_details record when a ride_request is completed';

-- Test the trigger (optional - comment out if not needed)
-- This will show you what happens when a ride is marked as completed
/*
-- First, check existing ride_requests
SELECT id, passenger_id, driver_id, status, price, distance 
FROM ride_requests 
WHERE status != 'completed' 
LIMIT 1;

-- Update a ride to completed (replace ID with actual ID from above query)
-- UPDATE ride_requests 
-- SET status = 'completed' 
-- WHERE id = YOUR_RIDE_ID;

-- Check if ride_details was created
-- SELECT * FROM ride_details ORDER BY created_at DESC LIMIT 1;
*/
