-- Campaign participants table to track driver enrollment and progress
CREATE TABLE campaign_participants (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    driver_id INTEGER NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    
    -- Progress tracking (JSONB for flexibility)
    progress JSONB DEFAULT '{}',
    -- Example: {"rides_completed": 25, "earnings": 250.50, "hours_worked": 15}
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    -- Status: 'active', 'completed', 'failed', 'withdrawn'
    
    -- Completion tracking
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    completion_percentage DECIMAL(5, 2) DEFAULT 0,
    
    -- Reward tracking
    reward_earned BOOLEAN DEFAULT FALSE,
    reward_amount DECIMAL(10, 2) DEFAULT 0,
    reward_points INTEGER DEFAULT 0,
    reward_paid BOOLEAN DEFAULT FALSE,
    reward_paid_at TIMESTAMP WITH TIME ZONE,
    
    -- Leaderboard position (for competitive campaigns)
    leaderboard_rank INTEGER,
    leaderboard_score DECIMAL(10, 2),
    
    -- Timestamps
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint: one driver per campaign
    CONSTRAINT unique_driver_campaign UNIQUE (campaign_id, driver_id),
    CONSTRAINT valid_status CHECK (status IN ('active', 'completed', 'failed', 'withdrawn')),
    CONSTRAINT valid_percentage CHECK (completion_percentage >= 0 AND completion_percentage <= 100)
);

-- Indexes for performance
CREATE INDEX idx_campaign_participants_campaign ON campaign_participants(campaign_id);
CREATE INDEX idx_campaign_participants_driver ON campaign_participants(driver_id);
CREATE INDEX idx_campaign_participants_status ON campaign_participants(status);
CREATE INDEX idx_campaign_participants_completed ON campaign_participants(is_completed);
CREATE INDEX idx_campaign_participants_leaderboard ON campaign_participants(campaign_id, leaderboard_rank);

-- RLS Policies
ALTER TABLE campaign_participants ENABLE ROW LEVEL SECURITY;

-- Drivers can view their own participation
CREATE POLICY "Drivers can view their own participation"
    ON campaign_participants FOR SELECT
    USING (
        driver_id = (
            SELECT id FROM drivers 
            WHERE user_id = (SELECT id FROM users WHERE auth.uid() = users.user_id)
        )
    );

-- Drivers can view leaderboard for competitive campaigns
CREATE POLICY "Users can view leaderboard"
    ON campaign_participants FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM campaigns 
            WHERE campaigns.id = campaign_participants.campaign_id 
            AND campaigns.show_leaderboard = true
        )
    );

-- System can manage participation
CREATE POLICY "System can manage participation"
    ON campaign_participants FOR ALL
    USING (true);

-- Function to update last_updated timestamp
CREATE OR REPLACE FUNCTION update_campaign_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update last_updated
CREATE TRIGGER set_campaign_participants_updated_at
    BEFORE UPDATE ON campaign_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_campaign_participants_updated_at();

-- Function to update participant count in campaigns
CREATE OR REPLACE FUNCTION update_campaign_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE campaigns
        SET current_participants = current_participants + 1
        WHERE id = NEW.campaign_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE campaigns
        SET current_participants = current_participants - 1
        WHERE id = OLD.campaign_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to maintain participant count
CREATE TRIGGER maintain_campaign_participant_count
    AFTER INSERT OR DELETE ON campaign_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_campaign_participant_count();
