-- ============================================================================
-- AUTOMATIC DISTANCE CALCULATION TRIGGER
-- ============================================================================
-- This trigger automatically calculates the distance_km for delivery requests
-- based on pickup and delivery locations.
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_delivery_requests_distance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- If pickup_location is NULL, distance is 0 (as per requirements)
  -- Or strictly speaking, if there is no pickup, the request distance *itself* is 0
  -- because the "job" starts at the delivery location regarding the item logic?
  -- The user requirement: "if the pickup_location is null it will equal to zero"
  
  IF NEW.pickup_location IS NULL OR NEW.delivery_location IS NULL THEN
    NEW.distance_km := 0;
  ELSE
    -- Calculate distance in meters using PostGIS ST_Distance
    -- Cast geography to geometry if needed, but ST_Distance works on geography usually returns meters
    -- We divide by 1000 to get Kilometers
    NEW.distance_km := ROUND((ST_Distance(NEW.pickup_location, NEW.delivery_location) / 1000)::numeric, 2);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_calculate_delivery_distance ON delivery_requests;

-- Create the trigger
CREATE TRIGGER trigger_calculate_delivery_distance
  BEFORE INSERT OR UPDATE OF pickup_location, delivery_location
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION calculate_delivery_requests_distance();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Test by inserting a row with NULL distance_km
-- INSERT INTO delivery_requests (passenger_id, category, pickup_location, delivery_location)
-- VALUES (..., ..., 'POINT(...)', 'POINT(...)');
-- Check if distance_km is populated.
