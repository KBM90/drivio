-- ============================================================================
-- CAR RENTAL BOOKING NOTIFICATION TRIGGER
-- ============================================================================
-- This file contains the trigger for automatically notifying car renters
-- when a new booking/rental request is created for their cars.
-- Run this file in your Supabase SQL editor.
-- ============================================================================

-- ============================================================================
-- 1. NEW CAR RENTAL BOOKING NOTIFICATION
-- ============================================================================
-- Notifies car renter when a user books one of their cars

CREATE OR REPLACE FUNCTION notify_car_renter_on_new_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_car_renter_user_id bigint;
  v_renter_name text;
  v_car_brand_name text;
  v_user_name text;
BEGIN
  -- Get car renter's user_id by joining through provided_car_rentals -> car_renters
  SELECT cr.user_id, u.name
  INTO v_car_renter_user_id, v_renter_name
  FROM provided_car_rentals pcr
  JOIN car_renters cr ON pcr.car_renter_id = cr.id
  JOIN users u ON cr.user_id = u.id
  WHERE pcr.id = NEW.car_rental_id;
  
  -- Get car brand name for the notification
  SELECT CONCAT(cb.company, ' ', cb.model)
  INTO v_car_brand_name
  FROM provided_car_rentals pcr
  JOIN car_brands cb ON pcr.car_brand_id = cb.id
  WHERE pcr.id = NEW.car_rental_id;
  
  -- Get the user's name who made the booking
  SELECT u.name
  INTO v_user_name
  FROM users u
  WHERE u.id = NEW.user_id;
  
  -- Insert notification for the car renter
  INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
  VALUES (
    v_car_renter_user_id,
    '🚗 New Car Rental Booking!',
    COALESCE(
      v_user_name || ' has booked your ' || v_car_brand_name || ' from ' || 
      TO_CHAR(NEW.start_date, 'Mon DD') || ' to ' || TO_CHAR(NEW.end_date, 'Mon DD, YYYY'),
      'You have a new car rental booking!'
    ),
    jsonb_build_object(
      'type', 'car_rental_booking',
      'car_rental_request_id', NEW.id,
      'car_rental_id', NEW.car_rental_id,
      'user_id', NEW.user_id,
      'start_date', NEW.start_date,
      'end_date', NEW.end_date,
      'total_price', NEW.total_price
    ),
    false,
    NOW()
  );
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_car_renter_on_new_booking ON car_rental_requests;

CREATE TRIGGER trigger_notify_car_renter_on_new_booking
  AFTER INSERT ON car_rental_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_car_renter_on_new_booking();


-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify the trigger is created:
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE event_object_table = 'car_rental_requests'
-- ORDER BY trigger_name;
