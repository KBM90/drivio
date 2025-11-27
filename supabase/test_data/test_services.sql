-- Test data for Services Feature

-- 1. Create a Service Provider (linked to an existing user, e.g., user_id 12 which is driver 3)
-- Adjust user_id as needed. Here assuming user_id 13 exists.
INSERT INTO service_providers (user_id, business_name, provider_type, phone, address, rating, is_verified)
VALUES (13, 'Fast Fix Mechanics', 'mechanic', '+212600000003', '123 Industrial Zone, Casablanca', 4.8, true)
ON CONFLICT DO NOTHING;

-- Get the provider ID
DO $$
DECLARE
  v_provider_id bigint;
BEGIN
  SELECT id INTO v_provider_id FROM service_providers WHERE user_id = 13 LIMIT 1;

  -- 2. Create Provided Services
  INSERT INTO provided_services (provider_id, name, description, price, category)
  VALUES 
    (v_provider_id, 'Oil Change', 'Full synthetic oil change including filter', 300.00, 'Mechanic'),
    (v_provider_id, 'Brake Inspection', 'Complete brake system check', 150.00, 'Mechanic'),
    (v_provider_id, 'Engine Tune-up', 'Spark plugs, air filter, and diagnostics', 500.00, 'Mechanic');

  -- 3. Add Images (assuming service IDs are sequential for this test, but using subquery is safer)
  INSERT INTO service_images (service_id, image_url)
  SELECT id, 'https://hips.hearstapps.com/hmg-prod/images/oil5981-667dbd6cb2cec.jpg?crop=1.00xw:0.847xh;0,0.0204xh&resize=1800:*'
  FROM provided_services WHERE name = 'Oil Change' AND provider_id = v_provider_id;

  INSERT INTO service_images (service_id, image_url)
  SELECT id, 'https://d12yp66odzcfr0.cloudfront.net/images/grant-road/Grant-Road-2.jpg'
  FROM provided_services WHERE name = 'Brake Inspection' AND provider_id = v_provider_id;

END $$;

-- Verification Query
SELECT 
    sp.business_name,
    ps.name as service_name,
    ps.price,
    ps.category,
    si.image_url
FROM service_providers sp
JOIN provided_services ps ON sp.id = ps.provider_id
LEFT JOIN service_images si ON ps.id = si.service_id
WHERE sp.user_id = 13;
