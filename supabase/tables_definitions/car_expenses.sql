-- Car Expenses Table
-- Stores all vehicle-related expenses for drivers to track operating costs

CREATE TABLE IF NOT EXISTS car_expenses (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  expense_type VARCHAR(50) NOT NULL CHECK (expense_type IN ('fuel', 'maintenance', 'insurance', 'registration', 'depreciation', 'other')),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
  description TEXT,
  expense_date DATE NOT NULL,
  odometer_reading INTEGER CHECK (odometer_reading >= 0),
  fuel_liters DECIMAL(10, 2) CHECK (fuel_liters >= 0),
  distance_km DECIMAL(10, 2) CHECK (distance_km >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_car_expenses_driver ON car_expenses(driver_id);
CREATE INDEX IF NOT EXISTS idx_car_expenses_date ON car_expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_car_expenses_type ON car_expenses(expense_type);
CREATE INDEX IF NOT EXISTS idx_car_expenses_driver_date ON car_expenses(driver_id, expense_date DESC);

-- Enable Row Level Security
ALTER TABLE car_expenses ENABLE ROW LEVEL SECURITY;

-- Policy: Drivers can only view their own expenses
CREATE POLICY car_expenses_select_policy ON car_expenses
  FOR SELECT
  USING (
    driver_id IN (
      SELECT d.id 
      FROM drivers d
      JOIN users u ON d.user_id = u.id
      WHERE u.user_id = auth.uid()
    )
  );

-- Policy: Drivers can only insert their own expenses
CREATE POLICY car_expenses_insert_policy ON car_expenses
  FOR INSERT
  WITH CHECK (
    driver_id IN (
      SELECT d.id 
      FROM drivers d
      JOIN users u ON d.user_id = u.id
      WHERE u.user_id = auth.uid()
    )
  );

-- Policy: Drivers can only update their own expenses
CREATE POLICY car_expenses_update_policy ON car_expenses
  FOR UPDATE
  USING (
    driver_id IN (
      SELECT d.id 
      FROM drivers d
      JOIN users u ON d.user_id = u.id
      WHERE u.user_id = auth.uid()
    )
  );

-- Policy: Drivers can only delete their own expenses
CREATE POLICY car_expenses_delete_policy ON car_expenses
  FOR DELETE
  USING (
    driver_id IN (
      SELECT d.id 
      FROM drivers d
      JOIN users u ON d.user_id = u.id
      WHERE u.user_id = auth.uid()
    )
  );

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_car_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER car_expenses_updated_at_trigger
  BEFORE UPDATE ON car_expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_car_expenses_updated_at();

-- Comment on table
COMMENT ON TABLE car_expenses IS 'Stores vehicle operating expenses for drivers to track costs and calculate profitability';
