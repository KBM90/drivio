-- ============================================================================
-- PRICE NEGOTIATION NOTIFICATION TRIGGERS
-- ============================================================================
-- Triggers to notify passengers and delivery persons during price negotiation
-- ============================================================================

-- ============================================================================
-- 1. NOTIFY PASSENGER ON PRICE PROPOSAL
-- ============================================================================
CREATE OR REPLACE FUNCTION notify_passenger_on_price_proposal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_passenger_user_id bigint;
  v_delivery_person_name text;
  v_original_price decimal;
  v_proposed_price decimal;
BEGIN
  -- Only proceed if status changed to 'price_negotiation'
  IF NEW.status = 'price_negotiation' AND (OLD.status IS NULL OR OLD.status != 'price_negotiation') THEN
    
    -- Get passenger's user_id
    SELECT user_id INTO v_passenger_user_id
    FROM passengers
    WHERE id = NEW.passenger_id;
    
    -- Get delivery person's name
    SELECT u.name INTO v_delivery_person_name
    FROM delivery_persons dp
    JOIN users u ON dp.user_id = u.id
    WHERE dp.id = NEW.delivery_person_id;
    
    v_original_price := NEW.price;
    v_proposed_price := NEW.proposed_price;
    
    -- Insert notification for the passenger
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_passenger_user_id,
      '💰 New Price Proposal',
      COALESCE(v_delivery_person_name || ' proposed $' || v_proposed_price || ' (original: $' || v_original_price || ')', 
               'A delivery person proposed a new price for your delivery'),
      jsonb_build_object(
        'type', 'price_proposal',
        'delivery_request_id', NEW.id,
        'delivery_person_id', NEW.delivery_person_id,
        'original_price', v_original_price,
        'proposed_price', v_proposed_price,
        'action_required', true
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_passenger_on_price_proposal ON delivery_requests;

CREATE TRIGGER trigger_notify_passenger_on_price_proposal
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_passenger_on_price_proposal();

-- ============================================================================
-- 2. NOTIFY DELIVERY PERSON ON PRICE ACCEPTANCE
-- ============================================================================
CREATE OR REPLACE FUNCTION notify_delivery_person_on_price_acceptance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_delivery_person_user_id bigint;
BEGIN
  -- Only proceed if status changed from 'price_negotiation' to 'accepted'
  IF OLD.status = 'price_negotiation' AND NEW.status = 'accepted' THEN
    
    -- Get delivery person's user_id
    SELECT user_id INTO v_delivery_person_user_id
    FROM delivery_persons
    WHERE id = NEW.delivery_person_id;
    
    -- Insert notification for the delivery person
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_delivery_person_user_id,
      '✅ Price Accepted!',
      'The passenger accepted your proposed price of $' || NEW.price,
      jsonb_build_object(
        'type', 'price_accepted',
        'delivery_request_id', NEW.id,
        'final_price', NEW.price
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_delivery_person_on_price_acceptance ON delivery_requests;

CREATE TRIGGER trigger_notify_delivery_person_on_price_acceptance
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_delivery_person_on_price_acceptance();

-- ============================================================================
-- 3. NOTIFY DELIVERY PERSON ON PRICE REJECTION
-- ============================================================================
CREATE OR REPLACE FUNCTION notify_delivery_person_on_price_rejection()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_delivery_person_user_id bigint;
  v_rejected_price decimal;
BEGIN
  -- Only proceed if status changed from 'price_negotiation' to 'pending'
  IF OLD.status = 'price_negotiation' AND NEW.status = 'pending' THEN
    
    -- Get delivery person's user_id (from OLD since it's cleared in NEW)
    SELECT user_id INTO v_delivery_person_user_id
    FROM delivery_persons
    WHERE id = OLD.delivery_person_id;
    
    v_rejected_price := OLD.proposed_price;
    
    -- Insert notification for the delivery person
    INSERT INTO notifications (user_id, title, body, data, is_read, created_at)
    VALUES (
      v_delivery_person_user_id,
      '❌ Price Rejected',
      'The passenger declined your proposed price of $' || v_rejected_price,
      jsonb_build_object(
        'type', 'price_rejected',
        'delivery_request_id', NEW.id,
        'rejected_price', v_rejected_price
      ),
      false,
      NOW()
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_delivery_person_on_price_rejection ON delivery_requests;

CREATE TRIGGER trigger_notify_delivery_person_on_price_rejection
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_delivery_person_on_price_rejection();
