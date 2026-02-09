-- ============================================================================
-- ADD PRICE NEGOTIATION COLUMNS TO DELIVERY_REQUESTS
-- ============================================================================
-- This migration adds support for price negotiation between passengers and
-- delivery persons.
-- ============================================================================

-- Add proposed_price column to track counter-offers from delivery persons
ALTER TABLE delivery_requests
ADD COLUMN IF NOT EXISTS proposed_price DECIMAL(10, 2) DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN delivery_requests.proposed_price IS 'Counter-price proposed by delivery person during negotiation. NULL means no counter-offer.';

-- Update status check constraint to include 'price_negotiation'
ALTER TABLE delivery_requests
DROP CONSTRAINT IF EXISTS delivery_requests_status_check;

ALTER TABLE delivery_requests
ADD CONSTRAINT delivery_requests_status_check 
CHECK (status IN ('pending', 'price_negotiation', 'accepted', 'picking_up', 'picked_up', 'delivering', 'completed', 'cancelled'));

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'delivery_requests' 
AND column_name = 'proposed_price';
