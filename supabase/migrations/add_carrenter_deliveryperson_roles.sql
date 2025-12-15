-- ============================================
-- Migration: Add 'carrenter' and 'deliveryperson' roles to users table
-- ============================================
-- This migration updates the users_role_check constraint to include
-- the new roles: 'carrenter' and 'deliveryperson'

-- Drop the existing constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;

-- Add the updated constraint with new roles
ALTER TABLE public.users ADD CONSTRAINT users_role_check CHECK (
  role = ANY (
    ARRAY[
      'passenger'::text,
      'driver'::text,
      'courtier'::text,
      'provider'::text,
      'admin'::text,
      'carrenter'::text,
      'deliveryperson'::text
    ]
  )
);

-- Verify the constraint was added successfully
SELECT 
  conname AS constraint_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conname = 'users_role_check';
