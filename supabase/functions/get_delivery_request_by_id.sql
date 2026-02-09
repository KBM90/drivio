-- Drop existing function if any
DROP FUNCTION IF EXISTS get_delivery_request_by_id(bigint);

-- Create RPC function to get delivery request by ID
-- Uses SECURITY DEFINER to bypass RLS policies
CREATE OR REPLACE FUNCTION get_delivery_request_by_id(
  p_delivery_id bigint
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'id', dr.id,
    'passenger_id', dr.passenger_id,
    'delivery_person_id', dr.delivery_person_id,
    'category', dr.category,
    'description', dr.description,
    'pickup_notes', dr.pickup_notes,
    'dropoff_notes', dr.dropoff_notes,
    'status', dr.status,
    'price', dr.price,
    'pickup_location', ST_AsGeoJSON(dr.pickup_location)::jsonb,
    'delivery_location', ST_AsGeoJSON(dr.delivery_location)::jsonb,
    'distance_km', dr.distance_km,
    'created_at', dr.created_at,
    'updated_at', dr.updated_at,
    -- Passenger data
    'passenger', json_build_object(
      'id', p.id,
      'user_id', p.user_id,
      'created_at', p.created_at,
      'updated_at', p.updated_at,
      'user', json_build_object(
        'id', pu.id,
        'user_id', pu.user_id,
        'name', pu.name,
        'email', pu.email,
        'phone', pu.phone,
        'role', pu.role,
        'created_at', pu.created_at,
        'updated_at', pu.updated_at
      )
    ),
    -- Delivery person data (null if not assigned)
    'delivery_person', CASE 
      WHEN dr.delivery_person_id IS NOT NULL THEN
        json_build_object(
          'id', dp.id,
          'user_id', dp.user_id,
          'vehicle_type', dp.vehicle_type,
          'vehicle_plate', dp.vehicle_plate,
          'is_available', dp.is_available,
          'current_location', ST_AsGeoJSON(dp.current_location)::jsonb,
          'rating', dp.rating,
          'range', dp.range,
          'created_at', dp.created_at,
          'updated_at', dp.updated_at,
          'user', json_build_object(
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
    END
  )
  INTO result
  FROM delivery_requests dr
  INNER JOIN passengers p ON dr.passenger_id = p.id
  INNER JOIN users pu ON p.user_id = pu.id
  LEFT JOIN delivery_persons dp ON dr.delivery_person_id = dp.id
  LEFT JOIN users du ON dp.user_id = du.id
  WHERE dr.id = p_delivery_id;

  RETURN result;
END;
$$;
