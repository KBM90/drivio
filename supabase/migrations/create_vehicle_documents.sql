-- Create document_images table
CREATE TABLE public.document_images (
    id BIGSERIAL PRIMARY KEY,
    image_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create vehicle_documents table
CREATE TABLE public.vehicle_documents (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    document_name TEXT NOT NULL,
    expiring_date DATE NOT NULL,
    image_id BIGINT NOT NULL REFERENCES public.document_images(id) ON DELETE CASCADE,
    is_expired BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create function to check expiration
CREATE OR REPLACE FUNCTION check_document_expiration()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_expired := NEW.expiring_date < CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update is_expired on insert or update
CREATE TRIGGER set_document_expiration
BEFORE INSERT OR UPDATE ON public.vehicle_documents
FOR EACH ROW
EXECUTE FUNCTION check_document_expiration();
