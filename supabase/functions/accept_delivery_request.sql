-- ============================================================================
-- ACCEPT DELIVERY REQUEST RPC FUNCTION
-- ============================================================================
-- Allows delivery person to accept a delivery request at the ORIGINAL price.
-- For accepting PROPOSED prices, use accept_proposed_price() instead.
-- ============================================================================

CREATE OR REPLACE FUNCTION accept_delivery_request(
  p_delivery_id bigint,
  p_delivery_person_id bigint
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
    RAISE EXCEPTION 'Delivery request is no longer available (current status: %)', v_status;
  END IF;

  -- Update the request
  UPDATE delivery_requests
  SET 
    status = 'accepted',
    delivery_person_id = p_delivery_person_id,
    updated_at = NOW()
  WHERE id = p_delivery_id
  RETURNING row_to_json(delivery_requests.*) INTO v_result;

  RETURN v_result;
END;
$$;
