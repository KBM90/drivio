-- Referrals table to track referral relationships
CREATE TABLE referrals (
    id SERIAL PRIMARY KEY,
    referrer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- Status: 'pending', 'active', 'completed', 'expired'
    
    -- Track progress
    rides_completed INTEGER DEFAULT 0,
    signup_completed BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    referred_email VARCHAR(255), -- Store email if user hasn't signed up yet
    referred_phone VARCHAR(20),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    signup_completed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'active', 'completed', 'expired'))
);

-- Indexes for performance
CREATE INDEX idx_referrals_referrer_id ON referrals(referrer_id);
CREATE INDEX idx_referrals_referred_user_id ON referrals(referred_user_id);
CREATE INDEX idx_referrals_code ON referrals(referral_code);
CREATE INDEX idx_referrals_status ON referrals(status);

-- RLS Policies
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Users can view their own referrals (as referrer)
CREATE POLICY "Users can view their own referrals"
    ON referrals FOR SELECT
    USING (
        referrer_id = (SELECT id FROM users WHERE auth.uid() = users.user_id)
    );

-- Users can view referrals where they are the referred user
CREATE POLICY "Users can view referrals where they are referred"
    ON referrals FOR SELECT
    USING (
        referred_user_id = (SELECT id FROM users WHERE auth.uid() = users.user_id)
    );

-- System can insert referrals (during signup)
CREATE POLICY "System can insert referrals"
    ON referrals FOR INSERT
    WITH CHECK (true);

-- System can update referrals
CREATE POLICY "System can update referrals"
    ON referrals FOR UPDATE
    USING (true);
