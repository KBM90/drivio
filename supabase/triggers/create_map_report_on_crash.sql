-- Function to create a map report when a crash report is created
CREATE OR REPLACE FUNCTION create_map_report_on_crash()
RETURNS TRIGGER AS $$
DECLARE
  internal_user_id BIGINT;
BEGIN
  -- Get the internal user_id from the users table using the auth user_id
  SELECT id INTO internal_user_id
  FROM users
  WHERE auth_user_id = NEW.user_id;

  -- Insert a new map report based on the crash report
  INSERT INTO map_reports (
    report_type,
    point_location,
    user_id,
    status,
    description,
    created_at,
    updated_at
  ) VALUES (
    'accident',  -- Map crash reports to 'accident' type
    ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326),  -- Create point geometry
    internal_user_id,  -- Use the internal user_id
    'Active',
    COALESCE(
      NEW.description || ' (Severity: ' || NEW.severity || ')',
      'Crash reported - Severity: ' || NEW.severity
    ),
    NEW.created_at,
    NEW.created_at
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to execute the function after a crash report is inserted
DROP TRIGGER IF EXISTS trigger_create_map_report_on_crash ON crash_reports;

CREATE TRIGGER trigger_create_map_report_on_crash
  AFTER INSERT ON crash_reports
  FOR EACH ROW
  EXECUTE FUNCTION create_map_report_on_crash();

-- Add comment for documentation
COMMENT ON FUNCTION create_map_report_on_crash() IS 
  'Automatically creates a map report of type "accident" when a crash report is inserted';
