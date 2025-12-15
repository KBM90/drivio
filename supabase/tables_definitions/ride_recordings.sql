-- Create ride_recordings table
CREATE TABLE IF NOT EXISTS ride_recordings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id BIGINT REFERENCES ride_requests(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  duration INTEGER, -- in seconds
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  is_uploaded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_ride_recordings_user_id ON ride_recordings(user_id);
CREATE INDEX IF NOT EXISTS idx_ride_recordings_ride_id ON ride_recordings(ride_id);
CREATE INDEX IF NOT EXISTS idx_ride_recordings_created_at ON ride_recordings(created_at DESC);

-- Enable Row Level Security
ALTER TABLE ride_recordings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own recordings
CREATE POLICY "Users can view their own recordings"
  ON ride_recordings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own recordings
CREATE POLICY "Users can insert their own recordings"
  ON ride_recordings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own recordings
CREATE POLICY "Users can update their own recordings"
  ON ride_recordings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own recordings
CREATE POLICY "Users can delete their own recordings"
  ON ride_recordings
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ride_recordings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ride_recordings_updated_at_trigger
  BEFORE UPDATE ON ride_recordings
  FOR EACH ROW
  EXECUTE FUNCTION update_ride_recordings_updated_at();
