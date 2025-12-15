-- ============================================
-- Test Script: Distance Accumulation Trigger
-- ============================================
-- This script helps verify that the distance accumulation trigger works correctly
SELECT 
  'BEFORE' as stage,
  id, 
  driving_distance,
  'driver' as type
FROM drivers 
WHERE id = <driver_id>

UNION ALL

SELECT 
  'BEFORE' as stage,
  id, 
  driving_distance,
  'passenger' as type
FROM passengers 
WHERE id = <passenger_id>;

-- Step 2: Check the ride request details
-- Replace <ride_id> with actual ride request ID
SELECT 
  id,
  passenger_id,
  driver_id,
  status,
  distance,
  created_at
FROM ride_requests
WHERE id = <ride_id>;

-- Step 3: Complete the ride (this should trigger the distance accumulation)
-- Replace <ride_id> with actual ride request ID
UPDATE ride_requests
SET status = 'completed'
WHERE id = <ride_id> AND status != 'completed';

-- Step 4: Verify the distances were updated
SELECT 
  'AFTER' as stage,
  id, 
  driving_distance,
  'driver' as type
FROM drivers 
WHERE id = <driver_id>

UNION ALL

SELECT 
  'AFTER' as stage,
  id, 
  driving_distance,
  'passenger' as type
FROM passengers 
WHERE id = <passenger_id>;

-- ============================================
-- Idempotency Test: Verify no double-counting
-- ============================================

-- Try updating the same ride again (should NOT increase distances)
UPDATE ride_requests
SET status = 'completed'
WHERE id = <ride_id>;

-- Check distances again (should be same as AFTER)
SELECT 
  'AFTER DUPLICATE UPDATE' as stage,
  id, 
  driving_distance,
  'driver' as type
FROM drivers 
WHERE id = <driver_id>

UNION ALL

SELECT 
  'AFTER DUPLICATE UPDATE' as stage,
  id, 
  driving_distance,
  'passenger' as type
FROM passengers 
WHERE id = <passenger_id>;

-- ============================================
-- Query to see all completed rides and their impact
-- ============================================
SELECT 
  rr.id as ride_id,
  rr.distance as ride_distance,
  rr.status,
  d.id as driver_id,
  d.driving_distance as driver_total_distance,
  p.id as passenger_id,
  p.driving_distance as passenger_total_distance
FROM ride_requests rr
LEFT JOIN drivers d ON rr.driver_id = d.id
LEFT JOIN passengers p ON rr.passenger_id = p.id
WHERE rr.status = 'completed'
ORDER BY rr.created_at DESC
LIMIT 10;
