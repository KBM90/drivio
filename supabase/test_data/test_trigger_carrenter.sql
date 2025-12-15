-- Test script to manually simulate what the trigger does
-- Run this in Supabase SQL Editor to see the exact error

DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  new_user_internal_id BIGINT;
  user_role TEXT := 'carrenter';
  test_metadata JSONB := '{
    "role": "carrenter",
    "name": "Test Car Renter",
    "city": "Casablanca",
    "country_code": "MA",
    "phone": "+212600000000",
    "business_name": "Test Rental Business"
  }'::jsonb;
BEGIN
  -- Step 1: Insert into public.users
  RAISE NOTICE 'Step 1: Inserting into public.users...';
  
  INSERT INTO public.users (
    user_id,
    email,
    name,
    city,
    country_code,
    phone,
    role,
    created_at,
    updated_at
  )
  VALUES (
    test_user_id,
    'test_carrenter_' || extract(epoch from now()) || '@test.com',
    COALESCE(test_metadata->>'name', 'User'),
    test_metadata->>'city',
    test_metadata->>'country_code',
    test_metadata->>'phone',
    user_role,
    NOW(),
    NOW()
  )
  RETURNING id INTO new_user_internal_id;
  
  RAISE NOTICE 'Created user with internal ID: %', new_user_internal_id;
  
  -- Step 2: Insert into car_renters
  RAISE NOTICE 'Step 2: Inserting into car_renters...';
  
  INSERT INTO public.car_renters (
    user_id,
    business_name,
    city,
    created_at,
    updated_at
  )
  VALUES (
    new_user_internal_id,
    NULLIF(TRIM(COALESCE(test_metadata->>'business_name', '')), ''),
    NULLIF(TRIM(COALESCE(test_metadata->>'city', '')), ''),
    NOW(),
    NOW()
  );
  
  RAISE NOTICE 'Successfully created car_renter record!';
  
  -- Rollback to clean up test data
  RAISE EXCEPTION 'Test completed successfully - rolling back';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error occurred: %', SQLERRM;
    RAISE NOTICE 'Error detail: %', SQLSTATE;
    -- Re-raise to see full error
    RAISE;
END $$;
