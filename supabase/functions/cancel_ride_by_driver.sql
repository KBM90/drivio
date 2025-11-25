-- Function to cancel a ride request by driver
-- This function runs with SECURITY DEFINER to bypass RLS policies
DROP FUNCTION IF EXISTS cancel_ride_by_driver(bigint, bigint, text);

CREATE OR REPLACE FUNCTION cancel_ride_by_driver(
  p_ride_request_id bigint,
  p_driver_id bigint,
  p_reason text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ride_request record;
  v_user_id bigint;
BEGIN
  -- Get the ride request and verify it belongs to this driver
  SELECT * INTO v_ride_request
  FROM ride_requests
  WHERE id = p_ride_request_id
    AND driver_id = p_driver_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride request not found or does not belong to this driver';
  END IF;
  
  -- Get the user_id for the driver
  SELECT user_id INTO v_user_id
  FROM drivers
  WHERE id = p_driver_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Driver not found';
  END IF;
  
  -- Insert cancellation record
  INSERT INTO cancelled_ride_requests (
    ride_request_id,
    user_id,
    user_type,
    reason
  ) VALUES (
    p_ride_request_id,
    v_user_id,
    'driver',
    p_reason
  );
  
  -- Update ride request: set status and clear driver_id
  UPDATE ride_requests
  SET 
    status = 'cancelled_by_driver',
    driver_id = NULL,
    updated_at = NOW()
  WHERE id = p_ride_request_id;
  
  -- Update driver status back to active
  UPDATE drivers
  SET 
    status = 'active',
    acceptnewrequest = true,
    updated_at = NOW()
  WHERE id = p_driver_id;
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'message', 'Trip cancelled successfully',
    'ride_request_id', p_ride_request_id
  );
END;
$$;
