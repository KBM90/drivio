-- ============================================
-- Test Data for Fuel Calculator (Driver ID = 3)
-- ============================================

-- Step 1: Check existing data for driver_id = 3
SELECT 'Current ride_details for driver 3:' as info;
SELECT * FROM ride_details WHERE driver_id = 3;

SELECT 'Current car_expenses for driver 3:' as info;
SELECT * FROM car_expenses WHERE driver_id = 3;

SELECT 'Driver 3 vehicle info:' as info;
SELECT v.*, cb.company, cb.model, cb.average_consumption 
FROM vehicles v
LEFT JOIN car_brands cb ON v.car_brand_id = cb.id
WHERE v.driver_id = 3;

-- ============================================
-- Step 2: Insert test ride_details records
-- ============================================

-- Insert 3 sample completed rides for driver 3
-- These will be used to calculate total distance

INSERT INTO ride_details (
  driver_id,
  passenger_id,
  price,
  distance,
  created_at
) VALUES
  -- Ride 1: 15.5 km
  (3, 1, 25.50, 15.5, NOW() - INTERVAL '5 days'),
  
  -- Ride 2: 22.3 km
  (3, 2, 38.75, 22.3, NOW() - INTERVAL '3 days'),
  
  -- Ride 3: 8.7 km
  (3, 1, 18.20, 8.7, NOW() - INTERVAL '1 day');

-- Verify inserted data
SELECT 'Inserted ride_details for driver 3:' as info;
SELECT id, driver_id, distance, price, created_at 
FROM ride_details 
WHERE driver_id = 3
ORDER BY created_at DESC;

-- Calculate total distance
SELECT 'Total distance for driver 3:' as info;
SELECT 
  driver_id,
  COUNT(*) as total_rides,
  SUM(distance) as total_distance_km,
  SUM(price) as total_earnings
FROM ride_details
WHERE driver_id = 3
GROUP BY driver_id;

-- ============================================
-- Step 3: Check if trigger exists for ride_requests -> ride_details
-- ============================================

SELECT 'Checking for triggers on ride_requests:' as info;
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'ride_requests'
ORDER BY trigger_name;

-- Check for trigger that creates ride_details on completion
SELECT 'Checking for ride completion trigger:' as info;
SELECT 
  trigger_name,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'ride_requests'
  AND action_statement LIKE '%ride_details%';

-- ============================================
-- Step 4: Test the fuel calculator calculation
-- ============================================

-- Assuming driver 3 has a vehicle with average_consumption set
-- Let's simulate the calculation

WITH driver_data AS (
  -- Get driver's vehicle and consumption
  SELECT 
    v.driver_id,
    cb.company,
    cb.model,
    cb.average_consumption
  FROM vehicles v
  JOIN car_brands cb ON v.car_brand_id = cb.id
  WHERE v.driver_id = 3 AND v.status = true
  LIMIT 1
),
distance_data AS (
  -- Get total distance from rides
  SELECT 
    driver_id,
    SUM(distance) as total_distance
  FROM ride_details
  WHERE driver_id = 3
  GROUP BY driver_id
),
calculation AS (
  -- Calculate fuel consumption
  SELECT 
    dd.driver_id,
    dd.company || ' ' || dd.model as vehicle,
    dd.average_consumption as avg_consumption_per_100km,
    dist.total_distance as total_distance_km,
    -- Calculate fuel liters: (distance * consumption) / 100
    ROUND((dist.total_distance * dd.average_consumption) / 100, 2) as fuel_liters_needed,
    -- Example fuel price: $1.50 per liter
    1.50 as fuel_price_per_liter,
    -- Calculate total cost: liters * price
    ROUND(((dist.total_distance * dd.average_consumption) / 100) * 1.50, 2) as total_fuel_cost,
    -- Calculate cost per km
    ROUND((((dist.total_distance * dd.average_consumption) / 100) * 1.50) / dist.total_distance, 3) as cost_per_km
  FROM driver_data dd
  CROSS JOIN distance_data dist
)
SELECT 
  'Fuel Calculator Test Results:' as info,
  *
FROM calculation;

-- ============================================
-- Step 5: Check car_expenses created by auto-track trigger
-- ============================================

SELECT 'Auto-tracked car_expenses (from trigger):' as info;
SELECT 
  id,
  expense_type,
  amount,
  distance_km,
  description,
  expense_date,
  created_at
FROM car_expenses
WHERE driver_id = 3
  AND description LIKE 'Auto-tracked from ride%'
ORDER BY created_at DESC;

-- ============================================
-- Summary Query
-- ============================================

SELECT '=== SUMMARY FOR DRIVER 3 ===' as summary;

SELECT 
  'Total Rides' as metric,
  COUNT(*)::text as value
FROM ride_details WHERE driver_id = 3
UNION ALL
SELECT 
  'Total Distance (km)',
  ROUND(SUM(distance), 2)::text
FROM ride_details WHERE driver_id = 3
UNION ALL
SELECT 
  'Total Earnings ($)',
  ROUND(SUM(price), 2)::text
FROM ride_details WHERE driver_id = 3
UNION ALL
SELECT 
  'Auto-tracked Expenses',
  COUNT(*)::text
FROM car_expenses 
WHERE driver_id = 3 AND description LIKE 'Auto-tracked%';

-- ============================================
-- NOTES:
-- ============================================
-- 1. If no vehicle is found, you need to:
--    - Insert a vehicle for driver 3
--    - Ensure the car_brand has average_consumption set
--
-- 2. If no trigger exists for ride_requests -> ride_details:
--    - You may need to create one
--    - Or manually insert ride_details when rides complete
--
-- 3. The auto_track_ride_distance trigger should create
--    car_expenses records when ride_requests status = 'completed'
--
-- 4. Expected calculation with example data:
--    - Total distance: 46.5 km (15.5 + 22.3 + 8.7)
--    - If avg consumption = 7.5 L/100km
--    - Fuel needed: (46.5 * 7.5) / 100 = 3.49 L
--    - At $1.50/L: 3.49 * 1.50 = $5.24
--    - Cost per km: $5.24 / 46.5 = $0.113/km
