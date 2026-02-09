-- Drop all conflicting versions of the function to avoid PGRST203 error
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(geometry, numeric);
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(text, double precision);
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(text, numeric);
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(text, double precision, bigint);
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(text, bigint);
DROP FUNCTION IF EXISTS get_nearby_pending_deliveries(text, bigint, double precision);

-- Create the RPC function for nearby delivery requests
CREATE OR REPLACE FUNCTION get_nearby_pending_deliveries(
  delivery_person_location text,
  p_delivery_person_id bigint DEFAULT NULL,
  max_distance_km double precision DEFAULT 10
)
RETURNS TABLE (
  id bigint,
  passenger_id bigint,
  delivery_person_id bigint,
  category text,
  description text,
  pickup_notes text,
  dropoff_notes text,
  status character varying,
  price numeric,
  pickup_location jsonb,
  delivery_location jsonb,
  distance_km numeric,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  distance_from_delivery_person double precision,
  passenger jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  search_radius double precision;
BEGIN
  -- Get delivery person's range preference if p_delivery_person_id is provided, otherwise use default
  IF p_delivery_person_id IS NOT NULL THEN
    SELECT COALESCE(dp.range, max_distance_km)
    INTO search_radius
    FROM delivery_persons dp
    WHERE dp.id = p_delivery_person_id;
    
    -- If delivery person not found, use default
    IF search_radius IS NULL THEN
      search_radius := max_distance_km;
    END IF;
  ELSE
    search_radius := max_distance_km;
  END IF;

  RETURN QUERY
  SELECT 
    dr.id,
    dr.passenger_id,
    dr.delivery_person_id,
    dr.category,
    dr.description,
    dr.pickup_notes,
    dr.dropoff_notes,
    dr.status,
    dr.price,
    ST_AsGeoJSON(dr.pickup_location)::jsonb as pickup_location,
    ST_AsGeoJSON(dr.delivery_location)::jsonb as delivery_location,
    dr.distance_km,
    dr.created_at,
    dr.updated_at,
    -- Use the minimum distance between pickup and delivery locations
    LEAST(
      ST_Distance(dr.pickup_location::geography, delivery_person_location::geography) / 1000,
      ST_Distance(dr.delivery_location::geography, delivery_person_location::geography) / 1000
    ) as distance_from_delivery_person,
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
    ) as passenger
  FROM delivery_requests dr
  INNER JOIN passengers p ON dr.passenger_id = p.id
  INNER JOIN users pu ON p.user_id = pu.id
  WHERE 
    (
      dr.status = 'pending'
      AND dr.delivery_person_id IS NULL
      AND (
        -- Show if pickup location is within range
        ST_DWithin(
          dr.pickup_location::geography, 
          delivery_person_location::geography, 
          search_radius * 1000
        )
        OR
        -- Show if delivery location is within range
        ST_DWithin(
          dr.delivery_location::geography, 
          delivery_person_location::geography, 
          search_radius * 1000
        )
      )
    )
    OR
    (
      -- Show requests accepted by this delivery person regardless of distance
      dr.status = 'accepted'
      AND dr.delivery_person_id = p_delivery_person_id
    )
  ORDER BY 
    -- Prioritize accepted requests
    CASE WHEN dr.status = 'accepted' THEN 0 ELSE 1 END,
    distance_from_delivery_person ASC;
END;
$$;
