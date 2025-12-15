-- Fix for car_renter registration trigger
-- This updates the trigger to handle car renter creation more robustly

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create the function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_user_internal_id BIGINT;
  user_role TEXT;
BEGIN
  -- Get the role from metadata
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'passenger');

  -- Insert into public.users and get the internal ID
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
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    NEW.raw_user_meta_data->>'city',
    COALESCE(NEW.raw_user_meta_data->>'country_code', 'MA'),
    NEW.raw_user_meta_data->>'phone',
    user_role,
    NOW(),
    NOW()
  )
  RETURNING id INTO new_user_internal_id;

  -- Create driver, passenger, or provider record based on role
  IF user_role = 'driver' THEN
    INSERT INTO public.drivers (
      user_id,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      NOW(),
      NOW()
    );

    -- Create wallet for driver
    INSERT INTO public.wallets (
      user_id,
      balance,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      0.00,
      NOW(),
      NOW()
    );

  ELSIF user_role = 'passenger' THEN
    INSERT INTO public.passengers (
      user_id,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      NOW(),
      NOW()
    );

  ELSIF user_role = 'provider' THEN
    INSERT INTO public.service_providers (
      user_id,
      business_name,
      provider_type,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      COALESCE(NEW.raw_user_meta_data->>'business_name', NEW.raw_user_meta_data->>'name', 'Provider'),
      COALESCE(NEW.raw_user_meta_data->>'provider_type',NEW.raw_user_meta_data->>'provider_type'),
      NOW(),
      NOW()
    );

  ELSIF user_role = 'deliveryperson' THEN
    INSERT INTO public.delivery_persons (
      user_id,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      NOW(),
      NOW()
    );

  ELSIF user_role = 'carrenter' THEN
    -- Insert into car_renters with only required fields
    -- business_name and city are optional
    INSERT INTO public.car_renters (
      user_id,
      business_name,
      city,
      created_at,
      updated_at
    )
    VALUES (
      new_user_internal_id,
      NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'business_name', '')), ''),
      NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'city', '')), ''),
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
