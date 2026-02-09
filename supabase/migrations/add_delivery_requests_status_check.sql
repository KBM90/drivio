-- Add CHECK constraint to delivery_requests.status if it doesn't exist
-- This ensures only valid status values can be stored

ALTER TABLE delivery_requests 
DROP CONSTRAINT IF EXISTS delivery_requests_status_check;

ALTER TABLE delivery_requests 
ADD CONSTRAINT delivery_requests_status_check 
CHECK (status IN ('pending', 'accepted', 'picking_up', 'picked_up', 'delivering', 'completed', 'cancelled'));
