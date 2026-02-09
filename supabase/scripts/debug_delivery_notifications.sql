-- ============================================================================
-- DEBUG SCRIPT: Check why delivery persons are not being notified
-- ============================================================================

-- 1. Check if there are any available delivery persons
SELECT 
  dp.id,
  dp.user_id,
  dp.is_available,
  dp.current_location,
  dp.range,
  u.name
FROM delivery_persons dp
JOIN users u ON dp.user_id = u.id;

-- 2. Check the latest delivery request
SELECT 
  id,
  passenger_id,
  category,
  status,
  price,
  pickup_location,
  delivery_location,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 1;

-- 3. Check if any delivery persons are within range of the latest request
WITH latest_request AS (
  SELECT 
    id,
    pickup_location
  FROM delivery_requests
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT 
  dp.id AS delivery_person_id,
  dp.user_id,
  dp.is_available,
  dp.current_location IS NOT NULL AS has_location,
  dp.range,
  lr.pickup_location IS NOT NULL AS request_has_pickup,
  CASE 
    WHEN dp.current_location IS NOT NULL AND lr.pickup_location IS NOT NULL THEN
      ST_Distance(
        dp.current_location::geography,
        lr.pickup_location
      ) / 1000
    ELSE NULL
  END AS distance_km,
  u.name
FROM delivery_persons dp
CROSS JOIN latest_request lr
JOIN users u ON dp.user_id = u.id
ORDER BY distance_km NULLS LAST;

-- 4. Check notifications table for any delivery request notifications
SELECT 
  n.id,
  n.user_id,
  n.title,
  n.body,
  n.data,
  n.created_at,
  u.name AS user_name
FROM notifications n
JOIN users u ON n.user_id = u.id
WHERE n.data->>'type' = 'new_delivery_request'
ORDER BY n.created_at DESC
LIMIT 10;
