-- Trigger function to notify passenger when trip is completed
-- This function automatically sends a notification to the passenger
-- when the driver completes the trip

CREATE OR REPLACE FUNCTION notify_passenger_on_trip_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
BEGIN
  -- Only proceed if status changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      '🎉 Trip Completed!',
      'Your trip has been completed. Thank you for riding with us!',
      jsonb_build_object(
        'type', 'trip_completed',
        'ride_request_id', NEW.id,
        'driver_id', NEW.driver_id,
        'price', NEW.price
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_trip_completed ON ride_requests;

-- Create trigger that fires after ride_requests update
CREATE TRIGGER trigger_notify_passenger_on_trip_completed
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_trip_completed();
