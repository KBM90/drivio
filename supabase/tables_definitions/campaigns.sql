-- Campaigns table to store competitions and missions for drivers
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Campaign type and goals
    campaign_type VARCHAR(50) NOT NULL,
    -- Type: 'ride_count', 'earnings', 'rating', 'hours', 'combo'
    
    -- Goal criteria (JSONB for flexibility)
    goal_criteria JSONB NOT NULL,
    -- Example: {"rides": 50, "days": 7} or {"earnings": 500, "hours": 40}
    
    -- Reward details
    reward_type VARCHAR(20) NOT NULL DEFAULT 'cash',
    -- Type: 'cash', 'points', 'badge', 'combo'
    reward_amount DECIMAL(10, 2) DEFAULT 0,
    reward_points INTEGER DEFAULT 0,
    reward_badge VARCHAR(100),
    reward_description TEXT,
    
    -- Time constraints
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Participation limits
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    
    -- Location restrictions
    city_restriction VARCHAR(100),
    region_restriction VARCHAR(100),
    
    -- Competition settings
    is_competitive BOOLEAN DEFAULT FALSE,
    show_leaderboard BOOLEAN DEFAULT FALSE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'upcoming',
    -- Status: 'upcoming', 'active', 'ended', 'cancelled'
    
    -- Metadata
    image_url TEXT,
    terms_conditions TEXT,
    priority INTEGER DEFAULT 0, -- Higher priority shows first
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_campaign_type CHECK (campaign_type IN ('ride_count', 'earnings', 'rating', 'hours', 'combo')),
    CONSTRAINT valid_reward_type CHECK (reward_type IN ('cash', 'points', 'badge', 'combo')),
    CONSTRAINT valid_status CHECK (status IN ('upcoming', 'active', 'ended', 'cancelled')),
    CONSTRAINT valid_dates CHECK (end_date > start_date),
    CONSTRAINT positive_reward CHECK (reward_amount >= 0 AND reward_points >= 0)
);

-- Indexes for performance
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);
CREATE INDEX idx_campaigns_city ON campaigns(city_restriction);
CREATE INDEX idx_campaigns_type ON campaigns(campaign_type);
CREATE INDEX idx_campaigns_priority ON campaigns(priority DESC);

-- RLS Policies
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view active campaigns
CREATE POLICY "Users can view active campaigns"
    ON campaigns FOR SELECT
    TO authenticated
    USING (status IN ('upcoming', 'active'));

-- System can manage campaigns
CREATE POLICY "System can manage campaigns"
    ON campaigns FOR ALL
    USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_campaigns_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER set_campaigns_updated_at
    BEFORE UPDATE ON campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_campaigns_updated_at();

-- Function to automatically update campaign status based on dates
CREATE OR REPLACE FUNCTION update_campaign_status()
RETURNS void AS $$
BEGIN
    -- Set to active if start date has passed
    UPDATE campaigns
    SET status = 'active'
    WHERE status = 'upcoming'
      AND start_date <= NOW();
    
    -- Set to ended if end date has passed
    UPDATE campaigns
    SET status = 'ended'
    WHERE status = 'active'
      AND end_date <= NOW();
END;
$$ LANGUAGE plpgsql;
