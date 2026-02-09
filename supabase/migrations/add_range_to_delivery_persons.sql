-- Add range column to delivery_persons table
-- This allows each delivery person to configure their preferred search radius

ALTER TABLE delivery_persons 
ADD COLUMN IF NOT EXISTS range numeric(10,2) DEFAULT 10.0;

COMMENT ON COLUMN delivery_persons.range IS 'Search radius in kilometers for nearby delivery requests';
