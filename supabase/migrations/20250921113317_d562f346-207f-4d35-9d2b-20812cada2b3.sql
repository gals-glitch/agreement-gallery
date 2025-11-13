-- Create storage bucket for Excel files
INSERT INTO storage.buckets (id, name, public)
VALUES ('excel-files', 'excel-files', false);

-- Create policies for Excel file uploads
CREATE POLICY "Users can upload Excel files" 
ON storage.objects 
FOR INSERT 
WITH CHECK (
  bucket_id = 'excel-files' 
  AND auth.uid() IS NOT NULL
  AND (storage.extension(name) = 'xlsx' OR storage.extension(name) = 'xls' OR storage.extension(name) = 'csv')
);

CREATE POLICY "Users can view their own Excel files" 
ON storage.objects 
FOR SELECT 
USING (
  bucket_id = 'excel-files' 
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Users can delete their own Excel files" 
ON storage.objects 
FOR DELETE 
USING (
  bucket_id = 'excel-files' 
  AND auth.uid() IS NOT NULL
);

-- Create table for tracking Excel import jobs
CREATE TABLE public.excel_import_jobs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_rows INTEGER,
  processed_rows INTEGER DEFAULT 0,
  success_count INTEGER DEFAULT 0,
  error_count INTEGER DEFAULT 0,
  validation_errors JSONB DEFAULT '[]'::jsonb,
  column_mapping JSONB,
  progress_percentage INTEGER DEFAULT 0,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on import jobs
ALTER TABLE public.excel_import_jobs ENABLE ROW LEVEL SECURITY;

-- Create policies for import jobs
CREATE POLICY "Users can view their own import jobs" 
ON public.excel_import_jobs 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own import jobs" 
ON public.excel_import_jobs 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own import jobs" 
ON public.excel_import_jobs 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Add trigger for updating timestamps
CREATE TRIGGER update_excel_import_jobs_updated_at
  BEFORE UPDATE ON public.excel_import_jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Add calculation_run_id to investor_distributions if not exists (for linking imported data)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'investor_distributions' 
        AND column_name = 'import_job_id'
    ) THEN
        ALTER TABLE public.investor_distributions 
        ADD COLUMN import_job_id UUID REFERENCES public.excel_import_jobs(id) ON DELETE SET NULL;
    END IF;
END $$;