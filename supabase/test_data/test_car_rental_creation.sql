-- ============================================
-- Test SQL: Create Provided Car Rental
-- ============================================
-- This script creates test data for the car rental feature
-- Run this in your Supabase SQL Editor

-- Step 1: Create a test user (if not exists)
-- Replace with an actual user_id from your users table if you have one
DO $$
DECLARE
  test_user_id bigint;
  test_car_renter_id bigint;
BEGIN
  -- Check if test user exists, if not create one
  SELECT id INTO test_user_id 
  FROM public.users 
  WHERE email = 'renter@gmail.com' 
  LIMIT 1;
  
  IF test_user_id IS NULL THEN
    INSERT INTO public.users (
      email,
      name,
      phone,
      role,
      created_at,
      updated_at
    ) VALUES (
      'renter@gmail.com',
      'Car Renter',
      '+212600000001',
      'carrenter',
      NOW(),
      NOW()
    ) RETURNING id INTO test_user_id;
    
    RAISE NOTICE 'Created test user with ID: %', test_user_id;
  ELSE
    RAISE NOTICE 'Using existing test user with ID: %', test_user_id;
  END IF;

  -- Step 2: Create a car renter profile
  INSERT INTO public.car_renters (
    user_id,
    business_name,
    location,
    city,
    rating,
    total_cars,
    is_verified,
    created_at,
    updated_at
  ) VALUES (
    test_user_id,
    'Premium Car Rentals Morocco',
    ST_SetSRID(ST_MakePoint(-7.5898434, 33.5731104), 4326), -- Casablanca coordinates
    'Casablanca',
    4.8,
    0,
    true,
    NOW(),
    NOW()
  ) RETURNING id INTO test_car_renter_id;
  
  RAISE NOTICE 'Created car renter with ID: %', test_car_renter_id;

  -- Step 3: Create multiple test car rentals
  
  -- Car 1: Toyota Corolla 2023
  INSERT INTO public.provided_car_rentals (
    car_renter_id,
    car_brand_id,
    model,
    year,
    color,
    plate_number,
    location,
    city,
    daily_price,
    features,
    images,
    is_available,
    created_at,
    updated_at
  ) VALUES (
    test_car_renter_id,
    NULL, -- Set to actual car_brand_id if you have car_brands table
    'Toyota Corolla',
    2023,
    'White',
    'A-12345-B',
    ST_SetSRID(ST_MakePoint(-7.5898434, 33.5731104), 4326),
    'Casablanca',
    350.00,
    '{"air_conditioning": true, "automatic": true, "bluetooth": true, "gps": true, "seats": 5}'::jsonb,
    '["https://example.com/car1.jpg", "https://example.com/car1_interior.jpg"]'::jsonb,
    true,
    NOW(),
    NOW()
  );

  -- Car 2: Dacia Duster 2022
  INSERT INTO public.provided_car_rentals (
    car_renter_id,
    car_brand_id,
    model,
    year,
    color,
    plate_number,
    location,
    city,
    daily_price,
    features,
    images,
    is_available,
    created_at,
    updated_at
  ) VALUES (
    test_car_renter_id,
    NULL,
    'Dacia Duster',
    2022,
    'Gray',
    'B-67890-C',
    ST_SetSRID(ST_MakePoint(-7.5898434, 33.5731104), 4326),
    'Casablanca',
    280.00,
    '{"air_conditioning": true, "automatic": false, "4x4": true, "seats": 5}'::jsonb,
    '["https://example.com/car2.jpg"]'::jsonb,
    true,
    NOW(),
    NOW()
  );

  -- Car 3: Mercedes C-Class 2024 (Premium)
  INSERT INTO public.provided_car_rentals (
    car_renter_id,
    car_brand_id,
    model,
    year,
    color,
    plate_number,
    location,
    city,
    daily_price,
    features,
    images,
    is_available,
    created_at,
    updated_at
  ) VALUES (
    test_car_renter_id,
    NULL,
    'Mercedes C-Class',
    2024,
    'Black',
    'C-11111-D',
    ST_SetSRID(ST_MakePoint(-7.5898434, 33.5731104), 4326),
    'Casablanca',
    750.00,
    '{"air_conditioning": true, "automatic": true, "bluetooth": true, "gps": true, "leather_seats": true, "sunroof": true, "seats": 5}'::jsonb,
    '["https://example.com/car3.jpg", "https://example.com/car3_interior.jpg", "https://example.com/car3_side.jpg"]'::jsonb,
    true,
    NOW(),
    NOW()
  );

  -- Car 4: Renault Clio 2021 (Economy)
  INSERT INTO public.provided_car_rentals (
    car_renter_id,
    car_brand_id,
    model,
    year,
    color,
    plate_number,
    location,
    city,
    daily_price,
    features,
    images,
    is_available,
    created_at,
    updated_at
  ) VALUES (
    test_car_renter_id,
    NULL,
    'Renault Clio',
    2021,
    'Red',
    'D-22222-E',
    ST_SetSRID(ST_MakePoint(-6.8498129, 33.9715904), 4326), -- Rabat coordinates
    'Rabat',
    220.00,
    '{"air_conditioning": true, "automatic": false, "bluetooth": true, "seats": 5}'::jsonb,
    '["https://example.com/car4.jpg"]'::jsonb,
    true,
    NOW(),
    NOW()
  );

  -- Car 5: Peugeot 208 2023 (Marrakech)
  INSERT INTO public.provided_car_rentals (
    car_renter_id,
    car_brand_id,
    model,
    year,
    color,
    plate_number,
    location,
    city,
    daily_price,
    features,
    images,
    is_available,
    created_at,
    updated_at
  ) VALUES (
    test_car_renter_id,
    NULL,
    'Peugeot 208',
    2023,
    'Blue',
    'E-33333-F',
    ST_SetSRID(ST_MakePoint(-7.9811490, 31.6294723), 4326), -- Marrakech coordinates
    'Marrakech',
    300.00,
    '{"air_conditioning": true, "automatic": true, "bluetooth": true, "gps": false, "seats": 5}'::jsonb,
    '["https://example.com/car5.jpg", "https://example.com/car5_interior.jpg"]'::jsonb,
    true,
    NOW(),
    NOW()
  );

  -- Update total_cars count for the car renter
  UPDATE public.car_renters 
  SET total_cars = (
    SELECT COUNT(*) 
    FROM public.provided_car_rentals 
    WHERE car_renter_id = test_car_renter_id
  )
  WHERE id = test_car_renter_id;

  RAISE NOTICE 'Successfully created 5 test car rentals!';
  
END $$;

-- Verify the created data
SELECT 
  pcr.id,
  pcr.model,
  pcr.year,
  pcr.color,
  pcr.city,
  pcr.daily_price,
  pcr.is_available,
  cr.business_name as renter_business,
  cr.rating as renter_rating,
  cr.is_verified as renter_verified
FROM public.provided_car_rentals pcr
JOIN public.car_renters cr ON pcr.car_renter_id = cr.id
ORDER BY pcr.created_at DESC
LIMIT 10;
