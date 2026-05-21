-- Add file upload capabilities to lessons
ALTER TABLE public.lessons 
ADD COLUMN IF NOT EXISTS file_url TEXT,
ADD COLUMN IF NOT EXISTS file_name TEXT,
ADD COLUMN IF NOT EXISTS file_size INTEGER,
ADD COLUMN IF NOT EXISTS file_type TEXT;

-- Optionally, add 'document' to lesson types if not already there, 
-- but since CHECK constraints can't be easily altered in Postgres without dropping them,
-- we'll just use the existing 'resource' or 'article' types, 
-- or we can just drop and recreate the constraint if really needed.
-- But wait, checking the constraint first.
DO $$
BEGIN
    -- Drop the check constraint if it exists
    ALTER TABLE public.lessons DROP CONSTRAINT IF EXISTS lessons_type_check;
EXCEPTION
    WHEN undefined_object THEN
        null;
END $$;

ALTER TABLE public.lessons
ADD CONSTRAINT lessons_type_check CHECK (type IN ('video', 'article', 'quiz', 'assignment', 'resource', 'live', 'document', 'file'));
