-- Migration: Add status column to delivery_persons table
-- This migration adds a status field to track delivery person workflow states

-- Add status column with default value and check constraint
ALTER TABLE delivery_persons 
ADD COLUMN status VARCHAR(50) DEFAULT 'available' 
CHECK (status IN ('available', 'accepted', 'picking_up', 'picked_up', 'delivering', 'completed'));

-- Add comment to document the column
COMMENT ON COLUMN delivery_persons.status IS 'Current delivery status: available, accepted, picking_up, picked_up, delivering, completed';

-- Update existing rows to have default status
UPDATE delivery_persons SET status = 'available' WHERE status IS NULL;


