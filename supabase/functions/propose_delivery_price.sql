-- ============================================================================
-- PROPOSE DELIVERY PRICE RPC FUNCTION
-- ============================================================================
-- Allows delivery person to propose a counter-price for a delivery request
-- ============================================================================

CREATE OR REPLACE FUNCTION propose_delivery_price(
  p_delivery_id bigint,
  p_delivery_person_id bigint,
  p_proposed_price decimal
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status text;
  v_result json;
BEGIN
  -- Check current status
  SELECT status INTO v_status
  FROM delivery_requests
  WHERE id = p_delivery_id;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Delivery request not found';
  END IF;

  IF v_status != 'pending' THEN
    RAISE EXCEPTION 'Can only propose price for pending requests (current status: %)', v_status;
  END IF;

  -- Validate proposed price
  IF p_proposed_price <= 0 THEN
    RAISE EXCEPTION 'Proposed price must be greater than 0';
  END IF;

  -- Update the request with proposed price and change status
  UPDATE delivery_requests
  SET 
    proposed_price = p_proposed_price,
    delivery_person_id = p_delivery_person_id,
    status = 'price_negotiation',
    updated_at = NOW()
  WHERE id = p_delivery_id
  RETURNING row_to_json(delivery_requests.*) INTO v_result;

  RETURN v_result;
END;
$$;
