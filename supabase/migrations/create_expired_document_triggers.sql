-- Triggers to check for expired documents and create notifications
-- These triggers fire when expiring_date is updated or a new document is inserted

-- Function to check and notify about expired vehicle documents
CREATE OR REPLACE FUNCTION check_expired_vehicle_documents()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id BIGINT;
  v_driver_id BIGINT;
BEGIN
  -- Check if document is expired (expiring_date is in the past)
  IF NEW.expiring_date < CURRENT_DATE THEN
    -- Only send notification if this is a new expiration (not already notified)
    IF (TG_OP = 'INSERT') OR (OLD.expiring_date IS NULL OR OLD.expiring_date >= CURRENT_DATE) THEN
      -- Get driver_id and user_id through vehicle
      SELECT v.driver_id, d.user_id INTO v_driver_id, v_user_id
      FROM vehicles v
      JOIN drivers d ON d.id = v.driver_id
      WHERE v.id = NEW.vehicle_id;
      
      -- Create notification
      IF v_user_id IS NOT NULL THEN
        INSERT INTO notifications (
          user_id,
          title,
          body,
          type,
          created_at
        ) VALUES (
          v_user_id,
          'Document ' || NEW.document_type || ' is expired',
          'Your vehicle document "' || NEW.document_name || '" expired on ' || TO_CHAR(NEW.expiring_date, 'YYYY-MM-DD') || '. Please update it as soon as possible to continue using the platform. Go to Vehicle Information > Documents to upload a new one.',
          'document_expired',
          NOW()
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for vehicle documents
DROP TRIGGER IF EXISTS trigger_check_expired_vehicle_documents ON vehicle_documents;
CREATE TRIGGER trigger_check_expired_vehicle_documents
  AFTER INSERT OR UPDATE OF expiring_date
  ON vehicle_documents
  FOR EACH ROW
  EXECUTE FUNCTION check_expired_vehicle_documents();

-- Function to check and notify about expired driver documents
CREATE OR REPLACE FUNCTION check_expired_driver_documents()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id BIGINT;
BEGIN
  -- Check if document is expired (expiring_date is in the past)
  IF NEW.expiring_date < CURRENT_DATE THEN
    -- Only send notification if this is a new expiration (not already notified)
    IF (TG_OP = 'INSERT') OR (OLD.expiring_date IS NULL OR OLD.expiring_date >= CURRENT_DATE) THEN
      -- Get user_id through driver
      SELECT d.user_id INTO v_user_id
      FROM drivers d
      WHERE d.id = NEW.driver_id;
      
      -- Create notification
      IF v_user_id IS NOT NULL THEN
        INSERT INTO notifications (
          user_id,
          title,
          body,
          type,
          created_at
        ) VALUES (
          v_user_id,
          'Document ' || NEW.type || ' is expired',
          'Your ' || NEW.type || ' (Number: ' || NEW.number || ') expired on ' || TO_CHAR(NEW.expiring_date, 'YYYY-MM-DD') || '. Please update it immediately to continue driving. Go to Driver Information > Documents to upload a new one.',
          'document_expired',
          NOW()
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for driver documents
DROP TRIGGER IF EXISTS trigger_check_expired_driver_documents ON driver_documents;
CREATE TRIGGER trigger_check_expired_driver_documents
  AFTER INSERT OR UPDATE OF expiring_date
  ON driver_documents
  FOR EACH ROW
  EXECUTE FUNCTION check_expired_driver_documents();

-- Add comments
COMMENT ON FUNCTION check_expired_vehicle_documents() IS 'Checks if a vehicle document has expired (expiring_date < current_date) and creates a notification for the driver';
COMMENT ON FUNCTION check_expired_driver_documents() IS 'Checks if a driver document has expired (expiring_date < current_date) and creates a notification for the driver';
