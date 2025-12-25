-- ============================================
-- Trigger: Auto-update total_cars count
-- ============================================
-- This trigger automatically updates the total_cars count in car_renters
-- whenever a car is added, updated, or deleted from provided_car_rentals

-- Function to update total_cars count
CREATE OR REPLACE FUNCTION update_car_renter_total_cars()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT and UPDATE operations
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    UPDATE public.car_renters
    SET total_cars = (
      SELECT COUNT(*)
      FROM public.provided_car_rentals
      WHERE car_renter_id = NEW.car_renter_id
    )
    WHERE id = NEW.car_renter_id;
    RETURN NEW;
  
  -- For DELETE operations
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.car_renters
    SET total_cars = (
      SELECT COUNT(*)
      FROM public.provided_car_rentals
      WHERE car_renter_id = OLD.car_renter_id
    )
    WHERE id = OLD.car_renter_id;
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on provided_car_rentals table
DROP TRIGGER IF EXISTS trigger_update_total_cars ON public.provided_car_rentals;

CREATE TRIGGER trigger_update_total_cars
  AFTER INSERT OR UPDATE OR DELETE ON public.provided_car_rentals
  FOR EACH ROW
  EXECUTE FUNCTION update_car_renter_total_cars();

-- Update existing car_renters to have correct total_cars count
UPDATE public.car_renters cr
SET total_cars = (
  SELECT COUNT(*)
  FROM public.provided_car_rentals pcr
  WHERE pcr.car_renter_id = cr.id
);
