-- =====================================================
-- Q&A Answer Upvotes System
-- =====================================================
-- This script creates a table for tracking upvotes on
-- Q&A answers and triggers to update upvotes_count
-- =====================================================

-- Create qa_answer_upvotes table
CREATE TABLE IF NOT EXISTS qa_answer_upvotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES qa_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one upvote per user per answer
  UNIQUE(answer_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_answer_upvotes_answer ON qa_answer_upvotes(answer_id);
CREATE INDEX IF NOT EXISTS idx_answer_upvotes_user ON qa_answer_upvotes(user_id);

-- Enable RLS
ALTER TABLE qa_answer_upvotes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view upvotes" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can add upvotes to others answers only" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can add their own upvotes" ON qa_answer_upvotes;
DROP POLICY IF EXISTS "Users can remove their own upvotes" ON qa_answer_upvotes;

CREATE POLICY "Anyone can view upvotes" ON qa_answer_upvotes 
  FOR SELECT 
  USING (true);

CREATE POLICY "Users can add their own upvotes" ON qa_answer_upvotes 
  FOR INSERT 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove their own upvotes" ON qa_answer_upvotes 
  FOR DELETE 
  USING (user_id = auth.uid());

-- Function to update upvotes count
CREATE OR REPLACE FUNCTION update_qa_answer_upvotes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment upvotes count
    UPDATE qa_answers
    SET upvotes_count = upvotes_count + 1
    WHERE id = NEW.answer_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement upvotes count
    UPDATE qa_answers
    SET upvotes_count = GREATEST(0, upvotes_count - 1)
    WHERE id = OLD.answer_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_qa_answer_upvotes_count ON qa_answer_upvotes;

-- Create trigger
CREATE TRIGGER trigger_update_qa_answer_upvotes_count
AFTER INSERT OR DELETE ON qa_answer_upvotes
FOR EACH ROW
EXECUTE FUNCTION update_qa_answer_upvotes_count();

-- Recalculate existing counts (one-time fix)
UPDATE qa_answers a
SET upvotes_count = (
  SELECT COUNT(*)
  FROM qa_answer_upvotes u
  WHERE u.answer_id = a.id
);

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON qa_answer_upvotes TO authenticated;

-- Add to realtime publication (only if not already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'qa_answer_upvotes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE qa_answer_upvotes;
  END IF;
END $$;

COMMENT ON TABLE qa_answer_upvotes IS 'Tracks user upvotes on Q&A answers - users cannot upvote their own answers';
COMMENT ON FUNCTION update_qa_answer_upvotes_count() IS 'Automatically updates upvotes_count in qa_answers when upvotes are added or removed';
