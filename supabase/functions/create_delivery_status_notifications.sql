-- ============================================================================
-- COMPREHENSIVE DELIVERY STATUS NOTIFICATIONS
-- ============================================================================
-- This trigger handles notifications for all major delivery status changes:
-- 1. accepted -> Driver is on the way to pickup
-- 2. picking_up -> Driver has arrived at pickup
-- 3. picked_up -> Driver has the item and is delivering
-- 4. delivering -> Driver is approaching destination (optional, usually skipped to completed)
-- 5. completed -> Delivery is finished
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_passenger_on_delivery_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
  v_delivery_person_name text;
  v_notification_title text;
  v_notification_body text;
  v_notification_type text;
BEGIN
  -- Only proceed if status has changed
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Get delivery person's name
    SELECT u.name INTO v_delivery_person_name
    FROM delivery_persons dp
    JOIN users u ON dp.user_id = u.id
    WHERE dp.id = NEW.delivery_person_id;

    -- Default name if missing
    IF v_delivery_person_name IS NULL THEN
      v_delivery_person_name := 'Your delivery driver';
    END IF;

    -- Determine Notification Content based on Status
    CASE NEW.status
      WHEN 'accepted' THEN
        v_notification_title := '✅ Delivery Request Accepted!';
        v_notification_body := v_delivery_person_name || ' accepted your request and is coming to pick up the item.';
        v_notification_type := 'delivery_accepted';

      WHEN 'picking_up' THEN
         -- Optional: 'picking_up' might be set when driver starts heading to pickup. 
         -- If 'accepted' already notifies, we might skip this unless distinct.
         -- For now, let's treat it as "Driver Arrived at Pickup" or "Started Pickup process".
         -- ACTUALLY, usually 'picking_up' = "I am at location, picking up".
         v_notification_title := '📦 Driver at Pickup Location';
         v_notification_body := v_delivery_person_name || ' has arrived at the pickup point.';
         v_notification_type := 'delivery_picking_up';

      WHEN 'picked_up' THEN
        v_notification_title := '🚚 Item Picked Up!';
        v_notification_body := v_delivery_person_name || ' has picked up the item and is on the way to the destination.';
        v_notification_type := 'delivery_picked_up';

      WHEN 'delivering' THEN
         -- Often used when driver is approaching or specifically sets "I am delivering now".
         v_notification_title := '📍 Driver Arriving Soon';
         v_notification_body := v_delivery_person_name || ' is approaching the delivery location.';
         v_notification_type := 'delivery_delivering';

      WHEN 'completed' THEN
        v_notification_title := '🎉 Delivery Completed!';
        v_notification_body := 'Your delivery has been completed successfully. Thank you for using Drivio!';
        v_notification_type := 'delivery_completed';

      ELSE
        -- Ignore other status changes (e.g., cancelled, pending, price_negotiation)
        RETURN NEW;
    END CASE;

    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      v_notification_title,
      v_notification_body,
      jsonb_build_object(
        'type', v_notification_type,
        'delivery_request_id', NEW.id,
        'delivery_person_id', NEW.delivery_person_id,
        'category', NEW.category,
        'status', NEW.status
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing triggers to avoid duplicates
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_delivery_accepted ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_passenger_on_delivery_status_change ON delivery_requests;

-- Create the new comprehensive trigger
CREATE TRIGGER trigger_notify_passenger_on_delivery_status_change
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_delivery_status_change();
