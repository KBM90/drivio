-- Add unavailability date range fields to provided_car_rentals table

ALTER TABLE public.provided_car_rentals
ADD COLUMN unavailable_from timestamp with time zone null,
ADD COLUMN unavailable_until timestamp with time zone null;

-- Add index for querying unavailable periods
CREATE INDEX IF NOT EXISTS idx_provided_car_rentals_unavailable_dates 
ON public.provided_car_rentals (unavailable_from, unavailable_until);

-- Add comment explaining the fields
COMMENT ON COLUMN public.provided_car_rentals.unavailable_from IS 'Start date of unavailability period';
COMMENT ON COLUMN public.provided_car_rentals.unavailable_until IS 'End date of unavailability period';
