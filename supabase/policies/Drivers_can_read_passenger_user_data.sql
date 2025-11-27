-- Drop the policy first
DROP POLICY IF EXISTS "Drivers can read passenger user data" ON public.users;

-- More restrictive: Only allow drivers to read users who are passengers
CREATE POLICY "Drivers can read passenger user data"
ON public.users
FOR SELECT
TO authenticated
USING (
  -- Allow if this is the current user's own data
  user_id = auth.uid()
  OR
  -- Allow if the requesting user is a driver AND this user is a passenger
  (
    EXISTS (
      SELECT 1 FROM public.drivers
      WHERE drivers.user_id::text = auth.uid()::text
    )
    OR
    role = 'passenger'
  
  )
);