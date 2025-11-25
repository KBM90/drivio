
DECLARE
  driver_record RECORD;
  pickup_point geography;
  driver_range_meters numeric;
BEGIN
  -- Convert pickup location to geography for distance calculations
  pickup_point := NEW.pickup_location::geography;
  
  -- Find all drivers within their individual range preference
  FOR driver_record IN
    SELECT 
      d.user_id, 
      d.id,
      d.range,
      d.status,
      d.acceptnewrequest
    FROM drivers d
    WHERE d.location IS NOT NULL
      AND d.range IS NOT NULL
      AND ST_DWithin(
        d.location::geography,
        pickup_point,
        (d.range * 1000)::numeric  -- Convert km to meters
      )
  LOOP
    -- Calculate range in meters for this driver
    driver_range_meters := driver_record.range * 1000;
    
    -- Create notification for each nearby driver
    INSERT INTO notifications (user_id, title, body, data, is_read)
    VALUES (
      driver_record.user_id,
      'New Ride Request',
      'A passenger needs a ride nearby!',
      jsonb_build_object(
        'ride_request_id', NEW.id,
        'pickup_lat', ST_Y(NEW.pickup_location::geometry),
        'pickup_lng', ST_X(NEW.pickup_location::geometry),
        'dropoff_lat', ST_Y(NEW.dropoff_location::geometry),
        'dropoff_lng', ST_X(NEW.dropoff_location::geometry),
        'price', NEW.price,
        'distance', NEW.distance,
        'transport_type_id', NEW.transport_type_id,
        'driver_status', driver_record.status,
        'driver_range_km', driver_record.range,
        'accept_new_request', driver_record.acceptnewrequest
      ),
      false
    );
    
    -- Log for debugging (optional)
    RAISE NOTICE 'Notified driver % (status: %, range: % km) about ride request %', 
      driver_record.user_id, 
      driver_record.status,
      driver_record.range,
      NEW.id;
  END LOOP;
  
  RETURN NEW;
END;
