-- Create 5 test delivery requests for testing nearby delivery functionality
-- 3 requests in Saidia, Morocco
-- 2 requests in Casablanca, Morocco

-- Saidia coordinates: approximately 35.0889° N, 2.3389° W
-- Casablanca coordinates: approximately 33.5731° N, 7.5898° W

-- Request 1: Saidia - Electronics delivery
INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  pickup_location,
  delivery_location,
  price,
  distance_km
)
SELECT 
  id as passenger_id,
  'Electronics' as category,
  'Laptop delivery in Saidia' as description,
  'Pickup at tech store, building 12' as pickup_notes,
  'Leave at apartment 5B' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-2.3389 35.0889)'::geography as pickup_location,  -- Saidia center
  'SRID=4326;POINT(-2.3350 35.0920)'::geography as delivery_location, -- ~500m away
  30.00 as price,
  0.5 as distance_km
FROM public.passengers
LIMIT 1;

-- Request 2: Saidia - Food delivery
INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  pickup_location,
  delivery_location,
  price,
  distance_km
)
SELECT 
  id as passenger_id,
  'Food' as category,
  'Restaurant order in Saidia' as description,
  'Pickup at Marina Restaurant' as pickup_notes,
  'Ring doorbell twice' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-2.234795 35.083288)'::geography as pickup_location,  -- Saidia west
  'SRID=4326;POINT(-2.233336 35.087081)'::geography as delivery_location, 
  
-- ~1.2km away
  15.00 as price,
  1.2 as distance_km
FROM public.passengers
LIMIT 1;

-- Request 3: Saidia - Documents
INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  pickup_location,
  delivery_location,
  price,
  distance_km
)
SELECT 
  id as passenger_id,
  'Documents' as category,
  'Important papers in Saidia' as description,
  'Pickup from law office, 3rd floor' as pickup_notes,
  'Hand to receptionist' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-2.3360 35.0910)'::geography as pickup_location,  -- Saidia north
  'SRID=4326;POINT(-2.3400 35.0850)'::geography as delivery_location, -- ~800m away
  20.00 as price,
  0.8 as distance_km
FROM public.passengers
LIMIT 1;

-- Request 4: Casablanca - Groceries
INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  pickup_location,
  delivery_location,
  price,
  distance_km
)
SELECT 
  id as passenger_id,
  'Groceries' as category,
  'Supermarket delivery in Casablanca' as description,
  'Pickup at Marjane, ask for order #123' as pickup_notes,
  'Leave at main entrance' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-7.5898 33.5731)'::geography as pickup_location,  -- Casablanca center
  'SRID=4326;POINT(-7.5850 33.5780)'::geography as delivery_location, -- ~600m away
  25.00 as price,
  0.6 as distance_km
FROM public.passengers
LIMIT 1;

-- Request 5: Casablanca - Package
INSERT INTO public.delivery_requests (
  passenger_id,
  category,
  description,
  pickup_notes,
  dropoff_notes,
  status,
  pickup_location,
  delivery_location,
  price,
  distance_km
)
SELECT 
  id as passenger_id,
  'Package' as category,
  'Parcel delivery in Casablanca' as description,
  'Pickup at post office counter 3' as pickup_notes,
  'Call on arrival: 0612345678' as dropoff_notes,
  'pending' as status,
  'SRID=4326;POINT(-7.5920 33.5700)'::geography as pickup_location,  -- Casablanca south
  'SRID=4326;POINT(-7.5800 33.5750)'::geography as delivery_location, -- ~1.3km away
  18.00 as price,
  1.3 as distance_km
FROM public.passengers
LIMIT 1;

-- Verify the insertions
SELECT 
  id,
  category,
  description,
  ST_AsText(pickup_location::geometry) as pickup_coords,
  ST_AsText(delivery_location::geometry) as delivery_coords,
  price,
  distance_km
FROM public.delivery_requests
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 5;
