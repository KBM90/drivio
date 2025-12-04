-- Migration: Add PayPal to payment_methods table
-- Description: Ensures PayPal payment method exists in the payment_methods table

-- Insert PayPal payment method if it doesn't exist
INSERT INTO payment_methods (name, requires_details, created_at, updated_at)
VALUES ('PayPal', true, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;
