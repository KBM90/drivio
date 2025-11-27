-- Function to increment ride count for referrals
-- This should be called whenever a referred user completes a ride
CREATE OR REPLACE FUNCTION increment_referral_rides(p_user_id INTEGER)
RETURNS void AS $$
BEGIN
    -- Update all active referrals where this user is the referred user
    UPDATE referrals
    SET rides_completed = rides_completed + 1
    WHERE referred_user_id = p_user_id
      AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION increment_referral_rides(INTEGER) TO authenticated;
