-- Drop existing table if exists (clean slate)
DROP TABLE IF EXISTS course_reviews CASCADE;

-- Create simplified course_reviews table
CREATE TABLE course_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, user_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_course_reviews_course_id ON course_reviews(course_id);
CREATE INDEX IF NOT EXISTS idx_course_reviews_user_id ON course_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_course_reviews_rating ON course_reviews(rating);

-- Enable RLS
ALTER TABLE course_reviews ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view course reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can insert their own reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can update their own reviews" ON course_reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews" ON course_reviews;

-- Policy: Users can view all reviews
CREATE POLICY "Anyone can view course reviews"
  ON course_reviews
  FOR SELECT
  USING (true);

-- Policy: Authenticated users can insert their own reviews
CREATE POLICY "Users can insert their own reviews"
  ON course_reviews
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reviews
CREATE POLICY "Users can update their own reviews"
  ON course_reviews
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reviews
CREATE POLICY "Users can delete their own reviews"
  ON course_reviews
  FOR DELETE
  USING (auth.uid() = user_id);

-- Drop old triggers and functions
DROP TRIGGER IF EXISTS trigger_update_course_rating ON course_reviews;
DROP TRIGGER IF EXISTS trigger_update_instructor_rating ON course_reviews;
DROP FUNCTION IF EXISTS update_course_rating();
DROP FUNCTION IF EXISTS update_instructor_rating();

-- Function to update course average rating (with SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE courses
  SET 
    rating = (
      SELECT COALESCE(AVG(rating), 0)
      FROM course_reviews
      WHERE course_id = COALESCE(NEW.course_id, OLD.course_id)
    ),
    rating_count = (
      SELECT COUNT(*)
      FROM course_reviews
      WHERE course_id = COALESCE(NEW.course_id, OLD.course_id)
    ),
    updated_at = NOW()
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update course rating on insert/update/delete
CREATE TRIGGER trigger_update_course_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_course_rating();

-- Function to update instructor average rating (with SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION update_instructor_rating()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_instructor_id UUID;
  v_avg_rating DECIMAL(3,2);
  v_total_reviews INTEGER;
BEGIN
  SELECT instructor_id INTO v_instructor_id
  FROM courses
  WHERE id = COALESCE(NEW.course_id, OLD.course_id);
  
  SELECT 
    COALESCE(AVG(cr.rating), 0)::DECIMAL(3,2),
    COUNT(cr.id)
  INTO v_avg_rating, v_total_reviews
  FROM course_reviews cr
  INNER JOIN courses c ON c.id = cr.course_id
  WHERE c.instructor_id = v_instructor_id;
  
  UPDATE instructor_profiles
  SET 
    average_rating = v_avg_rating,
    total_reviews = v_total_reviews,
    updated_at = NOW()
  WHERE instructor_id = v_instructor_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to update instructor rating on insert/update/delete
CREATE TRIGGER trigger_update_instructor_rating
  AFTER INSERT OR UPDATE OR DELETE ON course_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_instructor_rating();

-- Add comment
COMMENT ON TABLE course_reviews IS 'Stores user ratings and reviews for courses';
