-- ============================================================================
-- DELIVERY REQUEST NOTIFICATION TRIGGER
-- ============================================================================
-- This trigger automatically notifies passengers when their delivery request
-- is accepted by a delivery person.
-- ============================================================================

-- ============================================================================
-- DELIVERY ACCEPTED NOTIFICATION
-- ============================================================================
-- Notifies passenger when a delivery person accepts their delivery request

CREATE OR REPLACE FUNCTION notify_passenger_on_delivery_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
  v_delivery_person_name text;
BEGIN
  -- Only proceed if status changed to 'accepted'
  IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Get delivery person's name (optional, for personalized notification)
    SELECT u.name INTO v_delivery_person_name
    FROM delivery_persons dp
    JOIN users u ON dp.user_id = u.id
    WHERE dp.id = NEW.delivery_person_id;
    
    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      '✅ Delivery Accepted!',
      COALESCE(v_delivery_person_name || ' has accepted your delivery request and will pick up your item soon!', 'A delivery person has accepted your delivery request!'),
      jsonb_build_object(
        'type', 'delivery_accepted',
        'delivery_request_id', NEW.id,
        'delivery_person_id', NEW.delivery_person_id,
        'category', NEW.category
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_delivery_accepted ON delivery_requests;

-- Create the trigger
CREATE TRIGGER trigger_notify_passenger_on_delivery_accepted
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_delivery_accepted();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify the trigger is created:
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE event_object_table = 'delivery_requests'
-- ORDER BY trigger_name;
