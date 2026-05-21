-- Add badge column to courses table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'badge') THEN
        ALTER TABLE public.courses ADD COLUMN badge text;
    END IF;
END $$;

-- Reload schema cache to ensure the new column is visible to PostgREST
NOTIFY pgrst, 'reload schema';
