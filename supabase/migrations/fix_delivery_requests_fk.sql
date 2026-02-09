-- Add foreign key constraint to link delivery_requests.passenger_id to users.id
-- This allows PostgREST to detect the relationship between the tables

DO $$
BEGIN
    -- Check if the constraint already exists to avoid errors
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_delivery_requests_passenger' 
        AND table_name = 'delivery_requests'
    ) THEN
        ALTER TABLE public.delivery_requests
        ADD CONSTRAINT fk_delivery_requests_passenger
        FOREIGN KEY (passenger_id)
        REFERENCES public.users (id);
    END IF;
END $$;
