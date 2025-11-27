-- Referral rewards table to track earnings from referrals
CREATE TABLE referral_rewards (
    id SERIAL PRIMARY KEY,
    referral_id INTEGER NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Reward details
    reward_type VARCHAR(20) NOT NULL DEFAULT 'points',
    -- Type: 'points', 'cash', 'bonus'
    amount DECIMAL(10, 2) NOT NULL,
    points INTEGER DEFAULT 0,
    
    -- Status and tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- Status: 'pending', 'approved', 'paid', 'cancelled'
    milestone VARCHAR(50),
    -- Milestone: 'signup', 'first_ride', '5_rides', '10_rides', '20_rides'
    
    -- Payment tracking
    wallet_transaction_id INTEGER REFERENCES wallets(id) ON DELETE SET NULL,
    paid_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    description TEXT,
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_reward_type CHECK (reward_type IN ('points', 'cash', 'bonus')),
    CONSTRAINT valid_reward_status CHECK (status IN ('pending', 'approved', 'paid', 'cancelled')),
    CONSTRAINT positive_amount CHECK (amount >= 0),
    CONSTRAINT positive_points CHECK (points >= 0)
);

-- Indexes for performance
CREATE INDEX idx_referral_rewards_referral_id ON referral_rewards(referral_id);
CREATE INDEX idx_referral_rewards_user_id ON referral_rewards(user_id);
CREATE INDEX idx_referral_rewards_status ON referral_rewards(status);
CREATE INDEX idx_referral_rewards_milestone ON referral_rewards(milestone);

-- RLS Policies
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;

-- Users can view their own rewards
CREATE POLICY "Users can view their own rewards"
    ON referral_rewards FOR SELECT
    USING (
        user_id = (SELECT id FROM users WHERE auth.uid() = users.user_id)
    );

-- System can insert rewards
CREATE POLICY "System can insert rewards"
    ON referral_rewards FOR INSERT
    WITH CHECK (true);

-- System can update rewards
CREATE POLICY "System can update rewards"
    ON referral_rewards FOR UPDATE
    USING (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_referral_rewards_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER set_referral_rewards_updated_at
    BEFORE UPDATE ON referral_rewards
    FOR EACH ROW
    EXECUTE FUNCTION update_referral_rewards_updated_at();
