-- Drop all conflicting versions of the function to resolve PGRST203 error
DROP FUNCTION IF EXISTS get_nearby_pending_rides(geometry, numeric);
DROP FUNCTION IF EXISTS get_nearby_pending_rides(text, double precision);
DROP FUNCTION IF EXISTS get_nearby_pending_rides(text, numeric);
DROP FUNCTION IF EXISTS get_nearby_pending_rides(text, double precision, bigint);
DROP FUNCTION IF EXISTS get_nearby_pending_rides(text, bigint);
DROP FUNCTION IF EXISTS get_nearby_pending_rides(text, bigint, double precision);

-- Re-create the correct version with complete data
CREATE OR REPLACE FUNCTION get_nearby_pending_rides(
  driver_location text,
  p_driver_id bigint DEFAULT NULL,
  max_distance_km double precision DEFAULT 10
)
RETURNS TABLE (
  id bigint,
  passenger_id bigint,
  driver_id bigint,
  transport_type_id bigint,
  payment_method_id bigint,
  status character varying,
  price numeric,
  pickup_location jsonb,
  destination_location jsonb,
  preferences jsonb,
  distance_km numeric,
  estimated_time_min numeric,
  requested_at timestamp with time zone,
  accepted_at timestamp with time zone,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  qr_code character varying,
  qr_code_scanned boolean,
  cancellation_reason text,
  distance_from_driver double precision,
  passenger jsonb,
  driver jsonb,
  transport_type jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  search_radius double precision;
BEGIN
  -- Get driver's range preference if p_driver_id is provided, otherwise use default
  IF p_driver_id IS NOT NULL THEN
    SELECT COALESCE(d.range, max_distance_km)
    INTO search_radius
    FROM drivers d
    WHERE d.id = p_driver_id;
    
    -- If driver not found, use default
    IF search_radius IS NULL THEN
      search_radius := max_distance_km;
    END IF;
  ELSE
    search_radius := max_distance_km;
  END IF;

  RETURN QUERY
  SELECT 
    r.id,
    r.passenger_id,
    r.driver_id,
    r.transport_type_id,
    r.payment_method_id,
    r.status,
    r.price,
    ST_AsGeoJSON(r.pickup_location)::jsonb as pickup_location,
    ST_AsGeoJSON(r.dropoff_location)::jsonb as destination_location,
    r.preferences,
    r.distance as distance_km,
    r.duration as estimated_time_min,
    r.requested_at,
    r.accepted_at,
    r.created_at,
    r.updated_at,
    r.qr_code,
    r.qr_code_scanned,
    r.cancellation_reason,
    ST_Distance(r.pickup_location::geography, driver_location::geography) / 1000 as distance_from_driver,
    -- Passenger data as JSONB
    jsonb_build_object(
      'id', p.id,
      'user_id', p.user_id,
      'created_at', p.created_at,
      'updated_at', p.updated_at,
      'user', jsonb_build_object(
        'id', pu.id,
        'user_id', pu.user_id,
        'name', pu.name,
        'email', pu.email,
        'phone', pu.phone,
        'role', pu.role,
        'created_at', pu.created_at,
        'updated_at', pu.updated_at
      )
    ) as passenger,
    -- Driver data as JSONB (will be null for pending/cancelled rides)
    CASE 
      WHEN r.driver_id IS NOT NULL THEN
        jsonb_build_object(
          'id', d.id,
          'user_id', d.user_id,
          'location', ST_AsGeoJSON(d.location)::jsonb,
          'dropoff_location', ST_AsGeoJSON(d.dropoff_location)::jsonb,
          'preferences', d.preferences,
          'driving_distance', d.driving_distance,
          'status', d.status,
          'acceptnewrequest', d.acceptnewrequest,
          'range', d.range,
          'created_at', d.created_at,
          'updated_at', d.updated_at,
          'user', jsonb_build_object(
            'id', du.id,
            'user_id', du.user_id,
            'name', du.name,
            'email', du.email,
            'phone', du.phone,
            'role', du.role,
            'created_at', du.created_at,
            'updated_at', du.updated_at
          )
        )
      ELSE NULL
    END as driver,
    -- Transport type data as JSONB
    jsonb_build_object(
      'id', tt.id,
      'name', tt.name,
      'description', tt.description,
      'created_at', tt.created_at,
      'updated_at', tt.updated_at
    ) as transport_type
  FROM ride_requests r
  INNER JOIN passengers p ON r.passenger_id = p.id
  INNER JOIN users pu ON p.user_id = pu.id
  LEFT JOIN drivers d ON r.driver_id = d.id
  LEFT JOIN users du ON d.user_id = du.id
  INNER JOIN transport_types tt ON r.transport_type_id = tt.id
  WHERE 
    (r.status = 'pending' OR r.status = 'cancelled_by_driver')
    AND r.driver_id IS NULL
    AND ST_DWithin(
      r.pickup_location::geography, 
      driver_location::geography, 
      search_radius * 1000
    )
  ORDER BY distance_from_driver ASC;
END;
$$;
