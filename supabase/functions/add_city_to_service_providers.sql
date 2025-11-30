-- Migration: Add city column to service_providers table
-- Date: 2025-11-28

-- Add city column
ALTER TABLE public.service_providers 
ADD COLUMN IF NOT EXISTS city character varying(100) null;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_service_providers_city 
ON public.service_providers USING btree (city) TABLESPACE pg_default;

-- Update existing test data with city values
UPDATE public.service_providers 
SET city = 'Casablanca' 
WHERE user_id = 13 AND city IS NULL;

COMMENT ON COLUMN public.service_providers.city IS 'City where the service provider operates';
