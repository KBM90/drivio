-- Test data script to simulate a completed ride with payment for driver ID 3
-- This will populate ride_requests, ride_payments, and related tables

-- Step 1: Get or create a passenger (assuming passenger ID 1 exists, adjust if needed)
-- If you need to create a passenger, uncomment and adjust the following:
-- INSERT INTO passengers (user_id, created_at, updated_at)
-- VALUES (1, now(), now())
-- ON CONFLICT DO NOTHING;

-- Step 2: Get or create a payment method for the passenger
-- First, ensure a payment method exists in the payment_methods table
INSERT INTO payment_methods (id, name, created_at, updated_at)
VALUES 
  (1, 'Cash', now(), now()),
  (2, 'Bank Transfer', now(), now()),
  (3, 'Credit Card', now(), now())
ON CONFLICT (id) DO NOTHING;

-- Create a user payment method for passenger (passenger_id = 1, user_id = 9)
INSERT INTO user_payment_methods (user_id, payment_method_id, is_default, created_at, updated_at)
VALUES (9, 1, true, now(), now())
ON CONFLICT DO NOTHING
RETURNING id;

-- Note: If the above returns nothing, you need to find the existing user_payment_method_id
-- You can query: SELECT id FROM user_payment_methods WHERE user_id = 1 LIMIT 1;

-- Step 3: Create a completed ride request for driver ID 3
-- Note: Adjust transport_type_id if needed (assuming 1 exists)
INSERT INTO ride_requests (
  passenger_id,
  driver_id,
  transport_type_id,
  payment_method_id,
  pickup_location,
  dropoff_location,
  status,
  price,
  distance,
  duration,
  requested_at,
  accepted_at,
  created_at,
  updated_at
)
VALUES (
  1, -- passenger_id
  3, -- driver_id
  1, -- transport_type_id (adjust if needed)
  1, -- payment_method_id (Cash)
  ST_SetSRID(ST_MakePoint(-7.6177, 33.5731), 4326), -- Casablanca coordinates
  ST_SetSRID(ST_MakePoint(-7.6297, 33.5892), 4326), -- Nearby location
  'completed',
  150.00, -- price in Dirham
  5.5, -- distance in km
  15, -- duration in minutes
  now() - interval '2 hours', -- requested 2 hours ago
  now() - interval '1 hour 55 minutes', -- accepted 5 minutes after request
  now() - interval '2 hours', -- created 2 hours ago
  now() -- updated now
)
RETURNING id;

-- Note the returned ride_request_id, or query it:
-- SELECT id FROM ride_requests WHERE driver_id = 3 ORDER BY created_at DESC LIMIT 1;

-- Step 4: Create the payment record
-- Replace <ride_request_id> and <user_payment_method_id> with actual values
-- For this example, I'll use a subquery approach

DO $$
DECLARE
  v_ride_request_id bigint;
  v_user_payment_method_id bigint;
  v_fare numeric(10,2) := 150.00;
  v_commission_pct numeric(5,2) := 20.00;
  v_driver_earnings numeric(10,2);
BEGIN
  -- Get the most recent ride request for driver 3
  SELECT id INTO v_ride_request_id
  FROM ride_requests
  WHERE driver_id = 3
  ORDER BY created_at DESC
  LIMIT 1;

  -- Get a user payment method (Cash)
  SELECT id INTO v_user_payment_method_id
  FROM user_payment_methods
  WHERE payment_method_id = 1 -- Cash
  LIMIT 1;

  -- Calculate driver earnings (fare - commission)
  v_driver_earnings := v_fare * (1 - v_commission_pct / 100);

  -- Insert payment record
  INSERT INTO ride_payments (
    ride_request_id,
    user_payment_method_id,
    amount,
    payment_status,
    currency,
    transaction_id,
    payment_date,
    commission_percentage,
    driver_earnings,
    created_at,
    updated_at
  )
  VALUES (
    v_ride_request_id,
    v_user_payment_method_id,
    v_fare,
    'completed',
    'MAD', -- Moroccan Dirham
    'TEST_' || v_ride_request_id || '_' || extract(epoch from now())::text,
    now(),
    v_commission_pct,
    v_driver_earnings,
    now(),
    now()
  );

  RAISE NOTICE 'Created ride request ID: %, Payment with driver earnings: %', v_ride_request_id, v_driver_earnings;
END $$;

-- Step 5: Refresh the earnings summary for today
SELECT refresh_driver_earnings_summary(
  3, -- driver_id
  current_date, -- period_start (today)
  current_date  -- period_end (today)
);

-- Step 6: Verify the data
SELECT 
  'Ride Requests' as table_name,
  count(*) as count,
  sum(price) as total_price
FROM ride_requests
WHERE driver_id = 3 AND created_at::date = current_date

UNION ALL

SELECT 
  'Ride Payments' as table_name,
  count(*) as count,
  sum(driver_earnings) as total_earnings
FROM ride_payments rp
INNER JOIN ride_requests rr ON rr.id = rp.ride_request_id
WHERE rr.driver_id = 3 AND rr.created_at::date = current_date

UNION ALL

SELECT 
  'Earnings Summary' as table_name,
  1 as count,
  total_earnings
FROM driver_earnings_summary
WHERE driver_id = 3 
  AND period_start = current_date 
  AND period_end = current_date;
