-- Create crash_reports table
CREATE TABLE IF NOT EXISTS crash_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ride_id BIGINT REFERENCES ride_requests(id) ON DELETE SET NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('minor', 'moderate', 'severe')),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  description TEXT,
  injuries_reported BOOLEAN DEFAULT FALSE,
  vehicles_involved INTEGER DEFAULT 1,
  police_notified BOOLEAN DEFAULT FALSE,
  photos JSONB DEFAULT '[]'::jsonb,
  emergency_contacted JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_crash_reports_user_id ON crash_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_crash_reports_ride_id ON crash_reports(ride_id);
CREATE INDEX IF NOT EXISTS idx_crash_reports_created_at ON crash_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crash_reports_severity ON crash_reports(severity);

-- Enable Row Level Security
ALTER TABLE crash_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own crash reports
CREATE POLICY "Users can view their own crash reports"
  ON crash_reports
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own crash reports
CREATE POLICY "Users can insert their own crash reports"
  ON crash_reports
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own crash reports
CREATE POLICY "Users can update their own crash reports"
  ON crash_reports
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own crash reports
CREATE POLICY "Users can delete their own crash reports"
  ON crash_reports
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_crash_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_crash_reports_updated_at_trigger
  BEFORE UPDATE ON crash_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_crash_reports_updated_at();

-- Create Supabase Storage bucket for crash photos
-- Run this in Supabase Dashboard > Storage
-- INSERT INTO storage.buckets (id, name, public) VALUES ('crash-photos', 'crash-photos', true);
