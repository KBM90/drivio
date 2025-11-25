
BEGIN
  IF NEW.status = 'accepted' AND OLD.status != 'accepted' AND NEW.accepted_at IS NULL THEN
    NEW.accepted_at = CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
