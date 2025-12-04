-- Add is_verified field to vehicle_documents table

ALTER TABLE public.vehicle_documents
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Add comment to the new column
COMMENT ON COLUMN public.vehicle_documents.is_verified IS 'Indicates whether the document has been verified by admin';
