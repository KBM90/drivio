-- Create a test delivery request linked to the first available passenger
-- This ensures you have a valid 'pending' request to test the delivery person workflow

INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  delivery_location,  -- Dropoff location
  pickup_location,    -- Pickup location
  price,
  distance_km
)
SELECT 
  id as passenger_id, -- Automatically selects the first available passenger. create a passenger first if none exist!
  'Electronics' as category,
  'Test delivery request created via SQL' as description,
  'Pickup at the blue gate, invoke 123' as pickup_notes,
  'Leave at reception desk' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-2.224563 35.077688)'::geography as delivery_location, -- Example Coordinates
  'SRID=4326;POINT(-2.228563 35.087688)'::geography as pickup_location,   -- Example Coordinates
  25.00 as price,
  5.5 as distance_km
FROM public.passengers
LIMIT 1;
