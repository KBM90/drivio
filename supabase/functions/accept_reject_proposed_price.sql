-- ============================================================================
-- ACCEPT/REJECT PROPOSED PRICE RPC FUNCTIONS
-- ============================================================================
-- Allows passenger to accept or reject the delivery person's proposed price
-- ============================================================================

-- Function to accept proposed price
CREATE OR REPLACE FUNCTION accept_proposed_price(
  p_delivery_id bigint
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status text;
  v_proposed_price decimal;
  v_result json;
BEGIN
  -- Check current status and get proposed price
  SELECT status, proposed_price INTO v_status, v_proposed_price
  FROM delivery_requests
  WHERE id = p_delivery_id;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Delivery request not found';
  END IF;

  IF v_status != 'price_negotiation' THEN
    RAISE EXCEPTION 'Can only accept price during negotiation (current status: %)', v_status;
  END IF;

  IF v_proposed_price IS NULL THEN
    RAISE EXCEPTION 'No proposed price to accept';
  END IF;

  -- Accept the proposed price: update final price and change status to accepted
  UPDATE delivery_requests
  SET 
    price = proposed_price,
    status = 'accepted',
    updated_at = NOW()
  WHERE id = p_delivery_id
  RETURNING row_to_json(delivery_requests.*) INTO v_result;

  RETURN v_result;
END;
$$;

-- Function to reject proposed price
CREATE OR REPLACE FUNCTION reject_proposed_price(
  p_delivery_id bigint
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

  IF v_status != 'price_negotiation' THEN
    RAISE EXCEPTION 'Can only reject price during negotiation (current status: %)', v_status;
  END IF;

  -- Reject the proposed price: clear proposed_price, clear delivery_person_id, revert to pending
  UPDATE delivery_requests
  SET 
    proposed_price = NULL,
    delivery_person_id = NULL,
    status = 'pending',
    updated_at = NOW()
  WHERE id = p_delivery_id
  RETURNING row_to_json(delivery_requests.*) INTO v_result;

  RETURN v_result;
END;
$$;
