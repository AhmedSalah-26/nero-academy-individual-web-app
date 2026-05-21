-- Add image_url column to quiz_questions table
-- This allows questions to have text only, image only, or both

ALTER TABLE quiz_questions
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN quiz_questions.image_url IS 'Optional image URL for the question. Question can be text only, image only, or both.';
