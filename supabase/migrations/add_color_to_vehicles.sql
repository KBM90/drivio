-- Add color column to vehicles table
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS color VARCHAR(50);
