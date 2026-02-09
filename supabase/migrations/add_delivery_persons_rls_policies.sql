-- RLS Policy: Allow delivery persons to update their own location
-- This fixes the issue where location updates return empty array due to RLS blocking

-- Enable RLS on delivery_persons table (if not already enabled)
ALTER TABLE delivery_persons ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Delivery persons can update own location" ON delivery_persons;

-- Create policy to allow delivery persons to update their own record
CREATE POLICY "Delivery persons can update own location"
ON delivery_persons
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT user_id 
    FROM users 
    WHERE users.id = delivery_persons.user_id
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT user_id 
    FROM users 
    WHERE users.id = delivery_persons.user_id
  )
);

-- Also ensure delivery persons can read their own data
DROP POLICY IF EXISTS "Delivery persons can view own data" ON delivery_persons;

CREATE POLICY "Delivery persons can view own data"
ON delivery_persons
FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id 
    FROM users 
    WHERE users.id = delivery_persons.user_id
  )
);
