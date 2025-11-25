-- Function to accept a ride request by driver
-- This function runs with SECURITY DEFINER to bypass RLS policies
DROP FUNCTION IF EXISTS accept_ride_by_driver(bigint, bigint, text);

CREATE OR REPLACE FUNCTION accept_ride_by_driver(
  p_ride_request_id bigint,
  p_driver_id bigint,
  p_driver_location text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ride_request record;
BEGIN
  -- Get the ride request and verify it's available
  SELECT * INTO v_ride_request
  FROM ride_requests
  WHERE id = p_ride_request_id
    AND driver_id IS NULL
    AND (status = 'pending' OR status = 'cancelled_by_driver');
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ride request not found or already assigned';
  END IF;
  
  -- Update ride request: assign driver and set status to accepted
  UPDATE ride_requests
  SET 
    driver_id = p_driver_id,
    status = 'accepted',
    updated_at = NOW()
  WHERE id = p_ride_request_id;
  
  -- Update driver: set location, status to on_trip, and disable new requests
  UPDATE drivers
  SET 
    location = p_driver_location::geometry,
    status = 'on_trip',
    acceptnewrequest = false,
    updated_at = NOW()
  WHERE id = p_driver_id;
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'message', 'Ride request accepted successfully',
    'ride_request_id', p_ride_request_id
  );
END;
$$;
