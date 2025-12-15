-- ============================================
-- Test Data: Insert Completed Ride Request
-- Purpose: Test the Trip History feature
-- ============================================

-- This script inserts a completed ride request with all necessary related data
-- You can run this in your Supabase SQL Editor to create test data

-- Step 1: Insert a test user for the passenger (if not exists)
INSERT INTO public.users (id, name, email, phone, country_code, role, is_verified, created_at)
VALUES (
  9999991,
  'Test Passenger',
  'test.passenger@example.com',
  '0612345678',
  '+212',
  'passenger',
  true,
  NOW() - INTERVAL '30 days'
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Insert a test passenger record (if not exists)
INSERT INTO public.passengers (id, user_id, created_at)
VALUES (
  9999991,
  9999991,
  NOW() - INTERVAL '30 days'
)
ON CONFLICT (id) DO NOTHING;

-- Step 3: Insert a test user for the driver (if not exists)
-- NOTE: Replace this ID with your actual driver's user ID if you want to see it in your account
INSERT INTO public.users (id, name, email, phone, country_code, role, is_verified, created_at)
VALUES (
  9999992,
  'Test Driver',
  'test.driver@example.com',
  '0698765432',
  '+212',
  'driver',
  true,
  NOW() - INTERVAL '60 days'
)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Insert a test driver record (if not exists)
-- NOTE: Replace this ID with your actual driver ID to see the trip in YOUR trip history
INSERT INTO public.drivers (id, user_id, status, created_at)
VALUES (
  9999992,
  9999992,
  'inactive',
  NOW() - INTERVAL '60 days'
)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Ensure transport type exists (usually already in database)
INSERT INTO public.transport_types (id, name, created_at)
VALUES (1, 'Car', NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 6: Ensure payment method exists (usually already in database)
INSERT INTO public.payment_methods (id, name, created_at)
VALUES (1, 'Cash', NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 7: Insert the completed ride request
INSERT INTO public.ride_requests (
  passenger_id,
  driver_id,
  transport_type_id,
  payment_method_id,
  status,
  price,
  pickup_location,
  dropoff_location,
  distance,
  duration,
  requested_at,
  accepted_at,
  created_at,
  updated_at,
  preferences
)
VALUES (
  9999991, -- passenger_id
  9999992, -- driver_id (CHANGE THIS to your actual driver ID)
  1, -- transport_type_id (Car)
  1, -- payment_method_id (Cash)
  'completed', -- status
  45.50, -- price in MAD
  ST_SetSRID(ST_MakePoint(-1.9447, 33.5731), 4326), -- pickup: Casablanca center
  ST_SetSRID(ST_MakePoint(-1.9100, 33.6000), 4326), -- dropoff: Casablanca north
  8.5, -- distance in km
  15, -- duration in minutes
  NOW() - INTERVAL '2 hours', -- requested 2 hours ago
  NOW() - INTERVAL '1 hour 55 minutes', -- accepted 5 minutes after request
  NOW() - INTERVAL '2 hours', -- created 2 hours ago
  NOW() - INTERVAL '1 hour 30 minutes', -- updated when completed
  '{"notes": "Test ride for trip history", "passengers": 1}'::jsonb
);

-- Step 8: Insert another completed ride (different date)
INSERT INTO public.ride_requests (
  passenger_id,
  driver_id,
  transport_type_id,
  payment_method_id,
  status,
  price,
  pickup_location,
  dropoff_location,
  distance,
  duration,
  requested_at,
  accepted_at,
  created_at,
  updated_at,
  preferences
)
VALUES (
  9999991,
  9999992, -- CHANGE THIS to your actual driver ID
  1,
  1,
  'completed',
  32.00,
  ST_SetSRID(ST_MakePoint(-1.9300, 33.5800), 4326),
  ST_SetSRID(ST_MakePoint(-1.9200, 33.5750), 4326),
  5.2,
  10,
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day' + INTERVAL '3 minutes',
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day' + INTERVAL '15 minutes',
  '{"notes": "Second test ride", "passengers": 2}'::jsonb
);

-- Step 9: Insert a cancelled ride for testing
INSERT INTO public.ride_requests (
  passenger_id,
  driver_id,
  transport_type_id,
  payment_method_id,
  status,
  price,
  pickup_location,
  dropoff_location,
  distance,
  duration,
  requested_at,
  accepted_at,
  created_at,
  updated_at,
  cancellation_reason,
  preferences
)
VALUES (
  9999991,
  9999992, -- CHANGE THIS to your actual driver ID
  1,
  1,
  'cancelled_by_driver',
  25.00,
  ST_SetSRID(ST_MakePoint(-1.9500, 33.5700), 4326),
  ST_SetSRID(ST_MakePoint(-1.9400, 33.5650), 4326),
  3.8,
  8,
  NOW() - INTERVAL '3 days',
  NOW() - INTERVAL '3 days' + INTERVAL '2 minutes',
  NOW() - INTERVAL '3 days',
  NOW() - INTERVAL '3 days' + INTERVAL '5 minutes',
  'Passenger not responding',
  '{"notes": "Cancelled test ride", "passengers": 1}'::jsonb
);

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify the data was inserted correctly:

SELECT 
  rr.id,
  rr.status,
  rr.price,
  rr.distance,
  rr.duration,
  rr.created_at,
  u.name as passenger_name,
  tt.name as transport_type,
  pm.name as payment_method
FROM ride_requests rr
JOIN passengers p ON rr.passenger_id = p.id
JOIN users u ON p.user_id = u.id
JOIN transport_types tt ON rr.transport_type_id = tt.id
JOIN payment_methods pm ON rr.payment_method_id = pm.id
WHERE rr.driver_id = 9999992 -- CHANGE THIS to your actual driver ID
ORDER BY rr.created_at DESC;

-- ============================================
-- IMPORTANT NOTES:
-- ============================================
-- 1. Replace driver_id 9999992 with your actual driver ID throughout this script
-- 2. You can find your driver ID by running: SELECT id FROM drivers WHERE user_id = auth.uid();
-- 3. The coordinates used are for Casablanca, Morocco (adjust if needed)
-- 4. This creates 3 test rides: 2 completed and 1 cancelled
-- 5. To clean up test data later, run: DELETE FROM ride_requests WHERE driver_id = 9999992;
