-- Function to update driving_distance for driver and passenger when a ride is completed
CREATE OR REPLACE FUNCTION update_driving_distance_on_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if status changed TO 'completed' (not already completed)
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Update driver's driving_distance (if driver exists)
    IF NEW.driver_id IS NOT NULL THEN
      UPDATE drivers
      SET driving_distance = COALESCE(driving_distance, 0) + NEW.distance
      WHERE id = NEW.driver_id;
    END IF;
    
    -- Update passenger's driving_distance
    UPDATE passengers
    SET driving_distance = COALESCE(driving_distance, 0) + NEW.distance
    WHERE id = NEW.passenger_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_driving_distance ON ride_requests;

-- Create trigger to execute the function after ride_requests update
CREATE TRIGGER trigger_update_driving_distance
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_driving_distance_on_completion();

-- Add comment for documentation
COMMENT ON FUNCTION update_driving_distance_on_completion() IS 
  'Automatically accumulates ride distance into driver and passenger driving_distance when a ride is marked as completed';
