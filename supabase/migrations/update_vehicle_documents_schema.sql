-- Add document_type and metadata columns to vehicle_documents table
ALTER TABLE public.vehicle_documents
ADD COLUMN document_type TEXT,
ADD COLUMN metadata JSONB;

-- Update existing rows to have a default document_type
UPDATE public.vehicle_documents
SET document_type = 'other'
WHERE document_type IS NULL;

-- Make document_type NOT NULL after setting defaults
ALTER TABLE public.vehicle_documents
ALTER COLUMN document_type SET NOT NULL;
