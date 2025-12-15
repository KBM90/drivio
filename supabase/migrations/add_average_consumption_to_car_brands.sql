-- Migration: Add average_consumption column to car_brands table
-- This column stores the typical fuel consumption in liters per 100km for each vehicle model

ALTER TABLE car_brands 
ADD COLUMN IF NOT EXISTS average_consumption NUMERIC(4, 2);

-- Add comment
COMMENT ON COLUMN car_brands.average_consumption IS 'Average fuel consumption in liters per 100km';

-- Example: Update some common car models with typical consumption values
-- Uncomment and adjust as needed:
-- UPDATE car_brands SET average_consumption = 7.5 WHERE company = 'Toyota' AND model = 'Corolla';
-- UPDATE car_brands SET average_consumption = 8.2 WHERE company = 'Honda' AND model = 'Civic';
-- UPDATE car_brands SET average_consumption = 6.8 WHERE company = 'Toyota' AND model = 'Prius';
