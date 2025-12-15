-- Trigger function to notify passenger when ride is accepted
-- This function automatically sends a notification to the passenger
-- when a driver accepts their ride request

CREATE OR REPLACE FUNCTION notify_passenger_on_ride_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
  v_driver_name text;
BEGIN
  -- Only proceed if status changed to 'accepted'
  IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Get driver's name (optional, for personalized notification)
    SELECT u.name INTO v_driver_name
    FROM drivers d
    JOIN users u ON d.user_id = u.id
    WHERE d.id = NEW.driver_id;
    
    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      '✅ Ride Accepted!',
      COALESCE(v_driver_name || ' has accepted your ride request and is on the way!', 'A driver has accepted your ride request and is on the way!'),
      jsonb_build_object(
        'type', 'ride_accepted',
        'ride_request_id', NEW.id,
        'driver_id', NEW.driver_id
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_ride_accepted ON ride_requests;

-- Create trigger that fires after ride_requests update
CREATE TRIGGER trigger_notify_passenger_on_ride_accepted
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_ride_accepted();
