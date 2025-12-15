-- Trigger Function: Auto-track ride distance to car expenses
-- When a ride is completed, automatically create a fuel expense record with the distance

CREATE OR REPLACE FUNCTION auto_track_ride_distance()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if the ride has a driver assigned
  IF NEW.driver_id IS NOT NULL THEN
    -- Insert a fuel expense record with the ride distance
    INSERT INTO car_expenses (
      driver_id,
      expense_type,
      amount,
      description,
      expense_date,
      distance_km,
      fuel_liters,
      odometer_reading
    ) VALUES (
      NEW.driver_id,
      'fuel',
      0.00,
      'Auto-tracked from ride #' || NEW.id,
      CURRENT_DATE,
      NEW.distance,  -- Copy distance from ride_requests
      NULL,
      NULL
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires when a ride status changes to 'completed'
DROP TRIGGER IF EXISTS trigger_auto_track_ride_distance ON ride_requests;

CREATE TRIGGER trigger_auto_track_ride_distance
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed')
  EXECUTE FUNCTION auto_track_ride_distance();

-- Comment on function
COMMENT ON FUNCTION auto_track_ride_distance() IS 'Automatically creates a fuel expense record when a ride is completed, tracking the distance driven';
