-- Events table to store local events that may increase ride demand
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL,
    -- Type: 'sporting', 'concert', 'conference', 'festival', 'other'
    
    -- Location details
    city VARCHAR(100) NOT NULL,
    venue VARCHAR(255),
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Time details
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    expected_attendance INTEGER,
    surge_multiplier DECIMAL(3, 2) DEFAULT 1.0,
    image_url TEXT,
    external_link TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'upcoming',
    -- Status: 'upcoming', 'ongoing', 'completed', 'cancelled'
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_event_type CHECK (event_type IN ('sporting', 'concert', 'conference', 'festival', 'other')),
    CONSTRAINT valid_status CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
    CONSTRAINT valid_surge CHECK (surge_multiplier >= 1.0 AND surge_multiplier <= 5.0)
);

-- Indexes for performance
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_location ON events(latitude, longitude);

-- RLS Policies
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view events
CREATE POLICY "Authenticated users can view events"
    ON events FOR SELECT
    TO authenticated
    USING (true);

-- Only admins can insert/update/delete events (handled by backend)
CREATE POLICY "System can manage events"
    ON events FOR ALL
    USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER set_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_events_updated_at();
