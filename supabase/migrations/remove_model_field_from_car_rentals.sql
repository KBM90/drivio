-- Remove model field from provided_car_rentals and make car_brand_id required

-- First, ensure all existing records have a car_brand_id
-- You may need to manually assign brands to existing cars before running this

-- Make car_brand_id NOT NULL
ALTER TABLE public.provided_car_rentals
ALTER COLUMN car_brand_id SET NOT NULL;

-- Drop the model column
ALTER TABLE public.provided_car_rentals
DROP COLUMN model;

-- Update the foreign key constraint to ensure data integrity
ALTER TABLE public.provided_car_rentals
DROP CONSTRAINT IF EXISTS provided_car_rentals_car_brand_id_fkey;

ALTER TABLE public.provided_car_rentals
ADD CONSTRAINT provided_car_rentals_car_brand_id_fkey 
FOREIGN KEY (car_brand_id) 
REFERENCES car_brands (id) 
ON DELETE RESTRICT;
