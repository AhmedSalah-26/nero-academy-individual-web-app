-- =====================================================
-- Q&A Answer Upvotes
-- Apply this to existing Supabase projects that already
-- have qa_questions and qa_answers.
-- =====================================================

CREATE TABLE IF NOT EXISTS qa_answer_upvotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES qa_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(answer_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_answer_upvotes_answer
  ON qa_answer_upvotes(answer_id);

CREATE INDEX IF NOT EXISTS idx_answer_upvotes_user
  ON qa_answer_upvotes(user_id);

ALTER TABLE qa_answer_upvotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view answer upvotes" ON qa_answer_upvotes;
CREATE POLICY "Anyone can view answer upvotes"
  ON qa_answer_upvotes
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated can upvote answers" ON qa_answer_upvotes;
CREATE POLICY "Authenticated can upvote answers"
  ON qa_answer_upvotes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their answer upvotes" ON qa_answer_upvotes;
CREATE POLICY "Users can remove their answer upvotes"
  ON qa_answer_upvotes
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_qa_answer_upvotes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE qa_answers
    SET upvotes_count = upvotes_count + 1
    WHERE id = NEW.answer_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE qa_answers
    SET upvotes_count = GREATEST(0, upvotes_count - 1)
    WHERE id = OLD.answer_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_qa_answer_upvotes_count ON qa_answer_upvotes;
CREATE TRIGGER trigger_update_qa_answer_upvotes_count
  AFTER INSERT OR DELETE ON qa_answer_upvotes
  FOR EACH ROW
  EXECUTE FUNCTION update_qa_answer_upvotes_count();

UPDATE qa_answers a
SET upvotes_count = (
  SELECT COUNT(*)
  FROM qa_answer_upvotes u
  WHERE u.answer_id = a.id
);

GRANT SELECT, INSERT, DELETE ON qa_answer_upvotes TO authenticated;
