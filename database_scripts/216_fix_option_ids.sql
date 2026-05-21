-- ============================================================
-- Fix Missing Option IDs in Quiz Questions
-- Run this in Supabase SQL Editor
-- ============================================================

-- Update options that don't have IDs
UPDATE quiz_questions
SET options = (
  SELECT jsonb_agg(
    CASE 
      WHEN opt->>'id' IS NULL OR opt->>'id' = '' 
      THEN opt || jsonb_build_object('id', gen_random_uuid()::text)
      ELSE opt
    END
  )
  FROM jsonb_array_elements(options) AS opt
)
WHERE options IS NOT NULL 
  AND jsonb_array_length(options) > 0
  AND EXISTS (
    SELECT 1 FROM jsonb_array_elements(options) AS opt
    WHERE opt->>'id' IS NULL OR opt->>'id' = ''
  );

-- Verify the fix
SELECT id, question_ar, options 
FROM quiz_questions 
WHERE options IS NOT NULL 
LIMIT 5;
