-- Check for duplicate passenger records with the same user_id
-- This query will help identify if there are multiple passenger records for the same user

-- Step 1: Find duplicate user_ids in passengers table
SELECT 
  user_id,
  COUNT(*) as duplicate_count,
  ARRAY_AGG(id) as passenger_ids
FROM passengers
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Check if user_id = 1 has a passenger record
SELECT 
  p.*,
  u.name as user_name,
  u.email as user_email
FROM passengers p
LEFT JOIN users u ON p.user_id = u.id
WHERE p.user_id = 1;

-- Step 3: Check if user with id = 1 exists
SELECT id, name, email, role 
FROM users 
WHERE id = 1;

-- ============================================
-- SOLUTION 1: If duplicates exist, keep only the first one
-- ============================================

-- WARNING: This will delete duplicate passenger records!
-- Uncomment and run only after reviewing the duplicates above

/*
DELETE FROM passengers
WHERE id NOT IN (
  SELECT MIN(id)
  FROM passengers
  GROUP BY user_id
);
*/

-- ============================================
-- SOLUTION 2: Add unique constraint to prevent future duplicates
-- ============================================

-- Add unique constraint on user_id to prevent duplicate passengers
-- This ensures each user can only have ONE passenger record

ALTER TABLE passengers 
ADD CONSTRAINT passengers_user_id_unique UNIQUE (user_id);

-- ============================================
-- SOLUTION 3: Check if user_id = 1 is a passenger or driver
-- ============================================

-- Check user role
SELECT 
  u.id,
  u.name,
  u.email,
  u.role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM passengers WHERE user_id = u.id) THEN 'Has Passenger Record'
    ELSE 'No Passenger Record'
  END as passenger_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM drivers WHERE user_id = u.id) THEN 'Has Driver Record'
    ELSE 'No Driver Record'
  END as driver_status
FROM users u
WHERE u.id = 1;

-- ============================================
-- SOLUTION 4: Create missing passenger record if needed
-- ============================================

-- If user_id = 1 exists but has no passenger record, create one
-- Uncomment and run if needed:

/*
INSERT INTO passengers (user_id, created_at, updated_at)
SELECT 1, NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM passengers WHERE user_id = 1
);
*/

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify the fix
SELECT 
  'Total Passengers' as metric,
  COUNT(*)::text as value
FROM passengers
UNION ALL
SELECT 
  'Unique Users',
  COUNT(DISTINCT user_id)::text
FROM passengers
UNION ALL
SELECT 
  'Duplicate Records',
  (COUNT(*) - COUNT(DISTINCT user_id))::text
FROM passengers;
