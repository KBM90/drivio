-- Remove status column from delivery_persons table
-- Status now belongs to delivery_requests table

ALTER TABLE delivery_persons DROP COLUMN IF EXISTS status;

-- Note: delivery_requests.status already exists with the correct values:
-- pending, accepted, picking_up, picked_up, delivering, completed, cancelled
