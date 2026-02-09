-- ============================================================================
-- NOTIFY DELIVERY PERSONS ON NEW DELIVERY REQUEST
-- ============================================================================
-- This trigger automatically notifies available delivery persons within range
-- when a new delivery request is created.
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_delivery_persons_on_new_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_delivery_person RECORD;
  v_passenger_name text;
  v_distance_km numeric;
BEGIN
  -- Only proceed if this is a new pending request
  IF NEW.status = 'pending' THEN
    
    -- Get passenger's name for personalized notification
    SELECT u.name INTO v_passenger_name
    FROM passengers p
    JOIN users u ON p.user_id = u.id
    WHERE p.id = NEW.passenger_id;
    
    -- Find all available delivery persons within range
    FOR v_delivery_person IN
      SELECT 
        dp.id,
        dp.user_id,
        dp.range,
        ST_Distance(
          dp.current_location::geography,
          COALESCE(NEW.pickup_location, NEW.delivery_location)
        ) / 1000 AS distance_km
      FROM delivery_persons dp
      WHERE dp.is_available = true
        AND dp.current_location IS NOT NULL
        AND (NEW.pickup_location IS NOT NULL OR NEW.delivery_location IS NOT NULL)
        AND ST_Distance(
          dp.current_location::geography,
          COALESCE(NEW.pickup_location, NEW.delivery_location)
        ) / 1000 <= COALESCE(dp.range, 10) -- Default 10km if range is null
    LOOP
      -- Insert notification for each eligible delivery person
      INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
      VALUES (
        v_delivery_person.user_id,
        '📦 New Delivery Request!',
        COALESCE(
          v_passenger_name || ' needs a delivery (' || NEW.category || ') - $' || NEW.price::text || ' • ' || ROUND(v_delivery_person.distance_km::numeric, 1)::text || ' km away',
          'New delivery request available in your area!'
        ),
        jsonb_build_object(
          'type', 'new_delivery_request',
          'delivery_request_id', NEW.id,
          'passenger_id', NEW.passenger_id,
          'category', NEW.category,
          'price', NEW.price,
          'distance_km', ROUND(v_delivery_person.distance_km::numeric, 2)
        ),
        false,
        NOW()
      );
      
      RAISE NOTICE 'Notified delivery person % (user_id: %) about request %', 
        v_delivery_person.id, v_delivery_person.user_id, NEW.id;
    END LOOP;
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_delivery_persons_on_new_request ON delivery_requests;

-- Create the trigger
CREATE TRIGGER trigger_notify_delivery_persons_on_new_request
  AFTER INSERT ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_delivery_persons_on_new_request();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify the trigger is created:
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE event_object_table = 'delivery_requests'
-- ORDER BY trigger_name;
