-- Enable RLS on delivery_requests if not already enabled
ALTER TABLE delivery_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Allow delivery persons to view requests assigned to them or pending ones (if needed)
-- (Assuming there might be existing policies, we'll use DO block or drop if exists to be safe, but simple CREATE POLICY is standard here)

-- 1. Delivery persons can select requests assigned to them
CREATE POLICY "Delivery persons can select assigned requests"
ON delivery_requests
FOR SELECT
USING (
  auth.uid() IN (
    SELECT u.user_id 
    FROM delivery_persons dp
    JOIN users u ON u.id = dp.user_id
    WHERE dp.id = delivery_requests.delivery_person_id
  )
);

-- 2. Delivery persons can update status of requests assigned to them
CREATE POLICY "Delivery persons can update assigned requests"
ON delivery_requests
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT u.user_id 
    FROM delivery_persons dp
    JOIN users u ON u.id = dp.user_id
    WHERE dp.id = delivery_requests.delivery_person_id
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT u.user_id 
    FROM delivery_persons dp
    JOIN users u ON u.id = dp.user_id
    WHERE dp.id = delivery_requests.delivery_person_id
  )
);

-- 3. Delivery persons can select pending requests (for the requests feed)
CREATE POLICY "Delivery persons can select pending requests"
ON delivery_requests
FOR SELECT
USING (
  status = 'pending'
);

-- 4. Delivery persons can accept (update) pending requests
-- When accepting, the delivery_person_id is initially null, so we need to allow update if status is pending
-- AND the new row has the user's delivery_person_id
CREATE POLICY "Delivery persons can accept pending requests"
ON delivery_requests
FOR UPDATE
USING (
  status = 'pending'
)
WITH CHECK (
  status IN ('accepted', 'price_negotiation') AND
  auth.uid() IN (
    SELECT u.user_id 
    FROM delivery_persons dp
    JOIN users u ON u.id = dp.user_id
    WHERE dp.id = delivery_person_id
  )
);
