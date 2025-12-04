-- Create driver_documents table for storing driver's personal documents
-- (Driving License, ID Card, Passport)

CREATE TABLE IF NOT EXISTS public.driver_documents (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('Driving License', 'ID Card', 'Passport')),
  number TEXT NOT NULL,
  expiring_date DATE NOT NULL,
  image_id BIGINT REFERENCES public.document_images(id) ON DELETE SET NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on driver_id for faster queries
CREATE INDEX IF NOT EXISTS idx_driver_documents_driver_id ON public.driver_documents(driver_id);

-- Create index on type for filtering
CREATE INDEX IF NOT EXISTS idx_driver_documents_type ON public.driver_documents(type);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.driver_documents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own driver documents
CREATE POLICY "Users can view their own driver documents"
  ON public.driver_documents
  FOR SELECT
  USING (
    driver_id IN (
      SELECT id FROM public.drivers WHERE user_id = (
        SELECT id FROM public.users WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Users can insert their own driver documents
CREATE POLICY "Users can insert their own driver documents"
  ON public.driver_documents
  FOR INSERT
  WITH CHECK (
    driver_id IN (
      SELECT id FROM public.drivers WHERE user_id = (
        SELECT id FROM public.users WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Users can update their own driver documents
CREATE POLICY "Users can update their own driver documents"
  ON public.driver_documents
  FOR UPDATE
  USING (
    driver_id IN (
      SELECT id FROM public.drivers WHERE user_id = (
        SELECT id FROM public.users WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Users can delete their own driver documents
CREATE POLICY "Users can delete their own driver documents"
  ON public.driver_documents
  FOR DELETE
  USING (
    driver_id IN (
      SELECT id FROM public.drivers WHERE user_id = (
        SELECT id FROM public.users WHERE user_id = auth.uid()
      )
    )
  );

-- Add comment to table
COMMENT ON TABLE public.driver_documents IS 'Stores driver personal documents like driving license, ID card, and passport';
