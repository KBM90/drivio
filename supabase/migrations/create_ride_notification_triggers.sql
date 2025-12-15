-- ============================================================================
-- RIDE REQUEST NOTIFICATION TRIGGERS
-- ============================================================================
-- This file contains all triggers for automatically notifying passengers
-- about ride status changes. Run this file in your Supabase SQL editor.
-- ============================================================================

-- ============================================================================
-- 1. RIDE ACCEPTED NOTIFICATION
-- ============================================================================
-- Notifies passenger when a driver accepts their ride request

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

DROP TRIGGER IF EXISTS trigger_notify_passenger_on_ride_accepted ON ride_requests;

CREATE TRIGGER trigger_notify_passenger_on_ride_accepted
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_ride_accepted();


-- ============================================================================
-- 3. TRIP COMPLETED NOTIFICATION
-- ============================================================================
-- Notifies passenger when the trip is completed

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

DROP TRIGGER IF EXISTS trigger_notify_passenger_on_trip_completed ON ride_requests;

CREATE TRIGGER trigger_notify_passenger_on_trip_completed
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_trip_completed();


-- ============================================================================
-- 4. RIDE CANCELLED NOTIFICATION
-- ============================================================================
-- Notifies passenger when the driver cancels the ride

CREATE OR REPLACE FUNCTION notify_passenger_on_ride_cancelled()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
BEGIN
  -- Only proceed if status changed to 'cancelled_by_driver'
  IF NEW.status = 'cancelled_by_driver' AND (OLD.status IS NULL OR OLD.status != 'cancelled_by_driver') THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      '❌ Ride Cancelled',
      'Your driver has cancelled the ride. Please request a new ride.',
      jsonb_build_object(
        'type', 'ride_cancelled',
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

DROP TRIGGER IF EXISTS trigger_notify_passenger_on_ride_cancelled ON ride_requests;

CREATE TRIGGER trigger_notify_passenger_on_ride_cancelled
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_ride_cancelled();


-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify all triggers are created:
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE event_object_table = 'ride_requests'
-- ORDER BY trigger_name;
